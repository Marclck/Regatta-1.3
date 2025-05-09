//
//  ContentView.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @EnvironmentObject var colorManager: ColorManager
    @AppStorage("lastVersionSeen") private var lastVersionSeen: String = ""
    @State private var showingUpdateModal = false
    // Add a state to trigger view refresh
    @State private var themeRefreshTrigger = UUID()
    
    private let currentVersion = "1.4"

    var body: some View {
        TabView {
            JournalView()
                .environmentObject(colorManager)
                .tabItem {
                    Label("Journal", systemImage: "book.closed.circle.fill")
                }

            PlannerView()
                .environmentObject(colorManager)
                .tabItem {
                    Label("Planner", systemImage: "mappin.circle.fill")
                }
            
            MainInfoView()
                .environmentObject(colorManager)
                .tabItem {
                    Label("Info", systemImage: "timer.circle.fill")
                }
            
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            if lastVersionSeen != currentVersion {
                showingUpdateModal = true
            }
            
            // Set up notification observer for theme updates
            NotificationCenter.default.addObserver(
                forName: Notification.Name("ThemeUpdatedFromWatch"),
                object: nil,
                queue: .main
            ) { _ in
                // Force view refresh by changing the UUID
                self.themeRefreshTrigger = UUID()
            }
        }
        .id(themeRefreshTrigger) // This causes the view to redraw when themeRefreshTrigger changes
        .sheet(isPresented: $showingUpdateModal) {
            NavigationView {
                ScrollView {
                    VersionUpdatePopup()
                }
                .navigationTitle("What's New")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingUpdateModal = false
                            lastVersionSeen = currentVersion
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
        }
    }
}

struct VersionUpdatePopup: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Version 1.4")
                    .font(.system(size: 16, weight: .bold))
                
                
                Text("One-time Full ULTRA Access Option N ow Available \nUsers can now access watch app for free")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Introducing ULTRA features")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                
                Image("covershot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CruiseR")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
                        
                        FeatureRow(icon: "mappin", text: "Route planning and waypoint tracking - access through compass button")
                        FeatureRow(icon: "gauge.with.needle", text: "Speed Tracking: SOG display with GPS toggle for precise speed monitoring")
                        FeatureRow(icon: "wind", text: "Wind Analysis: Real-time wind speed and directional indicators with compass bearing")
                        FeatureRow(icon: "location.north.line", text: "Course Monitor: Deviation tracking with North reference and 10° indicators")
                        FeatureRow(icon: "thermometer.medium", text: "Weather Station: Integrated weather data and barometric pressure readings")
                        FeatureRow(icon: "point.topleft.down.curvedto.point.bottomright.up", text: "Journey Stats: Distance traveled with continuous tracking")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ProControl")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
                        
                        FeatureRow(icon: "bolt", text: "QuickStart: start a 5-min countdown immediately upon gun signal")
                        FeatureRow(icon: "bolt.ring.closed", text: "GunSync: countdown rounded up or down to closest minute")
                        FeatureRow(icon: "arrow.counterclockwise", text: "Restart: restart the stopwatch after two taps")
                        FeatureRow(icon: "timelapse", text: "Timelapse: double tap timer to change countdown minutes")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
                        
                        FeatureRow(icon: "square.fill.and.line.vertical.and.square.fill", text: "Distance to Startline using dual band GPS")
                        FeatureRow(icon: "dots.and.line.vertical.and.cursorarrow.rectangle", text: "Shift Tracking within 30 degrees")
                        FeatureRow(icon: "gauge.open.with.lines.needle.33percent", text: "Speedometer in knots")
                    }
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.05))
        .cornerRadius(12)
        .padding()
    }
}

private var versionHistorySection: some View {
    NavigationLink(destination: VersionHistoryView(isModal: false)) {
        HStack {
            Image(systemName: "clock.arrow.circlepath").foregroundColor(.white)
            Text("Version History")
                                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
        }
    }
}

