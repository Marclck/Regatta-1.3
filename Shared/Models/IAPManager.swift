//
//  IAPManager.swift
//  Regatta
//
//  Created by Chikai Lai on 22/12/2024.
//

import Foundation
import StoreKit
import UserNotifications

enum SubscriptionTier {
    case none
    case pro
    case ultra
}

enum IAPError: Error, LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case unknown
    case failedVerification
    case noRestoredPurchases
    case trialNotAvailable
    case trialAlreadyUsed
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in App Store."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .failedVerification:
            return "Purchase verification failed."
        case .unknown:
            return "An unknown error occurred."
        case .noRestoredPurchases:
            return "No previous purchases found to restore."
        case .trialNotAvailable:
            return "Ultra trial is only available for Pro subscribers."
        case .trialAlreadyUsed:
            return "You've already used your Ultra trial period."
        }
    }
}

class IAPManager: ObservableObject {
    static let shared = IAPManager()
    private let proFeatureID = "Astrolabe_pro_access_annual_599"
    private let ultraFeatureID = "Astrolabe_ultra_access_annual_1499"
    private let ultraOneTimeID = "Astrolabe_ultra_access_onetime_1999"

    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds
    private let proUltraTrialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // Keychain keys
    private let trialStartDateKey = "trialStartDate"
    private let proUltraTrialStartDateKey = "proUltraTrialStartDate"
    private let hasUsedProUltraTrialKey = "hasUsedProUltraTrial"
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var currentTier: SubscriptionTier = .none
    @Published var isInTrialPeriod = false
    @Published var isInProUltraTrial = false
    @Published var trialTimeRemaining: TimeInterval = 0
    @Published var proUltraTrialTimeRemaining: TimeInterval = 0
    @Published private(set) var isProUltraTrialAvailable: Bool = false
    @Published private(set) var hasUltraOneTimePurchase = false

    var proPrice: String {
        subscriptions.first { $0.id == proFeatureID }?.displayPrice ?? "$6.99"
    }
    
    var ultraPrice: String {
        subscriptions.first { $0.id == ultraFeatureID }?.displayPrice ?? "$14.99"
    }
    
    var ultraOneTimePrice: String {
        subscriptions.first { $0.id == ultraOneTimeID }?.displayPrice ?? "$19.99"
    }
    
