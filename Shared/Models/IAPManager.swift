//
//  IAPManager.swift
//  Regatta
//
//  Created by Chikai Lai on 22/12/2024.
//

import Foundation
import StoreKit

class IAPManager: ObservableObject {
    static let shared = IAPManager()
    private let premiumFeatureID = "com.normalappco.regattawatch.premium.yearly"
    
    @Published var isPremiumUser = false
    
    private init() {
        Task {
            await checkPurchaseStatus()
        }
    }
    
    @MainActor
    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumFeatureID {
                    isPremiumUser = true
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
}

enum IAPError: Error {
    case productNotFound
    case userCancelled
    case pending
    case unknown
}
