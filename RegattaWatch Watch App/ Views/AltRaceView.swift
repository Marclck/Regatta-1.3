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

    @Binding var showingWatchFace: Bool
    
    private var isSmallWatch: Bool {
        #if os(watchOS)
        return WKInterfaceDevice.current().screenBounds.height < 224
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
                        if settings.showCruiser && !showCruiseInfo {
                            Circle()
                                .fill(timerState.mode == .countdown && timerState.currentTime <= 60
                                      ? Color.orange.opacity(1)
                                      : Color(hex: colorManager.selectedTheme.rawValue).opacity(1))
                                .frame(width: 10, height: 10)
                                .offset(y:-35)
                        } else {
                            TimerDisplayAsCurrentTime(timerState: timerState)
                                .padding(.top, -10)
                                .offset(y: smallWatch ? -15 : -10)
                        }
                        
                        Spacer()
                            .frame(height: 10)
                        
                        if settings.showCruiser && showCruiseInfo {
                            
                            Spacer()
                                .frame(height: 30)
                            
                            HStack(spacing: 0) {
                                Text(hourString(from: currentTime))
                                    .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 42) : .zenithBeta(size: 38, weight: .medium)) //82?
                                    .dynamicTypeSize(.xSmall)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                                
                                Text(":")
                                    .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 42) : .zenithBeta(size: 38, weight: .medium)) //82?
                                    .dynamicTypeSize(.xSmall)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(x: settings.debugMode ? -2 : 0, y: settings.debugMode ? -50 : -53)
                                
                                
                                Text(minuteString(from: currentTime))
                                    .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 42) : .zenithBeta(size: 38, weight: .medium)) //82?
                                    .dynamicTypeSize(.xSmall)
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                            }
                            .font(.zenithBeta(size: 84, weight: .bold))
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+25)
                            .offset(y: smallWatch ? -5 : 0)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                            
                            HStack(spacing: 5) {
                                WindSpeedView(courseTracker: courseTracker, lastReadingManager: lastReadingManager)
                                CompassView(
                                    cruisePlanState: cruisePlanState,
                                    showingWatchFace: $showingWatchFace
                                )
                                BarometerView()
                            }
                            .offset(y:settings.ultraModel ? 15 : (isSmallWatch ? 20 : 10))

                        } else if settings.showCruiser && !showCruiseInfo {
                                // Show current time
                                VStack(spacing: -10) {
                                    HStack(spacing: 0) {
                                        // First digit position
                                        HStack(spacing: 0) {
                                            // Left half - Hour on top of Minute (vertically) - Center aligned, right masked
                                            ZStack {
                                                // Hour first digit - left half (on top vertically)
                                                Text(hourFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? 18 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))                                                    .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                        }
                                                    )
                                                    .offset(x:hourFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: settings.debugMode
                                                            ? -55 : -45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1", "4", "7"].contains(hourFirstDigit(from: currentTime)) ? 1 : 2)
                                                            : (2)) // Ensure hour is on top


                                                // Minute first digit - left half (on bottom vertically)
                                                Text(minuteFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? -37 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))
                                                    .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                        }
                                                    )
                                                    .offset(x:minuteFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: settings.debugMode ? 55 : 45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1", "4", "7"].contains(hourFirstDigit(from: currentTime)) ? 2 : 1)
                                                            : (1))
                                            }
                                            .offset(x:15)
                                            .frame(width: 30, height: 150)
                                            
                                            // Right half - Hour on top of Minute (vertically) - Center aligned, left masked
                                            ZStack {
                                                // Hour first digit - right half (on top vertically)
                                                Text(hourFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? 18 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))                                                       .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                        }
                                                    )
                                                    .offset(x:hourFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: settings.debugMode ? -55 : -45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1"].contains(minuteFirstDigit(from: currentTime)) ? 2 : 1)
                                                            : (["1", "4", "6"].contains(minuteFirstDigit(from: currentTime)) ? 2 : 1))

                                                // Minute first digit - right half (on bottom vertically)
                                                Text(minuteFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? -37 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))                                                      .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                        }
                                                    )
                                                    .offset(x:minuteFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: settings.debugMode ? 55 : 45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1"].contains(minuteFirstDigit(from: currentTime)) ? 1 : 2)
                                                            : (["1", "4", "6"].contains(minuteFirstDigit(from: currentTime)) ? 1 : 2))
                                            }
                                            .frame(width: 30, height: 150)
                                            .offset(x:-15)
                                        }
                                        
                                        // Second digit position
                                        HStack(spacing: 0) {
                                            // Left half - Hour on top of Minute (vertically) - Center aligned, right masked
                                            ZStack {
                                                // Hour second digit - left half (on top vertically)
                                                Text(hourSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? 18 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))
                                                    .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                        }
                                                    )
                                                    .offset(x:hourSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: settings.debugMode ? -55 : -45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1"].contains(hourSecondDigit(from: currentTime)) ? 2 : ["1"].contains(minuteSecondDigit(from: currentTime)) ? 1 : 2)
                                                            : (["1", "4", "7", "9"].contains(hourSecondDigit(from: currentTime)) ? 1 : 2))

                                                // Minute second digit - left half (on bottom vertically)
                                                Text(minuteSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? -37 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))                                                     .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                        }
                                                    )
                                                    .offset(x:minuteSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: settings.debugMode ? 55 : 45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1"].contains(hourSecondDigit(from: currentTime)) ? 1 :  ["1"].contains(minuteSecondDigit(from: currentTime)) ? 2 : 1)
                                                            : (["1", "4", "7", "9"].contains(hourSecondDigit(from: currentTime)) ? 2 : 1))
                                            }
                                            .offset(x: settings.debugMode ? 20 : 15)
                                            .frame(width: 30, height: 150)
                                            
                                            // Right half - Hour on top of Minute (vertically) - Center aligned, left masked
                                            ZStack {
                                                // Hour second digit - right half (on top vertically)
                                                Text(hourSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? 18 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))
                                                    .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                        }
                                                    )
                                                    .offset(x:hourSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: settings.debugMode ? -55 : -45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1"].contains(minuteSecondDigit(from: currentTime)) ? 2 : ["1", "4", "7"].contains(hourSecondDigit(from: currentTime)) ? 2 : 1)
                                                            : (["1", "4", "6"].contains(minuteSecondDigit(from: currentTime)) ? 2 : 1))

                                                // Minute second digit - right half (on bottom vertically)
                                                Text(minuteSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:0.9)
                                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .offset(y: settings.debugMode
                                                            ? (isLuminanceReduced ? -37 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))
                                                    .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .frame(height: 150, alignment: .center) // Wider frame, center alignment
                                                    .mask(
                                                        HStack(spacing: 0) {
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                                .opacity(0) // Transparent to create the mask
                                                            Rectangle()
                                                                .frame(width: 30, height: 150)
                                                        }
                                                    )
                                                    .offset(x:minuteSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: settings.debugMode ? 55 : 45)
                                                    .zIndex(settings.debugMode
                                                            ? (["1"].contains(minuteSecondDigit(from: currentTime)) ? 1 : ["1", "4", "7"].contains(hourSecondDigit(from: currentTime)) ? 1 : 2)
                                                            : (["1", "4", "6"].contains(minuteSecondDigit(from: currentTime)) ? 1 : 2))
                                            }
                                            .offset(x: settings.debugMode ? -10 : -15) //15 for zb
                                            .frame(width: 30, height: 60)
                                        }
                                    }
                                }
                                .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 100) : .zenithBeta(size: 84, weight: .medium)) //82?
                                .dynamicTypeSize(.xSmall)
                                .scaleEffect(settings.debugMode ?
                                            CGSize(width: 1, height: 1.1) :
                                            CGSize(width: 1.05, height: 1.43))
                                .foregroundColor(.white)
                                .frame(width: 150, height: 60)
                                .position(x: geometry.size.width/2, y: centerY/2+25)
                                .offset(y: settings.debugMode ? 0 : 5)
                                .onReceive(timeTimer) { input in
                                    currentTime = input
                                }
                                
                                /*
                                 // Show current time
                                 VStack(spacing: -10) {
                                 // Hour digits in HStack
                                 ZStack() {
                                 Text(hourFirstDigit(from: currentTime))
                                 .scaleEffect(x:1, y:0.9)
                                 .frame(alignment: .trailing)
                                 .foregroundColor(settings.lightMode ? .black : .white)
                                 .offset(x: hourFirstDigit(from: currentTime) == "1" ? -19 : -29)
                                 
                                 Text(hourSecondDigit(from: currentTime))
                                 .scaleEffect(x:1, y:0.9)
                                 .frame(alignment: .leading)
                                 .foregroundColor(settings.lightMode ? .black : .white)
                                 .offset(x: hourSecondDigit(from: currentTime) == "1" ? 19 : 29)
                                 }
                                 .offset(y:isLuminanceReduced ? 15 : 1)
                                 
                                 // Minute digits in HStack
                                 ZStack() {
                                 Text(minuteFirstDigit(from: currentTime))
                                 .scaleEffect(x:1, y:0.9)
                                 .frame(alignment: .trailing)
                                 .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                 .offset(x: minuteFirstDigit(from: currentTime) == "1" ? -19 : -29)
                                 
                                 Text(minuteSecondDigit(from: currentTime))
                                 .scaleEffect(x:1, y:0.9)
                                 .frame(alignment: .leading)
                                 .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                 .offset(x: minuteSecondDigit(from: currentTime) == "1" ? 19 : 29)
                                 }
                                 .offset(y:isLuminanceReduced ? -35 : -24)
                                 }
                                 .font(.zenithBeta(size: 84, weight: .medium))
                                 .scaleEffect(x:1, y:1.43)
                                 .foregroundColor(.white)
                                 .frame(width: 150, height: 60)
                                 .position(x: geometry.size.width/2, y: centerY/2+25)
                                 .offset(y:5)
                                 .onReceive(timeTimer) { input in
                                 currentTime = input
                                 }
                                 */
                            
                            } else {
                            // Show current time
                            VStack(spacing: -10) {
                                // Hour digits in HStack
                                ZStack() {
                                    Text(hourFirstDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .trailing)
                                        .foregroundColor(settings.lightMode ? .black : .white)
                                        .offset(x: hourFirstDigit(from: currentTime) == "1" ? -19 : -29)

                                    Text(hourSecondDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .leading)
                                        .foregroundColor(settings.lightMode ? .black : .white)
                                        .offset(x: hourSecondDigit(from: currentTime) == "1" ? 19 : 29)
                                }
                                .offset(y:isLuminanceReduced ? 6 : 4)
                                
                                // Minute digits in HStack
                                ZStack() {
                                    Text(minuteFirstDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .trailing)
                                        .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                        .offset(x: minuteFirstDigit(from: currentTime) == "1" ? -19 : -29)
                                        
                                    Text(minuteSecondDigit(from: currentTime))
                                        .scaleEffect(x:1, y:0.9)
                                        .frame(alignment: .leading)
                                        .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                        .offset(x: minuteSecondDigit(from: currentTime) == "1" ? 19 : 29)
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
                    .scaleEffect(isSmallWatch ?
                    CGSize(width: 0.9, height: 0.9)
                    : CGSize(width: 1, height: 1))
                    .padding(.horizontal, 0)
                        
                    
                    if settings.showCruiser && showCruiseInfo {
                        CruiseInfoView(
                            locationManager: locationManager
                        )
                        .transition(.opacity)
                        .offset(y: isSmallWatch ? -33 : -35)
                        .scaleEffect(isSmallWatch ?
                        CGSize(width: 0.9, height: 0.9)
                        : CGSize(width: 1, height: 1))
                    }

                    if settings.privacyOverlay {
                        PrivacyOverlayTwoView()
                            .offset(y:0)
                            .scaleEffect(isSmallWatch ?
                            CGSize(width: 0.9, height: 0.9)
                            : CGSize(width: 1, height: 1))
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
