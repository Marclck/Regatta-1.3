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
                    .font(.system(size: 16, weight: .bold))
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

struct PurchaseCard: View {
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
                
                Text("One-Time Purchase for ULTRA Access")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Limited Time Offer")
                    .font(.system(size: 16))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow.opacity(0.2))
                    .foregroundColor(.yellow)
                    .cornerRadius(8)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isSubscribed ? "Purchased" : price)
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray, lineWidth: 1)
            )
    }
}

struct FeatureCarouselItem: Identifiable {
    let id = UUID()
    let image: String
    let tier: String
    let featureName: String
    let description: String
}

struct FeatureCarouselCard: View {
    let item: FeatureCarouselItem
    
    var body: some View {
        HStack(spacing: 20) {
            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.tier)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(item.tier == "ULTRA" ? .orange : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (item.tier == "ULTRA" ? Color.orange : Color.blue)
                            .opacity(0.2)
                    )
                    .clipShape(Capsule())
                
                Text(item.featureName)
                    .font(.system(size: 24, weight: .bold))
                
                Text(item.description)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}



struct FeatureCarousel: View {
    private let items = [
        FeatureCarouselItem(
            image: "Procontrol",
            tier: "ULTRA",
            featureName: "ProControl",
            description: "GynSync and Quickstart buttons for precise race control and timing management."
        ),
        FeatureCarouselItem(
            image: "Timer",
            tier: "ULTRA",
            featureName: "Dashboard",
            description: "Comprehensive sailing metrics with SOG, COG, and startline tracking using dual GPS."
        ),
        FeatureCarouselItem(
            image: "CruiseR",
            tier: "ULTRA",
            featureName: "CruiseR",
            description: "A NEW display from timer that display crucial sailing info including real-time wind and speed/course analysis."
        ),
        FeatureCarouselItem(
            image: "Settings",
            tier: "PRO",
            featureName: "Personalize",
            description: "Customize your experience with team colors, names, and display preferences."
        )
    ]
    
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                FeatureCarouselCard(item: item)
                    .tag(index)
                    .id(item.image)
            }
        }
        .frame(height: 240)
        .animation(.easeInOut(duration: 1.0), value: currentIndex)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onAppear {
            // Start the timer when the view appears
            startTimer()
        }
        .onDisappear {
            // Clean up the timer when the view disappears
            stopTimer()
        }
        .onChange(of: currentIndex) { newIndex in
            // Reset timer when user manually swipes
            restartTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.7)) {
                currentIndex = (currentIndex + 1) % items.count
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func restartTimer() {
        stopTimer()
        startTimer()
    }
}

struct SubscriptionView: View {
    @ObservedObject private var iapManager = IAPManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var selectedTier: SubscriptionTier = .pro
    @State private var selectedFeatureCard: SubscriptionTier = .ultra
    @State private var isOneTimePurchasing = false

