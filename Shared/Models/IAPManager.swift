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
        }
    }
}

class IAPManager: ObservableObject {
    static let shared = IAPManager()
    private let proFeatureID = "Astrolabe_pro_access_annual_599"
    private let ultraFeatureID = "Astrolabe_ultra_access_annual_1499"
    private let trialDuration: TimeInterval = 900 * 24 * 60 * 60 // 7 days in seconds
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var currentTier: SubscriptionTier = .none
    @Published var isInTrialPeriod = false
    @Published var trialTimeRemaining: TimeInterval = 0
    
    var proPrice: String {
        subscriptions.first { $0.id == proFeatureID }?.displayPrice ?? "$6.99"
    }
    
    var ultraPrice: String {
        subscriptions.first { $0.id == ultraFeatureID }?.displayPrice ?? "$14.99"
    }
    
    private var trialTimer: Timer?
    private var updateListenerTask: Task<Void, Error>? = nil
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await checkPurchaseStatus()
            await MainActor.run {
                checkTrialStatus()
            }
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
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
    
    @MainActor
    private func requestProducts() async {
        do {
            subscriptions = try await Product.products(for: [proFeatureID, ultraFeatureID])
        } catch {
            print("Failed product request: \(error)")
        }
    }
    
    private func checkTrialStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let defaults = UserDefaults.standard
            let trialStartDate = defaults.object(forKey: "trialStartDate") as? Date
            let hasShownTrialEndNotification = defaults.bool(forKey: "hasShownTrialEndNotification")
            
            if let startDate = trialStartDate {
                let timeElapsed = Date().timeIntervalSince(startDate)
                if timeElapsed < self.trialDuration {
                    self.isInTrialPeriod = true
                    self.trialTimeRemaining = self.trialDuration - timeElapsed
                    self.startTrialTimer()
                    self.scheduleTrialReminders(startDate: startDate)
                } else {
                    self.isInTrialPeriod = false
                    self.trialTimeRemaining = 0
                    
                    // Check if user has already seen end notification
                    if !hasShownTrialEndNotification {
                        // Schedule end-of-trial notification
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
                        
                        // Mark notification as shown
                        defaults.set(true, forKey: "hasShownTrialEndNotification")
                    }
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
            let defaults = UserDefaults.standard
            defaults.set(startDate, forKey: "trialStartDate")
            self.isInTrialPeriod = true
            self.trialTimeRemaining = self.trialDuration
            self.startTrialTimer()
            self.scheduleTrialReminders(startDate: startDate)
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
    
    @MainActor
    private func updateCustomerProductStatus() async {
        var activeTier: SubscriptionTier = .none
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                switch transaction.productID {
                case ultraFeatureID:
                    activeTier = .ultra
                case proFeatureID:
                    // Only set to pro if we haven't found an ultra subscription
                    if activeTier != .ultra {
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
        
        currentTier = activeTier
        if activeTier != .none {
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
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw IAPError.failedVerification
        case .verified(let safe):
            return safe
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
    
    func canAccessFeatures(minimumTier: SubscriptionTier) -> Bool {
        switch (currentTier, minimumTier) {
        case (.ultra, _):
            // Ultra subscription can access everything
            return true
        case (.pro, .pro), (.pro, .none):
            // Pro subscription can access Pro and free features
            return true
        case (.none, .none):
            // Free features are always accessible
            return true
        case (.none, _) where isInTrialPeriod:
            // During trial, users can access both Pro and Ultra features
            return true
        default:
            return false
        }
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
}
