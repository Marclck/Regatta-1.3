//
//  ContentView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 16/11/2024.
//
import SwiftUI
import AVFoundation
import WatchKit
import AVKit
import WatchConnectivity

// WatchConnectivity Session Manager
class WCSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WCSessionManager()
    @Published var isReachable = false
    @Published var isCompanionAppInstalled = false
    private var session: WCSession?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
        }
    }
    
    func startSession() {
        session?.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📱 WCSession Reachability changed: \(session.isReachable)")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("📱 WCSession activation error: \(error.localizedDescription)")
                return
            }
            
            self.isCompanionAppInstalled = session.isCompanionAppInstalled
            self.isReachable = session.isReachable
            print("📱 WCSession activated: \(activationState.rawValue)")
            print("📱 Companion app installed: \(session.isCompanionAppInstalled)")
            print("📱 Reachable: \(session.isReachable)")
        }
    }
    
    // Required delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WCSession deactivated")
        // Reactivate session if needed
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("📱 WCSession watch state changed")
    }
    #endif
    
    // Handle received messages
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📱 Received message: \(message)")
    }
}

private var isUltraWatch: Bool {
    #if os(watchOS)
    return WKInterfaceDevice.current().model.contains("Ultra")
    #else
    return false
    #endif
}

func printWatchModel() {
    #if os(watchOS)
    let device = WKInterfaceDevice.current()
    print("Current Watch Model: \(device.model)")
    print("Current Watch Name: \(device.name)")
    print("Current Watch ppi: \(device.screenBounds)")
    #else
    print("Not running on watchOS")
    #endif
}

struct OverlayPlayerForTimeRemove: View {
    var body: some View {
        VideoPlayer(player: nil, videoOverlay: { })
            .focusable(false)
            .disabled(true)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension UserDefaults {
    static let lastIAPCheckDateKey = "lastIAPCheckDate"
    
    static func getLastIAPCheckDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastIAPCheckDateKey) as? Date
    }
    
    static func setLastIAPCheckDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastIAPCheckDateKey)
    }
}

extension ContentView {
    func shouldShowPromo() -> Bool {
        if let lastShowDate = UserDefaults.getLastPromoShowDate() {
            let calendar = Calendar.current
            if let nextShowDate = calendar.date(byAdding: .day, value: 7, to: lastShowDate) {
                return Date() >= nextShowDate
            }
        }
        return true // If no last show date, show promo
    }
    
    func establishConnectivity() {
        // Access the actual WatchSessionManager implementation from the watch app
        #if os(watchOS)
        // Get the current theme
        let currentTheme = colorManager.selectedTheme
        
        // Send theme update - this seems to reliably establish connectivity
        WatchSessionManager.shared.sendThemeUpdate(theme: currentTheme)
        
        print("⌚️ Establishing connectivity via theme update")
        #endif
    }
}


extension ContentView {
    func shouldPerformIAPCheck() -> Bool {
        if let lastCheckDate = UserDefaults.getLastIAPCheckDate() {
            let calendar = Calendar.current
            if let nextCheckDate = calendar.date(byAdding: .day, value: 1, to: lastCheckDate) {
                return Date() >= nextCheckDate
            }
        }
        return true // If no last check date, perform check
    }
    
    func performDelayedIAPCheck() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [self] in
            // First check if user can access Pro features
            if !iapManager.canAccessFeatures(minimumTier: .pro) {
                settings.resetToDefaults(colorManager)
                viewID = UUID()
            }
            // Then check if user can access Ultra features
            else if !iapManager.canAccessFeatures(minimumTier: .ultra) {
                // Only reset ultra-specific features
                settings.showSpeedInfo = false
                settings.useProButtons = false
                viewID = UUID()
            }
            
            // Update the last check date
            UserDefaults.setLastIAPCheckDate(Date())
        }
    }
    
    // New function to ensure watch connectivity
    func ensureWatchConnectivity() {
        // Start the WCSession
        WCSessionManager.shared.startSession()
        
        // Immediately attempt to establish connectivity
        establishConnectivity()
        
        // Check reachability every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            if !WCSessionManager.shared.isReachable {
                print("📱 Reachability lost, reactivating session")
                WCSessionManager.shared.startSession()
            }
        }
    }
}