    private var trialTimer: Timer?
    private var proUltraTrialTimer: Timer?
    private var updateListenerTask: Task<Void, Error>? = nil
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await checkPurchaseStatus()
            await MainActor.run {
                checkTrialStatus()
                checkProUltraTrialStatus()
            }
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        trialTimer?.invalidate()
        proUltraTrialTimer?.invalidate()
    }
    
    // MARK: - Trial Date Management
    
    private func saveTrialStartDate(_ date: Date, forKey key: String) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: date, requiringSecureCoding: true)
            try KeychainHelper.shared.save(data, key: key)
        } catch {
            print("Failed to save trial start date: \(error)")
        }
    }
    
    private func getTrialStartDate(forKey key: String) -> Date? {
        do {
            let data = try KeychainHelper.shared.read(key: key)
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDate.self, from: data) as Date?
        } catch {
            return nil
        }
    }
    
    private func removeTrialStartDate(forKey key: String) {
        try? KeychainHelper.shared.delete(key: key)
    }
    
    // MARK: - Pro Ultra Trial Management
    
    private func checkProUltraTrialStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let startDate = self.getTrialStartDate(forKey: self.proUltraTrialStartDateKey) {
                let timeElapsed = Date().timeIntervalSince(startDate)
                if timeElapsed < self.proUltraTrialDuration {
                    self.isInProUltraTrial = true
                    self.proUltraTrialTimeRemaining = self.proUltraTrialDuration - timeElapsed
                    self.startProUltraTrialTimer()
                } else {
                    self.isInProUltraTrial = false
                    self.proUltraTrialTimeRemaining = 0
                    self.removeTrialStartDate(forKey: self.proUltraTrialStartDateKey)
                }
            }
        }
    }
    
    private func startProUltraTrial() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let startDate = Date()
            self.saveTrialStartDate(startDate, forKey: self.proUltraTrialStartDateKey)
            self.isInProUltraTrial = true
            self.proUltraTrialTimeRemaining = self.proUltraTrialDuration
            self.startProUltraTrialTimer()
            self.scheduleProUltraTrialEndNotification(startDate: startDate)
        }
    }
    
    private func startProUltraTrialTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.proUltraTrialTimer?.invalidate()
            self?.proUltraTrialTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.proUltraTrialTimeRemaining > 0 {
                    self.proUltraTrialTimeRemaining -= 1
                } else {
                    self.isInProUltraTrial = false
                    self.proUltraTrialTimer?.invalidate()
                    self.removeTrialStartDate(forKey: self.proUltraTrialStartDateKey)
                }
            }
        }
    }
    
    private func scheduleProUltraTrialEndNotification(startDate: Date) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Ultra Trial Access Ending"
            content.body = "Your 7-day Ultra trial access is ending soon. Upgrade to keep premium features!"
            content.sound = .default
            
            let triggerDate = startDate.addingTimeInterval(self.proUltraTrialDuration - 24 * 60 * 60) // 1 day before expiration
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "pro-ultra-trial-end",
                content: content,
                trigger: trigger
            )
            
            center.add(request)
        }
    }
    
    // MARK: - Regular Trial Management
    
    private func checkTrialStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let startDate = self.getTrialStartDate(forKey: self.trialStartDateKey) {
                let timeElapsed = Date().timeIntervalSince(startDate)
                if timeElapsed < self.trialDuration {
                    self.isInTrialPeriod = true
                    self.trialTimeRemaining = self.trialDuration - timeElapsed
                    self.startTrialTimer()
                    self.scheduleTrialReminders(startDate: startDate)
                } else {
                    self.isInTrialPeriod = false
                    self.trialTimeRemaining = 0
                    self.showTrialEndNotification()
                }
            } else {
                self.startTrial()
            }
        }
    }
    
    private func startTrial() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let startDate = Date()
            self.saveTrialStartDate(startDate, forKey: self.trialStartDateKey)
            self.isInTrialPeriod = true
            self.trialTimeRemaining = self.trialDuration
            self.startTrialTimer()
            self.scheduleTrialReminders(startDate: startDate)
        }
    }
    
    private func startTrialTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.trialTimer?.invalidate()
            self?.trialTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.trialTimeRemaining > 0 {
                    self.trialTimeRemaining -= 1
                } else {
                    self.isInTrialPeriod = false
                    self.trialTimer?.invalidate()
                }
            }
        }
    }
    
    private func scheduleTrialReminders(startDate: Date) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else { return }
            
            center.removeAllPendingNotificationRequests()
            
            let reminders = [
                (days: 5, message: "5 days left in your Astrolabe trial! Upgrade to Pro or Ultra to keep access."),
                (days: 3, message: "Only 3 days remaining in your trial - Subscribe now to unlock all features"),
                (days: 1, message: "Last day of your trial - Your settings will be reset to default")
            ]
            
            for reminder in reminders {
                let content = UNMutableNotificationContent()
                content.title = "Trial Ending Soon"
                content.body = reminder.message
                content.sound = .default
                
                let triggerDate = startDate.addingTimeInterval(
                    (7 - Double(reminder.days)) * 24 * 60 * 60
                )
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: "trial-reminder-\(reminder.days)",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request)
            }
        }
    }
    
    // MARK: - Trial Availability Check
    
    private func checkProUltraTrialAvailability() {
        let hasUsedTrial = KeychainHelper.shared.hasUsedUltraTrial()
        isProUltraTrialAvailable = currentTier == .pro && !hasUsedTrial && !isInProUltraTrial
    }
    
    @MainActor
    func startProUltraTrialFromPrompt() async throws {
        await checkPurchaseStatus()
        
        guard currentTier == .pro else {
            throw IAPError.trialNotAvailable
        }
        
        if KeychainHelper.shared.hasUsedUltraTrial() {
            throw IAPError.trialAlreadyUsed
        }
        
        if isInProUltraTrial {
            return
        }
        
        startProUltraTrial()
        KeychainHelper.shared.setHasUsedUltraTrial(true)
        checkProUltraTrialAvailability()
        
        // Schedule confirmation notification
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Ultra Features Unlocked!"
        content.body = "Enjoy 7 days of Ultra features. Explore all the premium capabilities now available to you."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "ultra-trial-started",
            content: content,
            trigger: nil // Show immediately
        )
        
        try? await center.add(request)
    }
    
    // MARK: - Feature Access
    
    // Update canAccessFeatures to include one-time purchase
    func canAccessFeatures(minimumTier: SubscriptionTier) -> Bool {
        if hasUltraOneTimePurchase {
            return true
        }
        
        switch (currentTier, minimumTier) {
        case (.ultra, _):
            return true
        case (.pro, _) where isInProUltraTrial:
            return true
        case (.pro, .pro), (.pro, .none):
            return true
        case (.none, .none):
            return true
        case (.none, _) where isInTrialPeriod:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Purchase Management
        
        @MainActor
        func purchaseOneTime() async throws {
            guard let product = subscriptions.first(where: { $0.id == ultraOneTimeID }) else {
                throw IAPError.productNotFound
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                if case .verified(let transaction) = verificationResult {
                    isInTrialPeriod = false
                    trialTimer?.invalidate()
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    await transaction.finish()
                    await updateCustomerProductStatus()
                }
            case .userCancelled:
                throw IAPError.userCancelled
            case .pending:
                throw IAPError.pending
            @unknown default:
                throw IAPError.unknown
            }
        }
    
        @MainActor
        func purchaseSubscription(tier: SubscriptionTier) async throws {
            guard tier != .none else { return }
            
            let productId = tier == .ultra ? ultraFeatureID : proFeatureID
            guard let product = subscriptions.first(where: { $0.id == productId }) else {
                throw IAPError.productNotFound
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                if case .verified(let transaction) = verificationResult {
                    isInTrialPeriod = false
                    trialTimer?.invalidate()
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    
                    // Start Pro Ultra trial if purchasing Pro subscription
                    if productId == proFeatureID && !KeychainHelper.shared.hasUsedUltraTrial() {
                        startProUltraTrial()
                    }
                    
                    await transaction.finish()
                    await updateCustomerProductStatus()
                }
            case .userCancelled:
                throw IAPError.userCancelled
            case .pending:
                throw IAPError.pending
            @unknown default:
                throw IAPError.unknown
            }
        }
        
        // Update requestProducts to include one-time purchase
        @MainActor
        private func requestProducts() async {
            do {
                subscriptions = try await Product.products(for: [proFeatureID, ultraFeatureID, ultraOneTimeID])
            } catch {
                print("Failed product request: \(error)")
            }
        }
    
        // Add method to check if user has lifetime access
        var hasLifetimeAccess: Bool {
            hasUltraOneTimePurchase
        }
        
    // Update updateCustomerProductStatus to check for one-time purchase
    @MainActor
    private func updateCustomerProductStatus() async {
        var activeTier: SubscriptionTier = .none
        var hasLifetime = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                switch transaction.productID {
                case ultraOneTimeID:
                    hasLifetime = true
                    activeTier = .ultra
                case ultraFeatureID:
                    if !hasLifetime {
                        activeTier = .ultra
                    }
                case proFeatureID:
                    if activeTier != .ultra && !hasLifetime {
                        activeTier = .pro
                    }
                default:
                    break
                }
                await transaction.finish()
            } catch {
                print("Failed updating product status: \(error)")
                }
            }
            
            hasUltraOneTimePurchase = hasLifetime
            currentTier = activeTier
            if activeTier != .none || hasLifetime {
                isInTrialPeriod = false
                trialTimer?.invalidate()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
        
        @MainActor
        func checkPurchaseStatus() async {
            await updateCustomerProductStatus()
        }
        
        @MainActor
        func restorePurchases() async throws {
            print("Starting purchase restoration")
            var hasRestoredPurchases = false
            
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == proFeatureID || transaction.productID == ultraFeatureID {
                        print("Found previous purchase, restoring...")
                        hasRestoredPurchases = true
                        isInTrialPeriod = false
                        trialTimer?.invalidate()
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        await transaction.finish()
                    }
                }
            }
            
            if !hasRestoredPurchases {
                print("No previous purchases found")
                throw IAPError.noRestoredPurchases
            }
            
            await updateCustomerProductStatus()
        }
        
        private func listenForTransactions() -> Task<Void, Error> {
            return Task.detached {
                for await result in Transaction.updates {
                    do {
                        let transaction = try await self.checkVerified(result)
                        await self.updateCustomerProductStatus()
                        await transaction.finish()
                    } catch {
                        print("Transaction failed verification")
                    }
                }
            }
        }
        
        private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
            switch result {
            case .unverified:
                throw IAPError.failedVerification
            case .verified(let safe):
                return safe
            }
        }
        
        // MARK: - Helper Functions
        
        private func showTrialEndNotification() {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Trial Period Ended"
            content.body = "Free users can now access the app with basic features."
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "trial-end-notification",
                content: content,
                trigger: nil  // Show immediately
            )
            
            center.add(request)
        }
        
        func formatTimeRemaining() -> String {
            let days = Int(trialTimeRemaining / (24 * 60 * 60))
            let hours = Int((trialTimeRemaining.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
            if days > 0 {
                return "\(days)d \(hours)h remaining"
            } else {
                return "\(hours)h remaining"
            }
        }
        
        func formatProUltraTrialTimeRemaining() -> String {
            let days = Int(proUltraTrialTimeRemaining / (24 * 60 * 60))
            let hours = Int((proUltraTrialTimeRemaining.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
            if days > 0 {
                return "\(days)d \(hours)h remaining"
            } else {
                return "\(hours)h remaining"
            }
        }
    }
