//
//  SubscriptionView.swift
//  Regatta
//
//  Created by Chikai Lai on 23/12/2024.
//

import Foundation
import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject private var iapManager = IAPManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Team Customization")
                            .font(.headline)
                    }
                    
                    Text("$5.99 / year")
                        .font(.title2)
                        .bold()
                        .padding(.vertical, 4)
                    
                    Text("Unlock Customization Settings:")
                        .font(.subheadline)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "paintbrush.fill", text: "Custom Team Colors - Personalize your watch face with unique team color schemes")
                        FeatureRow(icon: "textformat", text: "Custom Team Name - Display your team name on the watch face (up to 14 characters)")
                        FeatureRow(icon: "clock.fill", text: "Smooth Second Hand - Enable fluid second hand movement with precise computation")
                        FeatureRow(icon: "rectangle.stack.fill", text: "Race Info Display - Toggle between minimal and detailed race information")
                        FeatureRow(icon: "paintpalette.fill", text: "Alternate Color Schemes - Switch between different text color combinations")
                    }
                    .padding(.vertical, 4)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                if isPurchasing {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    Button(action: {
                        purchaseSubscription()
                    }) {
                        HStack {
                            Spacer()
                            Text(iapManager.isPremiumUser ? "Subscribed" : "Subscribe")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(iapManager.isPremiumUser)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subscription Info")
                        .font(.subheadline)
                        .bold()
                    
                    Text("• Subscription automatically renews unless cancelled")
                    Text("• Cancel anytime through your Apple ID settings")
                    Text("• Payment will be charged to your Apple ID account")
                    Text("• Any unused portion of a free trial will be forfeited when purchasing a subscription")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Premium Features")
    }
    
    private func purchaseSubscription() {
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await iapManager.purchasePremium()
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            isPurchasing = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.system(.body, design: .rounded))
        }
    }
}
