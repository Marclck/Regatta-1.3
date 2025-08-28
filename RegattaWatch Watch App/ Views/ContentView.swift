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


// Screen size detection
let device = WKInterfaceDevice.current()
let screenBounds = device.screenBounds
let smallWatch: Bool = screenBounds.height < 224

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
    print("Current Watch ppi: \(device.screenBounds.height)")

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
    // Add these new state variables for luminance tracking
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @State private var originalLightModeState: Bool? = nil
    @State private var hasUserManuallyChangedLightMode = false

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
    @State private var hasInitializedLaunchScreen = false

    @State private var showCruiseInfo = true

    var body: some View {
        ZStack {
            if showingWatchFace {
                if settings.showRaceInfo {
                    WatchFaceView(
                        showingWatchFace: $showingWatchFace, timerState: timerState,
                        cruisePlanState: cruisePlanState, showCruiseInfo: $showCruiseInfo
                    )
                } else {
                    AltRaceView(
                        timerState: timerState,
                        showingWatchFace: $showingWatchFace
                    )
                }
            } else {
                TimerView(
                    timerState: timerState,
                    showStartLine: $showStartLine,
                    showingWatchFace: $showingWatchFace
                )
            }
            
            
            // Toggle overlay - only show when not in start line mode
            if !showStartLine {
                GeometryReader { geometry in
                    Color.clear
                        .frame(width: 80, height: settings.useProButtons && settings.showRaceInfo && showingWatchFace && !showCruiseInfo ? 80 : 40)
                        .contentShape(Rectangle())
                        .position(x: geometry.size.width/2, y: settings.useProButtons && settings.showRaceInfo && showingWatchFace && !showCruiseInfo ? geometry.size.height/2 + 50 : geometry.size.height/2 - 90)
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
//        .colorMultiply(.red)
//        .colorMultiply(Color(hex: colorManager.selectedTheme.rawValue))
        .id(viewID)
        // Add this new onChange modifier for luminance monitoring
        .onChange(of: isLuminanceReduced) { oldValue, newValue in
            handleLuminanceChange(isReduced: newValue)
        }
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
            
            if !hasInitializedLaunchScreen {
                switch settings.launchScreen {
                case .timer:
                    showingWatchFace = false
                case .cruiser, .time:
                    showingWatchFace = true
                }
                hasInitializedLaunchScreen = true
            }
            
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
            // Store the original light mode state when view first appears
            if originalLightModeState == nil {
                // If user has auto dark mode enabled, ensure lightMode is true (their base preference)
                if settings.autoDarkMode && !settings.lightMode {
                    settings.lightMode = true
                    print("App launch: Restored lightMode to true for auto dark mode user")
                }
                originalLightModeState = settings.lightMode
            }
            
            // Add observer for switching to timer view
            NotificationCenter.default.addObserver(
                forName: Notification.Name("SwitchToTimerView"),
                object: nil,
                queue: .main
            ) { [self] _ in
                showingWatchFace = false
            }
        }
        .onDisappear {
            // Clean up the connectivity timer when view disappears
            connectivityTimer?.invalidate()
            connectivityTimer = nil
            
            // Remove notification observers
            NotificationCenter.default.removeObserver(self, name: Notification.Name("SwitchToTimerView"), object: nil)
        }
        
        .sheet(isPresented: $showSettings, onDismiss: {
            // Original toggle for refreshToggle
            withAnimation {
                refreshToggle.toggle()
            }
            
            // First toggle of showingWatchFace
            withAnimation {
                showingWatchFace.toggle()
            }
            
            // Second toggle with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showingWatchFace.toggle()
                }
                print("!! Double toggle of watchface completed from settings")
            }
        }) {
            NavigationView {
                VStack {
//                    if !iapManager.canAccessFeatures(minimumTier: .pro) {
//                        SubscriptionOverlay()
//                    } else {
                        SettingsView(showSettings: $showSettings)
//                    }
                }
                .navigationTitle("Settings")
                    
            }
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
    
    // Add this helper function
    private func handleLuminanceChange(isReduced: Bool) {
        // Only proceed if the original state was light mode ON
        guard let originalState = originalLightModeState, originalState else {
            // User originally had light mode OFF - don't do any auto-toggling
            return
        }
        
        // Only auto-toggle if user hasn't manually changed light mode recently
        guard !hasUserManuallyChangedLightMode else { return }
        
        if isReduced {
            // Screen is dimmed - turn off light mode (only if it's currently on)
            if self.isLuminanceReduced && self.settings.lightMode && self.settings.autoDarkMode {
                print("🔅 Luminance reduced for 0.5s - auto-switching to dark mode")
                self.settings.lightMode = false
            }
        } else {
            // Screen is back to normal - restore to light mode (since user originally preferred it)
            if !settings.lightMode && settings.autoDarkMode {
                print("🔆 Luminance restored - auto-switching back to light mode")
                settings.lightMode = true
            }
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

// Alternative: If you want a simpler implementation without tracking manual changes
extension ContentView {
    private func simpleLuminanceHandling(isReduced: Bool) {
        // Only proceed if user originally preferred light mode
        guard let originalState = originalLightModeState, originalState else {
            return // Do nothing if user originally had dark mode
        }
        
        if isReduced && settings.lightMode {
            // Always turn off light mode when luminance is reduced
            settings.lightMode = false
        } else if !isReduced && !settings.lightMode {
            // Always turn on light mode when luminance is restored
            // (only if user originally preferred light mode)
            settings.lightMode = true
        }
    }
}

struct TimerView: View {
    @StateObject var persistentTimer = PersistentTimerManager()
    @ObservedObject var timerState: WatchTimerState
    @StateObject private var locationManager = LocationManager()
    @StateObject private var startLineManager = StartLineManager()
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @Binding var showStartLine: Bool
    @EnvironmentObject var settings: AppSettings
    @ObservedObject private var iapManager = IAPManager.shared
    
    // Add these new parameters
    @EnvironmentObject var cruisePlanState: WatchCruisePlanState
    @Binding var showingWatchFace: Bool
    @State private var viewUpdateTrigger = UUID()

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                GeometryReader { geometry in
                    let centerY = geometry.size.height/2
                    ZStack {
                        if settings.lightMode {
                             Color.white.edgesIgnoringSafeArea(.all)
                         } else {
                             Color.black.edgesIgnoringSafeArea(.all)
                         }
                        
                        if cruisePlanState.isActive && timerState.mode == .stopwatch {
                            WaypointProgressBarView(
                                plannerManager: WatchPlannerDataManager.shared,
                                locationManager: locationManager
                            )
                        } else {
                            WatchProgressBarView(timerState: timerState)
                        }
                        
                        VStack(spacing: 0) {
                            ZStack {
                                CurrentTimeView(timerState: timerState)
                                    .padding(.top, -10)
                                    .offset(y: smallWatch ? -15 : -10)
                            }
                            
                            Spacer()
                                .frame(height: 0)

                            if !(settings.timeFont == "Default") {
                                TimeDisplayViewV5(timerState: timerState)
                                    .frame(height: 150)
                                    .position(x: geometry.size.width/2, y: centerY/2+10)
                                    .offset(y:-2)
                            } else {
                                TimeDisplayView(timerState: timerState)
                                    .frame(height: 150)
                                    .position(x: geometry.size.width/2, y: centerY/2+10)
                            }
                            
                            
                            Spacer()
                                .frame(height: 0)
                            
                            if smallWatch {
                                // Only use pro buttons if user has any subscription (Pro or Ultra)
                                if settings.useProButtons && iapManager.canAccessFeatures(minimumTier: .pro) {
                                    ProButtonsView(timerState: timerState)
                                        .scaleEffect(smallWatch ?
                                                     CGSize(width: 1.1, height: 1.1) :
                                                     CGSize(width: 1, height: 1))
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: 10)
                                } else {
                                    ButtonsView(timerState: timerState)
                                        .scaleEffect(smallWatch ?
                                                     CGSize(width: 1.1, height: 1.1) :
                                                     CGSize(width: 1, height: 1))
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: 10)
                                }
                            } else {
                                if settings.useProButtons && iapManager.canAccessFeatures(minimumTier: .pro) {
                                    ProButtonsView(timerState: timerState)
                                        .scaleEffect(smallWatch ?
                                                     CGSize(width: 1.1, height: 1.1) :
                                                     CGSize(width: 1, height: 1))
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: 5)
                                } else {
                                    ButtonsView(timerState: timerState)
                                        .scaleEffect(smallWatch ?
                                                     CGSize(width: 1.1, height: 1.1) :
                                                     CGSize(width: 1, height: 1))
                                        .padding(.bottom, -10)
                                        .background(OverlayPlayerForTimeRemove())
                                        .offset(y: 5)
                                }
                            }
                        }
                        .padding(.horizontal, 0)
                        .scaleEffect(smallWatch ?
                                     CGSize(width: 0.9, height: 0.9) :
                                     CGSize(width: 1, height: 1))
                        
                        // Show speed info if user has any subscription (Pro or Ultra)
                        if settings.showSpeedInfo && iapManager.canAccessFeatures(minimumTier: .pro) {
                            AltSpeedInfoView(
                                cruisePlanState: cruisePlanState,
                                showingWatchFace: $showingWatchFace,
                                locationManager: locationManager,
                                watchTimerState: timerState,
                                persistentTimer: persistentTimer,
                                startLineManager: startLineManager,
                                isCheckmark: $showStartLine
                            )
                            .offset(y: persistentTimer.isTimerRunning ? -35 : -66)
                            .offset(y: smallWatch ? 10 : 0)
                        }
                        
                        ZStack {
                            if showStartLine {
                                Rectangle()
                                    .fill(settings.lightMode ? Color.white : Color.black)
                                    .frame(height: 40)
                                    .frame(maxWidth: 108)
                                    .offset(x: timerState.isRunning ? 0 : 22.5, y: -90)
                                
                                StartLineView(
                                    locationManager: locationManager,
                                    startLineManager: startLineManager
                                )
                                .padding(.top, -10)
                                .offset(x: timerState.isRunning ? 0 : 22.5, y: -81)
                            }
                        }
                        .offset(y: smallWatch ? 10 : 0)
                    }
                    .onReceive(timer) { _ in
                        timerState.updateTimer()
                    }
                    .onChange(of: cruisePlanState.isActive) { oldValue, newValue in
                        print("🚢 Cruise plan state changed from \(oldValue) to \(newValue)")
                        // Force view update by changing the ID
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewUpdateTrigger = UUID()
                        }
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
        .environmentObject(WatchTimerState())
        .environmentObject(WatchCruisePlanState.shared) // Use the shared instance
}

