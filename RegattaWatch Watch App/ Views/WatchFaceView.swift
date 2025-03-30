//
//  WatchFaceView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 01/12/2024.
//

import Foundation
import SwiftUI
import WatchKit

struct WatchFaceView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    @StateObject private var locationManager = LocationManager()
    @StateObject private var courseTracker = CourseTracker()  // Add CourseTracker
    @StateObject private var lastReadingManager = LastReadingManager()  // Add LastReadingManager
    @Binding var showingWatchFace: Bool

    @ObservedObject var timerState: WatchTimerState
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var currentTime = Date()
    let timeTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @ObservedObject var cruisePlanState: WatchCruisePlanState

    @State private var showCruiseInfo = true
    
    private var isUltraWatch: Bool {
        #if os(watchOS)
        return WKInterfaceDevice.current().name.contains("Ultra")
        #else
        return false
        #endif
    }
    
    var body: some View {
        ZStack {
            if settings.lightMode {
                 Color.white.edgesIgnoringSafeArea(.all)
             } else {
                 Color.black.edgesIgnoringSafeArea(.all)
             }
            
            GeometryReader { geometry in
                let centerY = geometry.size.height/2
                ZStack {
                    // Progress bar showing seconds
                    if cruisePlanState.isActive {
                        WaypointProgressBarView(
                            plannerManager: WatchPlannerDataManager.shared,
                            locationManager: locationManager
                        )
                    } else {
                        // Progress bar showing seconds
                        SecondProgressBarView()
                        
                        Text(settings.teamName)
                            .font(.system(size: 11, weight: .semibold))
                            .rotationEffect(.degrees(270), anchor: .center)
                            .foregroundColor(Color(hex: settings.teamNameColorHex).opacity(1))
                            .position(x: 4, y: centerY/2+55)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                    }
                    
                    // Content
                    VStack(spacing: 0) {
                        // Timer display instead of current time
                        TimerDisplayAsCurrentTime(timerState: timerState)
                            .padding(.top, -10)
                            .offset(y:-10)
                        
                        Spacer()
                            .frame(height: 10)
                        
                        if settings.showCruiser && showCruiseInfo {
                            Spacer()
                                .frame(height: 30)
                            
                            HStack(spacing: 0) {
                                Text(hourString(from: currentTime))
                                    .font(.zenithBeta(size: 38))
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                                
                                Text(":")
                                    .font(.zenithBeta(size: 38))
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-53)
                                
                                Text(minuteString(from: currentTime))
                                    .font(.zenithBeta(size: 38))
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                            }
                            .font(.zenithBeta(size: 84, weight: .medium))
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+25)
                            .scaleEffect(x:1.4, y:1.1)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                            
                            HStack(spacing: 5) {
                                WindSpeedView(
                                    courseTracker: courseTracker,
                                    lastReadingManager: lastReadingManager)
                                CompassView(
                                    cruisePlanState: cruisePlanState,
                                    showingWatchFace: $showingWatchFace
                                )
                                BarometerView()
                            }
                            .offset(y:settings.ultraModel ? 15 : 10)

                        } else {
                            // Show current time
                            VStack(spacing: -10) {
                                Text(hourString(from: currentTime))
                                    .scaleEffect(x:1, y:1)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:isLuminanceReduced ? 17 : 8)
                                
                                Text(minuteString(from: currentTime))
                                    .scaleEffect(x:1, y:1)
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                    .offset(y:isLuminanceReduced ? -26 : -14)
                            }
                            .font(.zenithBeta(size: 80, weight: .medium))
                            .scaleEffect(x:1, y:1.1)
                            .foregroundColor(.white)
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+10)
                            .offset(y:7)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                            
                            Spacer()
                                .frame(height: 20)
                            
                            VStack(alignment: .center, spacing: 1) {
                                if isUltraWatch {
                                    Text(dateString(from: Date()))
                                        .font(.system(size:14))
                                        .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))
                                }

                                if isUltraWatch {
                                    Text("Race \(JournalManager.shared.allSessions.count)")
                                        .font(.system(size: 14))
                                        .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))
                                } else {
                                    Text("Race \(JournalManager.shared.allSessions.count)")
                                        .offset(y:-10)
                                        .font(.system(size: 14))
                                        .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))
                                }
                            }
                            .frame(width: 180, height: 40)
                            .padding(.bottom, 0)
                            .offset(y:28)
                        }
                    }
                    .padding(.horizontal, 0)
                    
                    if settings.showCruiser && showCruiseInfo {
                        CruiseInfoView(
                            locationManager: locationManager
                        )
                        .transition(.opacity)
                        .offset(y:-35)
                    }
                    
                    // Tappable area for cruise info
                    GeometryReader { proxy in
                        Color.clear
                            .frame(
                                width: geometry.size.width - 30,
                                height: (settings.showCruiser && showCruiseInfo) ? 70 : 160
                            )
                            .contentShape(Rectangle())
                            .position(x: geometry.size.width/2, y: geometry.size.height/2+5)
                            .onTapGesture {
                                if settings.showCruiser {  // Only allow toggling if feature is enabled
                                    WKInterfaceDevice.current().play(.click)
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showCruiseInfo.toggle()
                                    }
                                }
                            }
                    }
                }
                .onReceive(timer) { _ in
                    timerState.updateTimer()
                }
                .onAppear {
                    // Pass in the timerState but let the manager decide if a new session is needed
//                    ExtendedSessionManager.shared.startSession(timerState: timerState)
//                    print("⌚️ View: Ensured extended runtime session is active")
                }
                .onDisappear {
                    // Original cleanup
                    timer.upstream.connect().cancel()
                    timeTimer.upstream.connect().cancel()
                    
//                    ExtendedSessionManager.shared.startSession(timerState: timerState)
//                    print("⌚️ View: Ensured extended runtime session is active")
                }
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
            timeTimer.upstream.connect().cancel()
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM dd"
        return formatter.string(from: date).uppercased()
    }
    
    private var formattedLastFinishTime: String {
        let lastFinishTime = "00:00"
        return lastFinishTime
    }
    
    private func hourString(from date: Date) -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "HH"
       return formatter.string(from: date)
    }

    private func minuteString(from date: Date) -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "mm"
       return formatter.string(from: date)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environment(\.isLuminanceReduced, true)
                .environmentObject(ColorManager())
                .environmentObject(AppSettings())
            ContentView()
                .environment(\.isLuminanceReduced, false)
                .environmentObject(ColorManager())
                .environmentObject(AppSettings())
        }
    }
}
