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
    
    private let currentVersion = "1.3"

    var body: some View {
        TabView {
            JournalView()
                .environmentObject(colorManager)
                .tabItem {
                    Label("Journal", systemImage: "book.closed.circle.fill")
                }

            MainInfoView()
                .environmentObject(colorManager)
                .tabItem {
                    Label("Info", systemImage: "timer.circle.fill")
                }
        }
        .onAppear {
            if lastVersionSeen != currentVersion {
                showingUpdateModal = true
            }
        }
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
        }
    }
}

struct VersionUpdatePopup: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Version 1.3")
                    .font(.system(size: 16, weight: .bold))
                
                
                Text("Users can now access watch app for free")
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
            Image(systemName: "clock.arrow.circlepath")
            Text("Version History")
                .font(.system(.body, design: .monospaced))
        }
    }
}

struct MainInfoView: View {
    @StateObject private var timerState = TimerState()
    @ObservedObject private var iapManager = IAPManager.shared
    @State private var showingWatchSettings = false
    @State private var showingSpeedTools = false
    
    private let privacyPolicyURL = URL(string: "https://astrolabe-countdown.apphq.online/privacy")!
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    private var subscriptionStatusText: String {
        if iapManager.currentTier == .ultra {
            return "Ultra Plan Active"
        } else if iapManager.currentTier == .pro {
            return "Pro Plan Active"
        } else if iapManager.isInTrialPeriod {
            return "7-day free trial active.\nUpgrade to Pro or Ultra for full access."
        } else {
            return "7-day free trial available.\nPro and Ultra plans available."
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
            List {
                Section("App Access") {
                    NavigationLink(destination: SubscriptionView()) {
                        HStack {
                            Image(systemName: subscriptionIcon)
                                .foregroundColor(subscriptionColor)
                            VStack(alignment: .leading) {
                                if iapManager.currentTier == .ultra {
                                    Text("Ultra subscription")
                                        .font(.system(.body, design: .monospaced, weight: .bold))
                                        .foregroundColor(.orange)
                                } else {
                                    Text("Pro & Ultra subscription")
                                        .font(.system(.body, design: .monospaced, weight: .bold))
                                        .foregroundColor(.cyan)
                                }
                                
                                Text(subscriptionStatusText)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                if iapManager.isInTrialPeriod {
                                    Text(iapManager.formatTimeRemaining())
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                
                Section("What is Astrolabe?") {
                    HStack {
                        Image(systemName: "sailboat.fill")
                        Text("Race countdown timer & sailing stopwatch")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "timer.circle.fill")
                        Text("Set countdown from 1-30 minutes for race start sequence")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "stopwatch.fill")
                        Text("Auto-transitions to stopwatch at zero for race timing")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "applewatch")
                        Text("Optimized for Apple Watch Ultra with Ultra-exclusive features")
                    }
                    .font(.system(.body, design: .monospaced))
                }
                
                Section("Basic Info") {
                    basicInfoSection
                }
                
                Section("Advanced Settings") {
                    advancedSettingsSection
                }
                
                Section("Features") {
                    featuresSection
                }
                
                Section() {
                    versionHistorySection
                    
                    footerSection
                }
            }
            .navigationTitle("About")
        }
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
            }
        }
    }
    
    private var advancedSettingsSection: some View {
        Group {
            Button(action: { showingWatchSettings = true }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Watch Settings Guide")
                        .font(.system(.body, design: .monospaced))
                }
            }
            .sheet(isPresented: $showingWatchSettings) {
                WatchSettingsInfo()
            }
            
            Button(action: { showingSpeedTools = true }) {
                HStack {
                    Image(systemName: "speedometer")
                    Text("Speed Tools Guide")
                        .font(.system(.body, design: .monospaced))
                }
            }
            .sheet(isPresented: $showingSpeedTools) {
                SpeedToolInfo()
            }
        }
    }
    
    private var featuresSection: some View {
        Group {
            HStack {
                Image(systemName: "bell.fill")
                Text("Haptic feedback at key moments")
            }
            .font(.system(.body, design: .monospaced))
            
            HStack {
                Image(systemName: "clock.fill")
                Text("Runs in background with notifications")
            }
            .font(.system(.body, design: .monospaced))
            
            HStack {
                Image(systemName: "book.closed.fill")
                Text("Race history stored in Journal")
            }
            .font(.system(.body, design: .monospaced))
        }
    }
    
    private var footerSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("made for sailing enthusiasts")
                .font(.system(.subheadline, design: .monospaced))
                .italic()
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                Link("Privacy Policy", destination: privacyPolicyURL)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Link("Terms of Use", destination: termsOfUseURL)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
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

#Preview {
    MainInfoView()
}

#Preview {
    ContentView()
        .environmentObject(ColorManager())
}

//struct ContentView: View {
//    @StateObject private var timerState = TimerState()
  //  @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    //var body: some View {
      //  ZStack {
        //    Color.black.edgesIgnoringSafeArea(.all)
            
            // Progress Bar
          //  ProgressBarView(timerState: timerState)
            
            // Main Content
            //VStack(spacing: 20) {
              //  CurrentTimeView()
                //    .padding(.top, 60)
                
                //Spacer()
                
                //TimeDisplayView(timerState: timerState)
                
               // Spacer()
                
               // ButtonsView(timerState: timerState)
                 //   .padding(.bottom, 80)
            //}
            //.padding(.horizontal)
        //}
        //.onReceive(timer) { _ in
          //  timerState.updateTimer()
        //}
    //}
//}