struct MainInfoView: View {
    @StateObject private var timerState = TimerState()
    @ObservedObject private var iapManager = IAPManager.shared
    @EnvironmentObject var colorManager: ColorManager
    @State private var showingWatchSettings = false
    @State private var showingSpeedTools = false
    @State private var showingCruiser = false

    private let privacyPolicyURL = URL(string: "https://astrolabe-countdown.apphq.online/privacy")!
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    private var subscriptionStatusText: String {
        if iapManager.currentTier == .ultra {
            return "ULTRA Plan Active"
        } else if iapManager.currentTier == .pro {
            return "PRO Plan Active"
        } else if iapManager.isInTrialPeriod {
            return "7-day free trial active.\nUpgrade to PRO or ULTRA for full access."
        } else {
            return "7-day free trial available.\nPRO and ULTRA plans available."
        }
    }
    
    private var subscriptionIcon: String {
        switch iapManager.currentTier {
        case .ultra:
            return "sailboat.circle.fill"
        case .pro:
            return "star.circle.fill"
        case .none:
            return "star.circle.fill"
        }
    }
    
    private var subscriptionColor: Color {
        switch iapManager.currentTier {
        case .ultra:
            return .orange
        case .pro:
            return .yellow
        case .none:
            return .yellow
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background - matches JournalView
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: colorManager.selectedTheme.rawValue), location: 0.0),
                        .init(color: Color.black, location: 0.3),
                        .init(color: Color.black, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Feature Access Section (Sticky)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Feature Access")
                            .font(.system(.headline))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        NavigationLink(destination: SubscriptionView()) {
                            HStack {
                                VStack(alignment: .leading) {
                                    if iapManager.currentTier == .ultra {
                                        HStack{
                                            Text("ULTRA")
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                                                .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                                                .cornerRadius(8)
                                            
                                            
                                            Text("Features").foregroundColor(.white)
                                        }
                                        .font(.system(.body, weight: .bold))
                                        
                                    } else {
                                        HStack{
                                            Text("ULTRA")
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                                                .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                                                .cornerRadius(8)
                                            
                                            Text("&").foregroundColor(.white)
                                            
                                            Text("PRO")
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                                                .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.2))
                                                .cornerRadius(8)
                                            
                                            
                                            Text("Features").foregroundColor(.white)
                                        }
                                        .font(.system(.body, weight: .bold))
                                    }
                                    
                                    Text(subscriptionStatusText)
                                        .font(.system(.body, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    if iapManager.isInTrialPeriod {
                                        Text(iapManager.formatTimeRemaining())
                                            .font(.system(.body, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                }
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .environment(\.colorScheme, .dark)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 4)
                        }
                    }
                    .materialBackground()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Remaining content in scrollable list
                    List {
                        Section(header: Text("Long Press on Watch Screen to Access Settings Menu").foregroundColor(.white)) {
                            advancedSettingsSection
                        }
                        .listSectionSeparator(.hidden)
                        
                        Section(header: Text("What is Astrolabe?").foregroundColor(.white)) {
                            HStack {
                                Image(systemName: "sailboat.fill")
                                Text("Race countdown timer & sailing stopwatch")
                            }
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "timer.circle.fill")
                                Text("Set countdown from 1-30 minutes for race start sequence")
                            }
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "stopwatch.fill")
                                Text("Auto-transitions to stopwatch at zero for race timing")
                            }
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "applewatch")
                                Text("Optimized for Apple Watch Ultra with Ultra-exclusive features")
                            }
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                        }
                        .listRowBackground(Color.clear.background(.ultraThinMaterial))
                        .environment(\.colorScheme, .dark)
                        .listSectionSeparator(.hidden)
                        
                        Section(header: Text("Basic Info").foregroundColor(.white)) {
                            basicInfoSection
                        }
                        .listRowBackground(Color.clear.background(.ultraThinMaterial))
                        .environment(\.colorScheme, .dark)
                        .listSectionSeparator(.hidden)
                        
                        
                        Section(header: Text("Features").foregroundColor(.white)) {
                            featuresSection
                        }
                        .listRowBackground(Color.clear.background(.ultraThinMaterial))
                        .environment(\.colorScheme, .dark)
                        .listSectionSeparator(.hidden)
                        
                        Section(header: Text("").foregroundColor(.white)) {
                            versionHistorySection
                            
                            footerSection
                        }
                        .listRowBackground(Color.clear.background(.ultraThinMaterial))
                        .environment(\.colorScheme, .dark)
                        .listSectionSeparator(.hidden)
                    }
                    .scrollContentBackground(.hidden) // Hide default list background
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("About")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("StartCountdownFromShortcut"),
                object: nil,
                queue: .main) { notification in
                    if let minutes = notification.userInfo?["minutes"] as? Int {
                        timerState.startFromShortcut(minutes: minutes)
                    }
                }
        }
    }
    
    private var basicInfoSection: some View {
        Group {
            ForEach(1...9, id: \.self) { number in
                HStack {
                    Image(systemName: "\(number).circle.fill")
                    Text(getBasicInfoText(number))
                }
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
            }
        }
    }
    
    private var advancedSettingsSection: some View {
        Group {
            
            Button(action: { showingSpeedTools = true }) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    Text("ProControl & Dashboard")
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    
                    Text("ULTRA")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                        .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showingSpeedTools) {
                SpeedToolInfo()
            }
            .listRowBackground(Color.clear.background(.ultraThinMaterial))
            .environment(\.colorScheme, .dark)
            
            Button(action: { showingCruiser = true }) {
                HStack {
                    Image(systemName: "location.north.line")
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                        .scaleEffect(x:1.1)
                    
                    Text(" CruiseR")
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    
                    Text("ULTRA")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                        .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showingCruiser) {
                CruiseRInfoView()
            }
            .listRowBackground(Color.clear.background(.ultraThinMaterial))
            .environment(\.colorScheme, .dark)
            
            Button(action: { showingWatchSettings = true }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Watch Settings Guide")
                        .font(.system(.body, weight: .bold))
                    
                    Text("PRO")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.2))
                        .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                        .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showingWatchSettings) {
                WatchSettingsInfo()
            }
            .listRowBackground(Color.clear.background(.ultraThinMaterial))
            .environment(\.colorScheme, .dark)
        }
    }
    
    private var featuresSection: some View {
        Group {
            HStack {
                Image(systemName: "bell.fill")
                Text("Haptic feedback at key moments")
            }
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.white)
            
            HStack {
                Image(systemName: "clock.fill")
                Text("Runs in background with notifications")
            }
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.white)
            
            HStack {
                Image(systemName: "book.closed.fill")
                Text("Race history stored in Journal")
            }
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.white)
        }
    }
    
    private var footerSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("made for sailing enthusiasts")
                .font(.system(.subheadline, design: .monospaced))
                .italic()
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 15) {
                Link("Privacy Policy", destination: privacyPolicyURL)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                
                Link("Terms of Use", destination: termsOfUseURL)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
    
    private func getBasicInfoText(_ number: Int) -> String {
        switch number {
        case 1: return "Open the Watch app"
        case 2: return "Set countdown duration (0-30 minutes)"
        case 3: return "Start the countdown"
        case 4: return "Countdown automatically transitions to stopwatch at zero"
        case 5: return "Stop the timer to record your race; session stopped before stopwatch started will not be recorded"
        case 6: return "Add complication to your watch face for quick timer access"
        case 7: return "Long press your Apple Watch screen for customization options"
        case 8: return "Check race information by tapping the current time on the watch screen"
        case 9: return "Set Return to Clock to 1 hour in your Watch Settings app"
        default: return ""
        }
    }
}
