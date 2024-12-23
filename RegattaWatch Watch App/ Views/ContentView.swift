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
    return WKInterfaceDevice.current().name.contains("Ultra")
    #else
    return false
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
    @State private var refreshToggle = false  // Add at top with other state variables
    private let impactGenerator = WKHapticType.click

    @State private var viewID = UUID()
    @State private var lastTeamName = ""
    @State private var lastRaceInfoState = false
    
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
                    //.opacity(0.5)
                    .frame(width: 80, height: 40) // Adjust to match CurrentTimeView size
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
        .onAppear {
            lastTeamName = settings.teamName
            lastRaceInfoState = settings.showRaceInfo
        }
        
        .sheet(isPresented: $showSettings, onDismiss: {
            // Force view refresh
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
                     
//                     if iapManager.isPremiumUser {
                         showSettings = true
//                     } else {
//                         showPremiumAlert = true
//                     }
                 }
        )
    }
}

    
struct TimerView: View {
    @ObservedObject var timerState: WatchTimerState
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let centerY = geometry.size.height/2
                ZStack {
                
                    
                    // Progress bar and separators
                    WatchProgressBarView(timerState: timerState)
                    
                    // Content
                    VStack(spacing: 0) {
                        
                        CurrentTimeView(timerState: timerState)
                            .padding(.top, -10)
                            .offset(y:-10)
                                                
                        Spacer()
                            .frame(height: 0) // Space after current time
                                                
                        TimeDisplayView(timerState: timerState)
                            .frame(height: 150)  // Fixed height for picker
                            .position(x: geometry.size.width/2, y: centerY/2+10)
                        
                        Spacer()
                            .frame(height: 0) // Adjust this value to control space between picker and buttons
                        
                        if isUltraWatch {
                            ButtonsView(timerState: timerState)
                                .padding(.bottom, -10) // this control the position of the buttons to match numbers in timer and picker
                                .background(OverlayPlayerForTimeRemove())
                                .offset(y:5)
                        } else {
                            ButtonsView(timerState: timerState)
                                .padding(.bottom, -10) // this control the position of the buttons to match numbers in timer and picker
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


#Preview {
    ContentView()
        .environmentObject(ColorManager())
        .environmentObject(AppSettings())
}