struct ContentView: View {
    @State private var showSettings = false
    @State private var showPremiumAlert = false
    @State private var showStartLine = false
    @State private var showUltraTrialPromotion = false
    @EnvironmentObject var colorManager: ColorManager
    @State private var lastTheme: ColorTheme = .cambridgeBlue  // Add this state var
    @EnvironmentObject var settings: AppSettings
    @StateObject private var iapManager = IAPManager.shared
    @State private var refreshToggle = false
    private let impactGenerator = WKHapticType.click

    @State private var viewID = UUID()
    @State private var lastTeamName = ""
    @State private var lastRaceInfoState = false
    @State private var lastSpeedInfoState = false
    
    @StateObject private var timerState = WatchTimerState()
    @State private var showingWatchFace = false
    @State private var showWeeklyPromo = false
    
    // Add WatchConnectivity manager
    @ObservedObject private var wcSession = WCSessionManager.shared
    @State private var connectivityTimer: Timer?
    @EnvironmentObject var cruisePlanState: WatchCruisePlanState

    var body: some View {
        ZStack {
            if showingWatchFace {
                if settings.showRaceInfo {
                    WatchFaceView(timerState: timerState, cruisePlanState: cruisePlanState)
                } else {
                    AltRaceView(timerState: timerState)
                }
            } else {
                TimerView(timerState: timerState, showStartLine: $showStartLine)
            }
            
            // Toggle overlay - only show when not in start line mode
            if !showStartLine {
                GeometryReader { geometry in
                    Color.clear
                        .frame(width: 80, height: 40)
                        .contentShape(Rectangle())
                        .position(x: geometry.size.width/2, y: geometry.size.height/2 - 90)
                        .onTapGesture {
                            print("!! watchface toggled")
                            WKInterfaceDevice.current().play(impactGenerator)
                            withAnimation {
                                showingWatchFace.toggle()
                            }
                        }
                }
            }
            
            // Optional: Add connectivity status indicator (only during development)
            /* #if DEBUG
            VStack {
                Spacer()
                if !wcSession.isReachable {
                    Text("📱 Disconnected")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                        .padding(2)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                }
            }
            .padding(.bottom, 2)
            #endif */
        }
        .id(viewID)
        .onChange(of: settings.teamName) { _, newValue in
            if lastTeamName != newValue {
                viewID = UUID()
                lastTeamName = newValue
            }
        }
        .onChange(of: settings.showRaceInfo) { _, newValue in
            if lastRaceInfoState != newValue {
                viewID = UUID()
                lastRaceInfoState = newValue
            }
        }
        .onChange(of: colorManager.selectedTheme) { _, newValue in
            if lastTheme != newValue {
                viewID = UUID()
                lastTheme = newValue
            }
        }
        .onChange(of: settings.showSpeedInfo) { _, newValue in
            if lastSpeedInfoState != newValue {
                viewID = UUID()
                lastSpeedInfoState = newValue
            }
        }
        .onAppear {
            lastTeamName = settings.teamName
            lastRaceInfoState = settings.showRaceInfo
            lastSpeedInfoState = settings.showSpeedInfo
            lastTheme = colorManager.selectedTheme
            printWatchModel()
            
            // Ensure watch connectivity
            ensureWatchConnectivity()
            
            // Check for trial promotion eligibility
            if iapManager.isProUltraTrialAvailable {
                showUltraTrialPromotion = true
            }
            
            // Only perform IAP check once per day
            if shouldPerformIAPCheck() {
                performDelayedIAPCheck()
            }
            
            // Start extended session for background communication
            if timerState.isRunning {
                startExtendedSession()
            }
            
            // Add this to your existing onAppear
            if shouldShowPromo() {
                showWeeklyPromo = true
            }
        }
        .onDisappear {
            // Clean up the connectivity timer when view disappears
            connectivityTimer?.invalidate()
            connectivityTimer = nil
        }
        
        .sheet(isPresented: $showSettings, onDismiss: {
            withAnimation {
                refreshToggle.toggle()
            }
        }) {
            if !iapManager.canAccessFeatures(minimumTier: .pro) {
                SubscriptionOverlay()
            }
            SettingsView(showSettings: $showSettings)
        }
        .sheet(isPresented: $showPremiumAlert) {
            PremiumAlertView()
        }
        .sheet(isPresented: $showUltraTrialPromotion) {
            UltraTrialPromotionSheet(showSettings: $showSettings)
        }
        .gesture(
            LongPressGesture(minimumDuration: 1.0)
                .onEnded { _ in
                    WKInterfaceDevice.current().play(impactGenerator)
                    showSettings = true
                }
        )
        .sheet(isPresented: $showWeeklyPromo) {
            WeeklyPromoView(isPresented: $showWeeklyPromo)
        }
    }
    
