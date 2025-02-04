//
//  SubscriptionView.swift
//  Regatta
//
//  Created by Chikai Lai on 23/12/2024.
//

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
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                .multilineTextAlignment(.leading)
        }
    }
}

struct SubscriptionButton: View {
    let title: String
    let price: String
    let action: () -> Void
    let isSubscribed: Bool
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Text(isSubscribed ? "Subscribed" : title)
                        .bold()
                    if !isSubscribed {
                        Text("\(price)/year")
                            .bold()
                    }
                }
                Spacer()
            }
        }
        .disabled(isSubscribed || isLoading)
    }
}

struct SubscriptionCard: View {
    let title: String
    let price: String
    let titleColor: Color
    let action: () -> Void
    let isSubscribed: Bool
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(titleColor)
                
                Text("Subscribe for")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isSubscribed ? "SUBSCRIBED" : price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white, lineWidth: 1)
            )
        }
        .disabled(isSubscribed || isLoading)
    }
}

// Feature Card (with top alignment and spacer)
struct FeatureCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: () -> AnyView
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .scaleEffect(1.5)
                
                Text(title)
                    .font(.system(size: 24, weight: .bold))
            }
            
            AnyView(content())
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05))
        .cornerRadius(12)

    }
}

struct SubscriptionView: View {
    @ObservedObject private var iapManager = IAPManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var selectedTier: SubscriptionTier = .pro
    @State private var selectedFeatureCard: SubscriptionTier = .ultra
    
    private let privacyPolicyURL = URL(string: "https://astrolabe-countdown.apphq.online/privacy")!
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trial Section
                if iapManager.isInTrialPeriod {
                    Text("Free Trial - \(iapManager.formatTimeRemaining())")
                        .font(.system(.body, design: .monospaced, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.top)
                }
                
                // Subscription Buttons
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        // Ultra Subscription
                        SubscriptionCard(
                            title: "ULTRA",
                            price: iapManager.ultraPrice + "/year",
                            titleColor: .orange,
                            action: { purchaseSubscription(.ultra) },
                            isSubscribed: iapManager.currentTier == .ultra,
                            isLoading: isPurchasing && selectedTier == .ultra
                        )
                        .shadow(color: .orange.opacity(0.6), radius: 8, x: 0, y: 2)

                        
                        // Pro Subscription
                        SubscriptionCard(
                            title: "PRO",
                            price: iapManager.proPrice + "/year",
                            titleColor: .blue,
                            action: { purchaseSubscription(.pro) },
                            isSubscribed: iapManager.currentTier != .none,
                            isLoading: isPurchasing && selectedTier == .pro
                        )
                        .shadow(color: .blue.opacity(0.6), radius: 8, x: 0, y: 2)

                    }
                    .padding(.horizontal)
                    
                    // Restore Purchases
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .foregroundColor(.blue)
                    }
                    .disabled(isRestoring)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // Ultra Features Card
                            FeatureCard(
                                title: "Ultra Features",
                                icon: "sailboat.circle.fill",
                                iconColor: .orange,
                                content: { AnyView(ultraFeaturesSection) },
                                isSelected: selectedFeatureCard == .ultra
                            )
                            .frame(width: geometry.size.width * 0.9)
//                            .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 2)
                            
                            // Pro Features Card
                            FeatureCard(
                                title: "Pro Features",
                                icon: "star.circle.fill",
                                iconColor: .yellow,
                                content: { AnyView(proFeaturesSection) },
                                isSelected: selectedFeatureCard == .pro
                            )
                            .frame(width: geometry.size.width * 0.9)
//                            .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 2)
                        }
                        .padding(.horizontal, geometry.size.width * 0.05)
                    }
                    .scrollTargetBehavior(.paging)
                }
                .frame(height: 600)
                
                Spacer()
                
                // Subscription Info and Legal Sections
                VStack(spacing: 24) {
                    subscriptionInfoSection
                        .padding(.horizontal)
                    
                    legalSection
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Subscriptions")
    }
    
    
    private var ultraFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ProControl")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
            
            Text("Advanced button functionality")
                .font(.system(size: 16, weight: .bold))
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            
            FeatureRow(icon: "bolt", text: "QuickStart: start a 5-min countdown immediately upon gun signal")
            FeatureRow(icon: "bolt.ring.closed", text: "GunSync: countdown rounded up or down to closest minute for gun sync")
            FeatureRow(icon: "arrow.counterclockwise", text: "Restart: restart the stopwatch after two taps")
            FeatureRow(icon: "timelapse", text: "Timelapse: change countdown minutes by double tap on timer to sync to the right signal")
            
            Text("Dashboard")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
            
            Text("SOG, COG, Startline and shift tracking, using dual GPS on Apple Watch Ultra")
                .font(.system(size: 16, weight: .bold))
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            
            FeatureRow(icon: "square.fill.and.line.vertical.and.square.fill", text: "Distance to Startline: using dual band GPS to locate pinmark and committee boat and track distance")
            FeatureRow(icon: "dots.and.line.vertical.and.cursorarrow.rectangle", text: "Shift Tracking: automatically track course and shift deviation within 30 degrees")
            FeatureRow(icon: "gauge.open.with.lines.needle.33percent", text: "Speedometer: displaying speed over ground in knots")
        }
    }
    
    private var proFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FeatureRow(icon: "timer", text: "Regatta Countdown Timer - Precise race start timing and real-time race tracking capabilities")
            FeatureRow(icon: "rectangle.stack.fill", text: "Race Info Display - Toggle between minimal and detailed race information")
            FeatureRow(icon: "paintbrush.fill", text: "Custom Team Colors - Personalize your watch face with unique team color schemes")
            FeatureRow(icon: "textformat", text: "Custom Team Name - Display your team name on the face info page (up to 14 characters)")
            FeatureRow(icon: "clock.fill", text: "Smooth Second Hand - Enable fluid second hand movement with precise computation")
            FeatureRow(icon: "paintpalette.fill", text: "Alternate Color Schemes - Switch between different text color combinations")
            FeatureRow(icon: "ruler.fill", text: "Compatibility for Non-Ultra models - UI optimization for non-Ultra watches")
        }
    }
    
    private var subscriptionInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription Info")
                .font(.subheadline)
                .bold()
            
            Group {
                Text("• Subscription automatically renews every year unless cancelled")
                Text("• Cancel anytime through your Apple ID settings")
                Text("• Payment will be charged to your Apple ID account")
                Text("• Any unused portion of a free trial will be forfeited when purchasing a subscription")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legal")
                .font(.subheadline)
                .bold()
            
            Group {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Link("Terms of Use (EULA)", destination: termsOfUseURL)
                }
                
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.blue)
                    Link("Privacy Policy", destination: privacyPolicyURL)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func purchaseSubscription(_ tier: SubscriptionTier) {
        selectedTier = tier
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await iapManager.purchaseSubscription(tier: tier)
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
}

#Preview {
    NavigationView {
        SubscriptionView()
    }
}
