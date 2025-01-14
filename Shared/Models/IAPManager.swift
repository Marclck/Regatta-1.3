//
//  IAPManager.swift
//  Regatta
//
//  Created by Chikai Lai on 22/12/2024.
//

import Foundation
import StoreKit

enum IAPError: Error {
    case productNotFound
    case userCancelled
    case pending
    case unknown
}

class IAPManager: ObservableObject {
    static let shared = IAPManager()
    private let premiumFeatureID = "com.normalappco.regattawatch.premium.yearly"
    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds
    
    @Published var isPremiumUser = false
    @Published var isInTrialPeriod = false
    @Published var trialTimeRemaining: TimeInterval = 0
    private var trialTimer: Timer?
    
    private init() {
        Task {
            await checkPurchaseStatus()
            checkTrialStatus()
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
                } else {
                    self.isInTrialPeriod = false
                    self.trialTimeRemaining = 0
                }
            } else {
                // Start trial if it's the first time
                self.startTrial()
            }
        }
    }
    
    private func startTrial() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let defaults = UserDefaults.standard
            defaults.set(Date(), forKey: "trialStartDate")
            self.isInTrialPeriod = true
            self.trialTimeRemaining = self.trialDuration
            self.startTrialTimer()
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
    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumFeatureID {
                    isPremiumUser = true
                    isInTrialPeriod = false
                    trialTimer?.invalidate()
                    return
                }
            }
        }
        isPremiumUser = false
    }
    
    @MainActor
    func purchasePremium() async throws {
        guard let product = try? await Product.products(for: [premiumFeatureID]).first else {
            throw IAPError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            if case .verified(let transaction) = verificationResult {
                isPremiumUser = true
                isInTrialPeriod = false
                trialTimer?.invalidate()
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