    // Add function to start extended session
    private func startExtendedSession() {
        #if os(watchOS)
        let session = WKExtendedRuntimeSession()
        session.start()
        print("⌚️ Extended runtime session started")
        #endif
    }
}

struct TimerView: View {
    @ObservedObject var timerState: WatchTimerState
    @StateObject private var locationManager = LocationManager()
    @StateObject private var startLineManager = StartLineManager()
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @Binding var showStartLine: Bool
    @EnvironmentObject var settings: AppSettings
    @ObservedObject private var iapManager = IAPManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                GeometryReader { geometry in
                    let centerY = geometry.size.height/2
                    ZStack {
                        WatchProgressBarView(timerState: timerState)
                        
                        VStack(spacing: 0) {
                            ZStack {
                                CurrentTimeView(timerState: timerState)
                                    .padding(.top, -10)
                                    .offset(y: -10)
                            }
                            
                            Spacer()
                                .frame(height: 0)
                            
                            TimeDisplayView(timerState: timerState)
                                .frame(height: 150)
                                .position(x: geometry.size.width/2, y: centerY/2+10)
                            
                            Spacer()
                                .frame(height: 0)
                            
                            if settings.ultraModel {
                                // Only use pro buttons if user has any subscription (Pro or Ultra)
                                if settings.useProButtons && iapManager.canAccessFeatures(minimumTier: .pro) {
                                    ProButtonsView(timerState: timerState)
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: 0)
                                } else {
                                    ButtonsView(timerState: timerState)
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: 0)
                                }
                            } else {
                                if settings.useProButtons && iapManager.canAccessFeatures(minimumTier: .pro) {
                                    ProButtonsView(timerState: timerState)
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: -5)
                                } else {
                                    ButtonsView(timerState: timerState)
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: -5)
                                }
                            }
                        }
                        .padding(.horizontal, 0)
                        
                        // Show speed info if user has any subscription (Pro or Ultra)
                        if settings.showSpeedInfo && iapManager.canAccessFeatures(minimumTier: .pro) {
                            AltSpeedInfoView(
                                locationManager: locationManager,
                                timerState: timerState,
                                startLineManager: startLineManager,
                                isCheckmark: $showStartLine
                            )
                            .offset(y: timerState.isRunning ? -35 : -66)
                        }
                        
                        ZStack {
                            if showStartLine {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 40)
                                    .frame(maxWidth: 110)
                                    .offset(x: timerState.isRunning ? 0 : 22.5, y: -90)
                                
                                StartLineView(
                                    locationManager: locationManager,
                                    startLineManager: startLineManager
                                )
                                .padding(.top, -10)
                                .offset(x: timerState.isRunning ? 0 : 22.5, y: -81)
                            }
                        }
                    }
                    .onReceive(timer) { _ in
                        timerState.updateTimer()
                    }
                    .onAppear {
                        // Pass in the timerState but let the manager decide if a new session is needed
//                        ExtendedSessionManager.shared.startSession(timerState: timerState)
//                        print("⌚️ View: Ensured extended runtime session is active")
                    }
                    .onDisappear {
//                        ExtendedSessionManager.shared.startSession(timerState: timerState)
//                        print("⌚️ View: Ensured extended runtime session is active")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ColorManager())
        .environmentObject(AppSettings())
}
