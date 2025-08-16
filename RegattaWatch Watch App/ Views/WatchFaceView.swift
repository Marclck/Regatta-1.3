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
    @StateObject private var fontManager = CustomFontManager.shared
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
    @State private var hasInitializedShowCruiseInfo = false

    @Binding var showCruiseInfo: Bool

    var isShowingCruiseInfo: Bool {
        showCruiseInfo
    }
    
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
                    // Progress bar showing seconds
                    if cruisePlanState.isActive {
                        WaypointProgressBarView(
                            plannerManager: WatchPlannerDataManager.shared,
                            locationManager: locationManager
                        )
                    } else {
                        // Progress bar showing seconds
                        SecondProgressBarView()
                        
//                        if settings.useProButtons && !showCruiseInfo{
//                            MonthlyCalendarView()
//                        } else {
                        /*
                            Text(settings.teamName)
                            .font(settings.teamNameFont == "Default" ?
                                  .system(size: 9, weight: .semibold) :
                                  Font.customFont(fontManager.customFonts.first(where: { $0.id.uuidString == settings.teamNameFont }) ?? fontManager.customFonts.first!, size: 9) ?? .system(size: 9, weight: .semibold))                          .rotationEffect(.degrees(270), anchor: .center)
                                .foregroundColor(Color(hex: settings.teamNameColorHex).opacity(1))
                                .position(x: settings.teamNameFont == "Default" ? 4 : 5, y: centerY/2+55)
                                .onReceive(timeTimer) { input in
                                    currentTime = input
                                }
                        */
//                        }
                    }
                    
                    // Content
                    VStack(spacing: 0) {
                        /* //for 1.5 release
                        // Timer display instead of current time
                        if settings.showCruiser && !showCruiseInfo {
                            Circle()
                                .fill(timerState.mode == .countdown && timerState.currentTime <= 60
                                      ? Color.orange.opacity(1)
                                      : Color(hex: colorManager.selectedTheme.rawValue).opacity(1))
//                                .glassEffect(in: .circle)
                                .colorScheme(.light)
                                .frame(width: 10, height: 10)
                                .offset(y:-35)
                        } else if settings.useProButtons && !showCruiseInfo {
                            Circle()
                                .fill(timerState.mode == .countdown && timerState.currentTime <= 60
                                      ? Color.orange.opacity(1)
                                      : Color(hex: colorManager.selectedTheme.rawValue).opacity(1))
//                                .glassEffect(in: .circle)
                                .colorScheme(.light)
                                .frame(width: 10, height: 10)
                                .offset(y:-35)
 
                        } else {
                            */
                            TimerDisplayAsCurrentTime(timerState: timerState)
                                .padding(.top, -10)
                                .offset(y: smallWatch ? -15 : -10)
                        //}
                        
                        Spacer()
                            .frame(height: 10)
                            .offset(y: smallWatch ? -5 : 0)
                        
                        if settings.showCruiser && showCruiseInfo {
                            Spacer()
                                .frame(height: 30)
                            
                            HStack(spacing: 0) {
                                Text(hourString(from: currentTime))
                                    .font(settings.timeFont == "Default" ?
                                          .zenithBeta(size: 38, weight: .medium) :
                                            (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 38, weight: .medium) } ?? .zenithBeta(size: 38, weight: .medium)))
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-48.5)
                                
                                VStack(spacing: 10) {
                                    Circle()
                                        .fill(settings.lightMode ? Color.black : Color.white)
                                        .frame(width: 6, height: 6)
                                    Circle()
                                        .fill(settings.lightMode ? Color.black : Color.white)
                                        .frame(width: 6, height: 6)
                                }
                                .offset(x:-0.5, y:-49)
                                
                                /*
                                Text(":")
                                    .font(.zenithBeta(size: 38, weight: .regular))
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:-53)
                                */
                                
                                Text(minuteString(from: currentTime))
                                    .font(settings.timeFont == "Default" ?
                                          .zenithBeta(size: 38, weight: .medium) :
                                          (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 38, weight: .medium) } ?? .zenithBeta(size: 38, weight: .medium)))
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                    .offset(x: 3, y:-48.5)
                            }
                            .font(.zenithBeta(size: 84, weight: .semibold))
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+25)
                            .offset(y: smallWatch ? -5 : 0)
                            .scaleEffect(x:!(settings.timeFont == "Default") ? 1.3 : 1.4, y: !(settings.timeFont == "Default") ? 1 : 1.1)
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
                            .offset(y:settings.ultraModel ? 15 : (isSmallWatch ? 20 : 10))

                            /* //for 1.5 release
                        } else if settings.useProButtons && !showCruiseInfo {
                                // Show current time
                            VStack(spacing: 0) {
                            
                                HStack(spacing: 0) {
                                    Text(hourString(from: currentTime))
                                        .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 50) : .zenithBeta(size: 46, weight: .regular)) //82?
                                        .foregroundColor(settings.lightMode ? .black : .white)
                                        .offset(y:-2)
                                    
                                    Text(":")
                                        .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 52) : .zenithBeta(size: 52, weight: .regular)) //82?
                                        .foregroundColor(settings.lightMode ? .black : .white)
                                        .offset(x: settings.debugMode ? -3 : 0)
                                        .offset(y:-6.5)
                                    
                                    Text(minuteString(from: currentTime))
                                        .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 50) : .zenithBeta(size: 46, weight: .regular)) //82?
                                        .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                        .offset(y:-2)
                                }
                                .offset(y:settings.debugMode ? 0 : 10)
                                
                                
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
                                .offset(y:settings.ultraModel ? 2 : (isSmallWatch ? 2 : 2))
                                
                                
                                // Circular Progress Bar
                                ZStack{

                                    Circle()
                                        .fill(settings.lightMode ? .white : .black)
//                                        .glassEffect(in: .circle)
                                        .colorScheme(settings.lightMode ? .light: .dark)
                                        .frame(width: 115, height: 115)
                                    
                                    
                                    CircularProgressBarView(timerState: timerState, realTime: $currentTime) // <--- MODIFIED
                                        .environmentObject(colorManager)
                                        .environmentObject(settings)

                                    
                                    CircularProButtonsView(timerState: timerState)
                                        // Provide environment objects that CircularProButtonsView needs
                                        .environmentObject(colorManager)
                                        .environmentObject(settings)
                                        .offset(y: settings.ultraModel ? 45 : (isSmallWatch ? 40 : 40))
                                    
                                }
                                    .offset(y: settings.ultraModel ? -15 : (isSmallWatch ? -15 : -15))

                                }
                                .offset(y:settings.debugMode ? 0 : -15)
                                .dynamicTypeSize(.xSmall)
                                .foregroundColor(.white)
                                .frame(width: 150, height: 60)
                                .position(x: geometry.size.width/2, y: centerY/2+25)
                                .offset(y: settings.debugMode ? 0 : 5)
                                .onReceive(timeTimer) { input in
                                    currentTime = input
                                }
                             */
                            
                        } else {
                            // Show current time
                            VStack(spacing: -10) {
                                Text(hourString(from: currentTime))
                                    .scaleEffect(x:1, y:1)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:isLuminanceReduced ? 17 : 8)
                                    .offset(y: !(settings.timeFont == "Default") ? 0 : 5)
                                
                                Text(minuteString(from: currentTime))
                                    .scaleEffect(x:1, y:1)
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
                                    .offset(y:isLuminanceReduced ? -26 : -14)
                                    .offset(y: !(settings.timeFont == "Default") ? 0 : 5)
                            }
