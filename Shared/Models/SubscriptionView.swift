//
//  SubscriptionView.swift
//  Regatta
//
//  Created by Chikai Lai on 23/12/2024.
//

import Foundation
import SwiftUI
import StoreKit

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

struct SubscriptionView: View {
    @ObservedObject private var iapManager = IAPManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Astrolabe Pro")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "timer", text: "Regatta Countdown Timer - Precise race start timing and real-time race tracking capabilities")
                        FeatureRow(icon: "rectangle.stack.fill", text: "Race Info Display - Toggle between minimal and detailed race information")
                        FeatureRow(icon: "paintbrush.fill", text: "Custom Team Colors - Personalize your watch face with unique team color schemes")
                        FeatureRow(icon: "textformat", text: "Custom Team Name - Display your team name on the face info page (up to 14 characters)")
                        FeatureRow(icon: "clock.fill", text: "Smooth Second Hand - Enable fluid second hand movement with precise computation")
                        FeatureRow(icon: "paintpalette.fill", text: "Alternate Color Schemes - Switch between different text color combinations")
                        FeatureRow(icon: "ruler.fill", text: "Compatibility for Non-Ultra models - UI optimization for non-Ultra watches")
                    }
                        
                    if iapManager.isInTrialPeriod {
                        Text("Free Trial - \(iapManager.formatTimeRemaining())")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.cyan)
                    }
                }
            }
            
            Section {
                VStack {
                    if isPurchasing || isRestoring {
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
                                Text(buttonText)
                                    .bold()
                                if !iapManager.isPremiumUser {
                                    Text("\(iapManager.localizedPrice)/year")
                                        .bold()
                                }
                                Spacer()
                            }
                        }
                        .disabled(iapManager.isPremiumUser)
                        
                        Button(action: {
                            restorePurchases()
                        }) {
                            HStack {
                                Spacer()
                                Text("Restore Purchases")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
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
                    
                    Text("• Subscription automatically renews every year unless cancelled")
                    Text("• Cancel anytime through your Apple ID settings")
                    Text("• Payment will be charged to your Apple ID account")
                    Text("• Any unused portion of a free trial will be forfeited when purchasing a subscription")
                    
                    Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    
                    Link("Privacy Policy", destination: URL(string: "https://astrolabe-countdown.apphq.online/privacy")!)
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func purchaseSubscription() {
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await iapManager.purchasePremium()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        errorMessage = nil
        
        Task {
            do {
                try await iapManager.restorePurchases()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isRestoring = false
        }
    }
    
    private var buttonText: String {
        if iapManager.isPremiumUser {
            return "Subscribed"
        } else if iapManager.isInTrialPeriod {
            return "Subscribe to Astrolabe Pro"
        } else {
            return "Subscribe to Astrolabe Pro"
        }
    }
}
