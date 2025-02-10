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

    @ObservedObject var timerState: WatchTimerState
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var currentTime = Date()
    let timeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showCruiseInfo = false
    
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
                    SecondProgressBarView()
                    
                    Text(settings.teamName)
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(270), anchor: .center)
                        .foregroundColor(Color(hex: settings.teamNameColorHex).opacity(1))
                        .position(x: 4, y: centerY/2+55)
                        .onReceive(timeTimer) { input in
                            currentTime = input
                        }
                    
                    // Content
                    VStack(spacing: 0) {
                        // Timer display instead of current time
                        TimerDisplayAsCurrentTime(timerState: timerState)
                            .padding(.top, -10)
                            .offset(y:-10)
                        
                        Spacer()
                            .frame(height: 10)
                        
                        if showCruiseInfo {
                            
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
                            .font(.zenithBeta(size: 84, weight: .medium))
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+25)
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                            
                            HStack(spacing: 5) {
                                WindSpeedView()
                                CompassView()
                                BarometerView()
                            }
                            .offset(y:settings.ultraModel ? 15 : 10)
                            
                        }
                        
                        if !showCruiseInfo {
                            // Show current time
                            VStack(spacing: -10) {
                                Text(hourString(from: currentTime))
                                    .scaleEffect(x:1, y:0.9)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                                    .offset(y:isLuminanceReduced ? 10 : 4)
                                
                                Text(minuteString(from: currentTime))
                                    .scaleEffect(x:1, y:0.9)
                                    .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? .black : .white)
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
                        
                    
                    if showCruiseInfo {
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
                                height: showCruiseInfo ? 70 : 160
                            )
//                            .border(Color.green.opacity(0.3), width: 1)
                            .contentShape(Rectangle())
                            .position(x: geometry.size.width/2, y: geometry.size.height/2+5)
                            .onTapGesture {
                                WKInterfaceDevice.current().play(.click)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showCruiseInfo.toggle()
                                }
                            }
                    }
                }
                .onReceive(timer) { _ in
                    timerState.updateTimer()
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