//                            .font(.zenithBeta(size: 80, weight: .medium))
                            .font(settings.timeFont == "Default" ?
                                  .zenithBeta(size: 80, weight: .medium) :
                                  (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 60, weight: .medium) } ?? .zenithBeta(size: 80, weight: .medium)))
                            .scaleEffect(!(settings.timeFont == "Default") ?
                                        CGSize(width: 1, height: 1.1) :
                                        CGSize(width: 1.05, height: 1.43))
                            .foregroundColor(.white)
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+10)
                            .offset(y:7)
                            .offset(y: smallWatch ? -5 : 0)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                            
                            Spacer()
                                .frame(height: 20)
                            
                            VStack(alignment: .center, spacing: 1) {
                                if !isSmallWatch {
                                    Text(dateString(from: Date()))
                                        .font(.system(size:14))
                                        .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))
                                }

                                if !isSmallWatch {
                                    Text("Race \(JournalManager.shared.allSessions.count)")
                                        .font(.system(size: 14))
                                        .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))
                                } else {
                                    Text("Race \(JournalManager.shared.allSessions.count)")
                                        .font(.system(size: 14))
                                        .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))
                                }
                            }
                            .frame(width: 180, height: 40)
                            .padding(.bottom, 0)
                            .offset(y: isSmallWatch ? 28 : 26)
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
                        PrivacyOverlayView()
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
                                height: (settings.showCruiser && showCruiseInfo) ? 70 : 100
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
                    if !hasInitializedShowCruiseInfo {
                        showCruiseInfo = settings.launchScreen != .time
                        hasInitializedShowCruiseInfo = true
                    }

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
