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
        VideoPlayer(player: nil,videoOverlay: { })
        .focusable(false)
        .disabled(true)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ContentView: View {
    
    @State private var showSettings = false
    @State private var showPremiumAlert = false
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @StateObject private var iapManager = IAPManager.shared
    @StateObject private var locationManager = LocationManager()
    @State private var refreshToggle = false
    private let impactGenerator = WKHapticType.click

    @State private var viewID = UUID()
    @State private var lastTeamName = ""
    @State private var lastRaceInfoState = false
    @State private var lastSpeedInfoState = false
    
    @StateObject private var timerState = WatchTimerState()
    @State private var showingWatchFace = false
    
    var body: some View {
        ZStack {
            if showingWatchFace {
                if settings.showRaceInfo {
                    WatchFaceView(timerState: timerState)
                } else {
                    AltRaceView(timerState: timerState)
                }
            } else {
                TimerView(timerState: timerState)
            }
            
            // Toggle overlay
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
        .id(viewID) // Force entire view refresh
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
            printWatchModel()
        }
        
        .sheet(isPresented: $showSettings, onDismiss: {
            withAnimation {
                refreshToggle.toggle()
            }
        }) {
            SettingsView(showSettings: $showSettings)
        }
        .sheet(isPresented: $showPremiumAlert) {
            PremiumAlertView()
        }
        .gesture(
            LongPressGesture(minimumDuration: 1.0)
                .onEnded { _ in
                     WKInterfaceDevice.current().play(impactGenerator)
                     showSettings = true
                 }
        )
    }
}

struct TimerView: View {
    @ObservedObject var timerState: WatchTimerState
    @StateObject private var locationManager = LocationManager()
    @StateObject private var heartRateManager = HeartRateManager()
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                GeometryReader { geometry in
                    let centerY = geometry.size.height/2
                    ZStack {
                        // Progress bar and separators
                        WatchProgressBarView(timerState: timerState)
                        
                        // Content
                        VStack(spacing: 0) {
                            ZStack {
                                // Center the CurrentTimeView
                                CurrentTimeView(timerState: timerState)
                                    .padding(.top, -10)
                                    .offset(y: -10)
                                
                                if settings.showSpeedInfo {
                                    HStack {
                                        // Speed display layer
                                        HeartRateView(timerState: timerState)
                                            .padding(.top, -10)
                                            .offset(x: -5, y: -10)
                                        
                                        Spacer().frame(width: 70)
                                        
                                        // Speed display layer
                                        SpeedDisplayView(locationManager: locationManager,
                                                         timerState: timerState)
                                            .padding(.top, -10)
                                            .offset(x: 5, y: -10)
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            Spacer()
                                .frame(height: 0)
                            
                            TimeDisplayView(timerState: timerState)
                                .frame(height: 150)
                                .position(x: geometry.size.width/2, y: centerY/2+10)
                            
                            Spacer()
                                .frame(height: 0)
                            
                            if isUltraWatch {
                                ButtonsView(timerState: timerState)
                                    .padding(.bottom, -10)
                                    .background(OverlayPlayerForTimeRemove())
                                    .offset(y:5)
                            } else {
                                ButtonsView(timerState: timerState)
                                    .padding(.bottom, -10)
                                    .background(OverlayPlayerForTimeRemove())
                                    .offset(y:0)
                            }
                        }
                        .padding(.horizontal, 0)
                    }
                    .onReceive(timer) { _ in
                        timerState.updateTimer()
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
