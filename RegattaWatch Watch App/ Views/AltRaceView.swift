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
    @State private var colorLuminanceReduced: Bool = false
    @StateObject private var fontManager = CustomFontManager.shared
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
    
    @State private var showCruiseInfo = true //this triggers show time
    @EnvironmentObject var cruisePlanState: WatchCruisePlanState
    @State private var hasInitializedShowCruiseInfo = false

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
/*
                        if !cruisePlanState.isActive {
                            Text(settings.teamName)
//                                .font(settings.debugMode ? Font.custom("MemphisLTCYR-Bold", size: 11) : .system(size: 11, weight: .semibold))
                                .font(settings.teamNameFont == "Default" ? .system(size: 9, weight: .semibold) :                                      Font.customFont(fontManager.customFonts.first(where: { $0.id.uuidString == settings.teamNameFont }) ?? fontManager.customFonts.first!, size: 9) ?? .system(size: 9, weight: .semibold))
                                .rotationEffect(.degrees(270), anchor: .center)
                                .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue).opacity(1))
//                                .foregroundColor(Color(hex: settings.teamNameColorHex).opacity(1))
                                .position(x: settings.teamNameFont == "Default" ? 4 : 5, y: centerY/2+55)
                                .onReceive(timeTimer) { input in
                                    currentTime = input
                                }
                        }
*/
                    }
                    
                    // Content
                    VStack(spacing: 0) {
                        // Timer display instead of current time
                        if settings.showCruiser && showCruiseInfo {
                            TimerDisplayAsCurrentTime(timerState: timerState)
                                .padding(.top, -10)
                                .offset(y: smallWatch ? -15 : -10)
                        } else {
                            Circle()
                                .fill(timerState.mode == .countdown && timerState.currentTime <= 60
                                      ? Color.orange.opacity(1)
                                      : Color(hex: colorManager.selectedTheme.rawValue).opacity(1))
//                                .glassEffect(in: .circle)
//                                .colorScheme(.light)
                                .frame(width: 10, height: 10)
                                .offset(y:-35)
                        }
                        
                        Spacer()
                            .frame(height: 10)
                        
                        if settings.showCruiser && showCruiseInfo {
                            
                            Spacer()
                                .frame(height: 30)
                            
                            HStack(spacing: 2) {
                                Text(hourString(from: currentTime))
                                    .font(settings.timeFont == "Default" ?
                                          .zenithBeta(size: 38, weight: .medium) :
                                          (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 36 + CGFloat(settings.fontSize)) } ?? .zenithBeta(size: 38, weight: .medium)))
                                    .dynamicTypeSize(.xSmall)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                                    .offset(y:CGFloat(settings.fontSize)/4) //offset for font size
                                
                                VStack(spacing: 10) {
                                    Circle()
                                        .fill(settings.lightMode ? Color.black : Color.white)
                                        .frame(width: 6, height: 6)
                                    Circle()
                                        .fill(settings.lightMode ? Color.black : Color.white)
                                        .frame(width: 6, height: 6)
                                }
                                .offset(x:-0.5, y:-49)
                                
                                Text(minuteString(from: currentTime))
                                    .font(settings.timeFont == "Default" ?
                                          .zenithBeta(size: 38, weight: .medium) :
                                          (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 36 + CGFloat(settings.fontSize)) } ?? .zenithBeta(size: 38, weight: .medium)))
                                    .dynamicTypeSize(.xSmall)
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                    .offset(x:2, y:-48.5)
                                    .offset(y:CGFloat(settings.fontSize)/4) //offset for font size
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

                        } else { //if settings.showCruiser && !showCruiseInfo {
                                // Show current time
                                VStack(spacing: -10) {
                                    HStack(spacing: !(settings.timeFont == "Default") ? -2 + CGFloat(settings.fontSize) : 2) {
                                        // First digit position
                                        HStack(spacing: 0) {
                                            // Left half - Hour on top of Minute (vertically) - Center aligned, right masked
                                            ZStack {
                                                // Hour first digit - left half (on top vertically)
                                                Text(hourFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(settings.lightMode ? .black : .white)
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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? 20 + CGFloat(settings.fontSize) / 2 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))
                                                    .offset(x:hourFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? -55 : -45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1", "4", "7"].contains(hourFirstDigit(from: currentTime)) ? 1 : 2)
                                                            : (2)) // Ensure hour is on top


                                                // Minute first digit - left half (on bottom vertically)
                                                Text(minuteFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(colorLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .animation(.easeInOut(duration: 0.1), value: colorLuminanceReduced)
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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? -40 - CGFloat(settings.fontSize) / 2 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))
                                                    .offset(x:minuteFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default") ? 60 : 45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1", "4", "7"].contains(hourFirstDigit(from: currentTime)) ? 2 : 1)
                                                            : (1))
                                            }
                                            .offset(x:20)
                                            .frame(width: 30, height: 150)
                                            
                                            // Right half - Hour on top of Minute (vertically) - Center aligned, left masked
                                            ZStack {
                                                // Hour first digit - right half (on top vertically)
                                                Text(hourFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(settings.lightMode ? .black : .white)
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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? 20 + CGFloat(settings.fontSize) / 2 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))
                                                    .offset(x:hourFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default") ? -55 : -45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1"].contains(minuteFirstDigit(from: currentTime)) ? 1 : 1)
                                                            : (["1", "4", "6"].contains(minuteFirstDigit(from: currentTime)) ? 2 : 1))

                                                // Minute first digit - right half (on bottom vertically)
                                                Text(minuteFirstDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(colorLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .animation(.easeInOut(duration: 0.1), value: colorLuminanceReduced)
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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? -40 - CGFloat(settings.fontSize) / 2 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))
                                                    .offset(x:minuteFirstDigit(from: currentTime) == "1" ? 10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default") ? 60 : 45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1"].contains(minuteFirstDigit(from: currentTime)) ? 2 : 2)
                                                            : (["1", "4", "6"].contains(minuteFirstDigit(from: currentTime)) ? 1 : 2))
                                            }
                                            .frame(width: 30, height: 150)
                                            .offset(x:-10)
                                        }
                                        
                                        // Second digit position
                                        HStack(spacing: 0) {
                                            // Left half - Hour on top of Minute (vertically) - Center aligned, right masked
                                            ZStack {
                                                // Hour second digit - left half (on top vertically)
                                                //Text("5")
                                                Text(hourSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(settings.lightMode ? .black : .white)
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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? 20 + CGFloat(settings.fontSize) / 2 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))
                                                    .offset(x:hourSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default") ? -55 : -45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1", "7"].contains(hourSecondDigit(from: currentTime)) ? 2 : ["1", "7"].contains(minuteSecondDigit(from: currentTime)) ? 1 : 2)
                                                            : (["1", "4", "7", "9"].contains(hourSecondDigit(from: currentTime)) ? 1 : 2))

                                                // Minute second digit - left half (on bottom vertically)
                                                //Text("7")
                                                Text(minuteSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(colorLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .animation(.easeInOut(duration: 0.1), value: colorLuminanceReduced)
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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? -40 - CGFloat(settings.fontSize) / 2 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))                                                     .frame(width: 60, alignment: .center) // Wider frame, center alignment
                                                    .offset(x:minuteSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default") ? 60 : 45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1", "7"].contains(hourSecondDigit(from: currentTime)) ? 1 :  ["1", "7"].contains(minuteSecondDigit(from: currentTime)) ? 2 : 1)
                                                            : (["1", "4", "7", "9"].contains(hourSecondDigit(from: currentTime)) ? 2 : 1))
                                            }
                                            .offset(x: !(settings.timeFont == "Default") ? 20 : 15)
                                            .frame(width: 30, height: 150)
                                            
                                            // Right half - Hour on top of Minute (vertically) - Center aligned, left masked
                                            ZStack {
                                                // Hour second digit - right half (on top vertically)
                                                //Text("5")
                                                Text(hourSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(settings.lightMode ? .black : .white)

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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? 20 + CGFloat(settings.fontSize) / 2 : 1)
                                                            : (isLuminanceReduced ? 15 : 1))                                                    .offset(x:hourSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default") ? -55 : -45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1"].contains(minuteSecondDigit(from: currentTime)) ? 2 : ["1", "4", "7"].contains(hourSecondDigit(from: currentTime)) ? 2 : 1)
                                                            : (["1", "4", "6"].contains(minuteSecondDigit(from: currentTime)) ? 2 : 1))

                                                // Minute second digit - right half (on bottom vertically)
                                                //Text("7")
                                                Text(minuteSecondDigit(from: currentTime))
                                                    .scaleEffect(x:1, y:1)
                                                    .foregroundColor(colorLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                                    .animation(.easeInOut(duration: 0.1), value: colorLuminanceReduced)
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
                                                    .offset(y: !(settings.timeFont == "Default")
                                                            ? (isLuminanceReduced ? -40 - CGFloat(settings.fontSize) / 2 : -26)
                                                            : (isLuminanceReduced ? -36 : -26))
                                                    .offset(x:minuteSecondDigit(from: currentTime) == "1" ? -10 : 0)
                                                    .offset(y: !(settings.timeFont == "Default") ? 60 : 45)
                                                    .zIndex(!(settings.timeFont == "Default")
                                                            ? (["1"].contains(minuteSecondDigit(from: currentTime)) ? 1 : ["1", "4", "7"].contains(hourSecondDigit(from: currentTime)) ? 1 : 2)
                                                            : (["1", "4", "6"].contains(minuteSecondDigit(from: currentTime)) ? 1 : 2))
                                            }
                                            .offset(x: !(settings.timeFont == "Default") ? -10 : -15) //15 for zb
                                            .frame(width: 30, height: 150)
                                        }
                                    }
                                }
                                .font(settings.timeFont == "Default" ?
                                      .zenithBeta(size: 76, weight: .medium) :
                                        (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 76 + CGFloat(settings.fontSize) * 2.1, weight: .medium) } ?? .zenithBeta(size: 76, weight: .medium)))
                                .dynamicTypeSize(.xSmall)
                                .scaleEffect(!(settings.timeFont == "Default") ?
                                            CGSize(width: 1, height: 1) :
                                            CGSize(width: 1.05, height: 1.3))
                                .foregroundColor(.white)
                                .frame(width: 150, height: 60)
                                .position(x: geometry.size.width/2, y: centerY/2+25)
                                .offset(y: !(settings.timeFont == "Default") ? -3 : 5)
                                .offset(y:CGFloat(settings.fontSize) / 2) //offset for font size
                                .onReceive(timeTimer) { input in
                                    currentTime = input
                                }
                                .animation(.easeInOut(duration: 0.2), value: isLuminanceReduced)
                                
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
                                 */
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
            if !hasInitializedShowCruiseInfo {
                showCruiseInfo = settings.launchScreen != .time
                hasInitializedShowCruiseInfo = true
                showingWatchFace.toggle()
                showingWatchFace.toggle()
            }
            if !hasInitializedShowCruiseInfo {
                showCruiseInfo = settings.launchScreen != .time
                hasInitializedShowCruiseInfo = true
                showingWatchFace.toggle()
                showingWatchFace.toggle()
            }
        }
        .onChange(of: isLuminanceReduced) { newValue in
            // Update color with animation
            withAnimation(.easeInOut(duration: 0.1)) {
                colorLuminanceReduced = newValue
            }
            // The isLuminanceReduced environment value is already updated by the system
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
