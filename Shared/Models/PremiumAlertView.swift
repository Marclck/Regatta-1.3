//
//  PremiumAlertView.swift
//  Regatta
//
//  Created by Chikai Lai on 22/12/2024.
//

import SwiftUI
import StoreKit

struct SubscriptionFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let includedIn: [SubscriptionTier]
}

struct PremiumAlertView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var iapManager = IAPManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var selectedTier: SubscriptionTier = .pro
    
    private let features: [SubscriptionFeature] = [
        SubscriptionFeature(
            title: "Basic Features",
            description: "Essential app functionality",
            includedIn: [.pro, .ultra]
        ),
        SubscriptionFeature(
            title: "Advanced Settings",
            description: "Customization options and advanced controls",
            includedIn: [.pro, .ultra]
        ),
        SubscriptionFeature(
            title: "Ultra Features",
            description: "Premium analytics and exclusive tools",
            includedIn: [.ultra]
        )
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .bold()
            
            if iapManager.isInTrialPeriod {
                Text("Trial Period Active\n\(iapManager.formatTimeRemaining())")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                // Pro Tier Card
                subscriptionCard(
                    tier: .pro,
                    title: "Pro",
                    price: iapManager.proPrice
                )
                
                // Ultra Tier Card
                subscriptionCard(
                    tier: .ultra,
                    title: "Ultra",
                    price: iapManager.ultraPrice
                )
            }
            .padding(.horizontal)
            
            // Feature comparison
            VStack(alignment: .leading, spacing: 12) {
                Text("Features")
                    .font(.headline)
                
                ForEach(features) { feature in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(feature.title)
                                .font(.subheadline)
                                .bold()
                            Text(feature.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Image(systemName: feature.includedIn.contains(.pro) ? "checkmark" : "xmark")
                                .foregroundColor(feature.includedIn.contains(.pro) ? .green : .gray)
                            Image(systemName: feature.includedIn.contains(.ultra) ? "checkmark" : "xmark")
                                .foregroundColor(feature.includedIn.contains(.ultra) ? .green : .gray)
                        }
                    }
                }
            }
            .padding()
            
            if isPurchasing {
                ProgressView()
            } else if iapManager.currentTier == .none {
                purchaseButton
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
    
    private func subscriptionCard(tier: SubscriptionTier, title: String, price: String) -> some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(price + "/year")
                .font(.subheadline)
            
            RadioButton(
                selected: selectedTier == tier,
                action: { selectedTier = tier }
            )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedTier == tier ? Color.blue : Color.gray.opacity(0.3))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTier = tier
        }
    }
    
    private var purchaseButton: some View {
        Button(action: {
            Task {
                isPurchasing = true
                do {
                    try await iapManager.purchaseSubscription(tier: selectedTier)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isPurchasing = false
            }
        }) {
            Text(iapManager.isInTrialPeriod ? "Subscribe Now" : "Subscribe")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

struct RadioButton: View {
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(selected ? Color.blue : Color.gray, lineWidth: 2)
                    .frame(width: 20, height: 20)
                
                if selected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

#Preview {
    PremiumAlertView()
}
