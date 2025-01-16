//
//  IAPManager.swift
//  Regatta
//
//  Created by Chikai Lai on 22/12/2024.
//

import Foundation
import StoreKit
import UserNotifications

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
    private let premiumFeatureID = "Astrolabe_pro_access_annual_599"
    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds
    
    @Published private(set) var subscriptions: [Product] = []
    @Published var isPremiumUser = false
    @Published var isInTrialPeriod = false
    @Published var trialTimeRemaining: TimeInterval = 0
    
    var localizedPrice: String {
        subscriptions.first?.displayPrice ?? "$6.99"
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
            subscriptions = try await Product.products(for: [premiumFeatureID])
        } catch {
            print("Failed product request: \(error)")
        }
    }
    
    private func checkTrialStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let defaults = UserDefaults.standard
            let trialStartDate = defaults.object(forKey: "trialStartDate") as? Date
            
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
        
        // Request permission
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else { return }
            
            // Remove any existing notifications
            center.removeAllPendingNotificationRequests()
            
            // Schedule reminders
            let reminders = [
                (days: 5, message: "5 days left in your Astrolabe Pro trial!"),
                (days: 3, message: "Only 3 days remaining in your trial - Subscribe now to keep access"),
                (days: 1, message: "Last day of your trial - Don't lose access to Astrolabe Pro")
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
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == premiumFeatureID {
                    hasActiveSubscription = true
                }
                await transaction.finish()
            } catch {
                print("Failed updating product status: \(error)")
            }
        }
        
        isPremiumUser = hasActiveSubscription
        if hasActiveSubscription {
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
        
        // Check all the user's previous purchases
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumFeatureID {
                    print("Found previous purchase, restoring...")
                    hasRestoredPurchases = true
                    isPremiumUser = true
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
    func purchasePremium() async throws {
        guard let product = subscriptions.first else {
            throw IAPError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            if case .verified(let transaction) = verificationResult {
                isPremiumUser = true
                isInTrialPeriod = false
                trialTimer?.invalidate()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                await transaction.finish()
            }
        case .userCancelled:
            throw IAPError.userCancelled
        case .pending:
            throw IAPError.pending
        @unknown default:
            throw IAPError.unknown
        }
    }
    
    func canAccessPremiumFeatures() -> Bool {
        return isPremiumUser || isInTrialPeriod
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