    private let privacyPolicyURL = URL(string: "https://astrolabe-countdown.apphq.online/privacy")!
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    private func purchaseOneTime() {
        isOneTimePurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await iapManager.purchaseOneTime()
            } catch {
                errorMessage = error.localizedDescription
            }
            isOneTimePurchasing = false
        }
    }
    
    var body: some View {
        
        ScrollView {
            
            FeatureCarousel()
                .padding(.top)
            
            VStack(spacing: 24) {
                // Trial Section
                if iapManager.currentTier == .none && iapManager.isInTrialPeriod {
                    Text("Free Trial - \(iapManager.formatTimeRemaining())")
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.top)
                }
                
                // Pro Ultra Trial Section - Only show for Pro subscribers during active trial
                if iapManager.currentTier == .pro && iapManager.isInProUltraTrial {
                    Text("Ultra Trial - \(iapManager.formatProUltraTrialTimeRemaining())")
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.top)
                }
                
                // Subscription Buttons
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        // Ultra Subscription
                        SubscriptionCard(
                            title: "ULTRA",
                            price: iapManager.ultraPrice + " / year",
                            titleColor: .orange,
                            action: { purchaseSubscription(.ultra) },
                            isSubscribed: iapManager.currentTier == .ultra,
                            isLoading: isPurchasing && selectedTier == .ultra
                        )
                        .shadow(color: .orange.opacity(1), radius: 25, x: 0, y: 2)

                        
                        // Pro Subscription
                        SubscriptionCard(
                            title: "PRO",
                            price: iapManager.proPrice + " / year",
                            titleColor: .blue,
                            action: { purchaseSubscription(.pro) },
                            isSubscribed: iapManager.currentTier != .none,
                            isLoading: isPurchasing && selectedTier == .pro
                        )
                        .shadow(color: .blue.opacity(0.6), radius: 15, x: 0, y: 2)

                    }
                    .padding(.horizontal)
                    
                    // Then replace the PurchaseCard section with:
                    PurchaseCard(
                        title: "ULTRA for Sailing Enthusiasts",
                        price: iapManager.ultraOneTimePrice + " / One-time",
                        titleColor: .purple,
                        action: { purchaseOneTime() },
                        isSubscribed: iapManager.hasLifetimeAccess,
                        isLoading: isOneTimePurchasing
                    )
                    .shadow(color: .purple.opacity(1), radius: 25, x: 0, y: 2)
                    .padding(.horizontal)

                    
                    // Restore Purchases
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .disabled(isRestoring)
                    
                    Text("subscription can be cancelled any time")
                        .font(.system(size: 12))
                        .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                GeometryReader { geometry in
                    VStack(spacing: 20) {
                        // Ultra Features Card
                        FeatureCard(
                            title: " ULTRA Access",
                            icon: "sailboat.circle.fill",
                            iconColor: .orange,
                            content: { AnyView(ultraFeaturesSection) },
                            isSelected: selectedFeatureCard == .ultra
                        )
                        .frame(width: geometry.size.width * 0.9)
                        
                        // Pro Features Card
                        FeatureCard(
                            title: " PRO Access",
                            icon: "star.circle.fill",
                            iconColor: .yellow,
                            content: { AnyView(proFeaturesSection) },
                            isSelected: selectedFeatureCard == .pro
                        )
                        .frame(width: geometry.size.width * 0.9)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, geometry.size.width * 0.05)
                }
                
                Spacer()
                    .frame(minHeight: 1800)
                
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
        .navigationTitle("Feature Access")
    }
    
    
    private var ultraFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack{
                Text("Plus all")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                Text("Pro")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                Text("Access features")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap

            }
            
            Text("ProControl")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
            
            Text("Advanced Button Racing Control")
                .font(.system(size: 16, weight: .bold))
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            
            FeatureRow(icon: "bolt", text: "QuickStart: start a 5-min countdown immediately upon gun signal")
            FeatureRow(icon: "bolt.ring.closed", text: "GunSync: countdown rounded up or down to closest minute for gun sync")
            FeatureRow(icon: "arrow.counterclockwise", text: "Restart: restart the stopwatch after two taps")
            FeatureRow(icon: "timelapse", text: "Timelapse: change countdown minutes by double tap on timer to sync to the right signal")
            
            Text("Dashboard")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
            
            Text("SOG, COG, Startline and Shift Tracking, Using Dual GPS on Apple Watch Ultra")
                .font(.system(size: 16, weight: .bold))
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            
            FeatureRow(icon: "square.fill.and.line.vertical.and.square.fill", text: "Distance to Startline: using dual band GPS to locate pinmark and committee boat and track distance")
            FeatureRow(icon: "dots.and.line.vertical.and.cursorarrow.rectangle", text: "Shift Tracking: automatically track course and shift deviation within 30 degrees")
            FeatureRow(icon: "gauge.open.with.lines.needle.33percent", text: "Speedometer: displaying speed over ground in knots")
            

            HStack(spacing: 8) {
                
                Text("CruiseR")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
                
                Text("NEW")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                    .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    .cornerRadius(8)
            }
            
            Text("At-a-Glance Cruising Display on Your Wrist")
                .font(.system(size: 16, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            
            FeatureRow(icon: "gauge.with.needle", text: "Speed Tracking: SOG display with GPS toggle for precise speed monitoring")
            FeatureRow(icon: "wind", text: "Wind Analysis: Real-time wind speed and directional indicators with compass bearing")
            FeatureRow(icon: "location.north.line", text: "Course Monitor: Deviation tracking with North reference and 10° indicators")
            FeatureRow(icon: "thermometer.medium", text: "Weather Station: Integrated weather data and barometric pressure readings")
            FeatureRow(icon: "point.topleft.down.curvedto.point.bottomright.up", text: "Journey Stats: Distance traveled with continuous tracking")
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
