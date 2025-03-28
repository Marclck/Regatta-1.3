//
//  AltRaceView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 06/12/2024.
//

import Foundation
import SwiftUI
import WatchKit

struct AltRaceView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    @StateObject private var locationManager = LocationManager()
    @StateObject private var courseTracker = CourseTracker()  // Add CourseTracker
    @StateObject private var lastReadingManager = LastReadingManager()  // Add LastReadingManager

    @ObservedObject var timerState: WatchTimerState
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var currentTime = Date()
    let timeTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State private var showCruiseInfo = true
    @EnvironmentObject var cruisePlanState: WatchCruisePlanState

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
                    
                    if cruisePlanState.isActive {
                        WaypointProgressBarView(
                            plannerManager: WatchPlannerDataManager.shared,
                            locationManager: locationManager
                        )
                    } else {
                        // Progress bar showing seconds
                        SecondProgressBarView()
                        
                        if !cruisePlanState.isActive {
                            Text(settings.teamName)
                                .font(.system(size: 11, weight: .semibold))
                                .rotationEffect(.degrees(270), anchor: .center)
                                .foregroundColor(Color(hex: settings.teamNameColorHex).opacity(1))
                                .position(x: 4, y: centerY/2+55)
                                .onReceive(timeTimer) { input in
                                    currentTime = input
                                }
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
                                    .font(.zenithBeta(size: 38, weight: .medium))
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                                
                                Text(":")
                                    .font(.zenithBeta(size: 38, weight: .medium))
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-53)

                                
                                Text(minuteString(from: currentTime))
                                    .font(.zenithBeta(size: 38, weight: .medium))
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                            }
                            .font(.zenithBeta(size: 84, weight: .bold))
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+25)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                            
                            HStack(spacing: 5) {
                                WindSpeedView(courseTracker: courseTracker, lastReadingManager: lastReadingManager)
                                CompassView(cruisePlanState: cruisePlanState)
                                BarometerView()
                            }
                            .offset(y:settings.ultraModel ? 15 : 10)
                            
                        } else {
                            // Show current time
                            VStack(spacing: -10) {
                                // Hour digits in HStack
                                ZStack() {
                                    Text(hourFirstDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .trailing)
                                        .foregroundColor(settings.lightMode ? .black : .white)
                                        .offset(x: hourFirstDigit(from: currentTime) == "1" ? -20 : -30)

                                    Text(hourSecondDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .leading)
                                        .foregroundColor(settings.lightMode ? .black : .white)
                                        .offset(x: hourSecondDigit(from: currentTime) == "1" ? 20 : 30)
                                }
                                .offset(y:isLuminanceReduced ? 6 : 4)
                                
                                // Minute digits in HStack
                                ZStack() {
                                    Text(minuteFirstDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .trailing)
                                        .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                        .offset(x: minuteFirstDigit(from: currentTime) == "1" ? -20 : -30)
                                        
                                    Text(minuteSecondDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .leading)
                                        .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                        .offset(x: minuteSecondDigit(from: currentTime) == "1" ? 20 : 30)
                                }
                                .offset(y:isLuminanceReduced ? -40 : -24)
                            }
                            .font(.zenithBeta(size: 84, weight: .medium))
                            .scaleEffect(x:1, y:1.3)
                            .foregroundColor(.white)
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+25)
                            .offset(y:12)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
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
//                            .border(Color.green.opacity(0.3), width: 1)
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
            }
        }
        .onAppear {
            // Pass in the timerState but let the manager decide if a new session is needed
//            ExtendedSessionManager.shared.startSession(timerState: timerState)
//            print("⌚️ View: Ensured extended runtime session is active")
        }
        .onDisappear {
            // Original cleanup
            timer.upstream.connect().cancel()
            timeTimer.upstream.connect().cancel()
            
//            ExtendedSessionManager.shared.startSession(timerState: timerState)
//            print("⌚️ View: Ensured extended runtime session is active")
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd"
        return formatter.string(from: date).uppercased()
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
    
    private func hourFirstDigit(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH" // Always use 2-digit format
        let hourString = formatter.string(from: date)
        return String(hourString.prefix(1))
    }

    private func hourSecondDigit(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH" // Always use 2-digit format
        let hourString = formatter.string(from: date)
        return String(hourString.suffix(1))
    }

    private func minuteFirstDigit(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm" // Always use 2-digit format
        let minuteString = formatter.string(from: date)
        return String(minuteString.prefix(1))
    }

    private func minuteSecondDigit(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm" // Always use 2-digit format
        let minuteString = formatter.string(from: date)
        return String(minuteString.suffix(1))
    }
}

struct ContentView_Previews2: PreviewProvider {
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
