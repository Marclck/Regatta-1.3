//
//  PremiumAlertView.swift
//  Regatta
//
//  Created by Chikai Lai on 22/12/2024.
//

import Foundation
import StoreKit
import SwiftUI

struct PremiumAlertView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var iapManager = IAPManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Astrolabe Pro")
                .font(.headline)
            
            if iapManager.isInTrialPeriod {
                Text("You're in trial period!\n\(iapManager.formatTimeRemaining())")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            } else {
                Text("Full app access with advanced settings and customization options")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            if isPurchasing {
                ProgressView()
            } else if !iapManager.isPremiumUser {
                Button(action: {
                    Task {
                        isPurchasing = true
                        do {
                            try await iapManager.purchasePremium()
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isPurchasing = false
                    }
                }) {
                    Text(iapManager.isInTrialPeriod ? "Subscribe Now ($5.99/year)" : "Subscribe ($5.99/year)")
                        .bold()
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
