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


    @ObservedObject var timerState: WatchTimerState
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var currentTime = Date()
    let timeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let centerY = geometry.size.height/2
                ZStack {


                    // Progress bar showing seconds
                    SecondProgressBarView()
                    
                    
                    Text(settings.teamName)
                        .font(.system(size: 11, weight: .bold)) //36 b4 adjustment
                        .rotationEffect(.degrees(270), anchor: .center)
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.8)) // see how the code is referenced.
                        .position(x: 4, y: centerY/2+60)
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
                        
                        // Show current time
                        VStack(spacing: -10) {  // Adjust spacing as needed
                           // Hours
                           Text(hourString(from: currentTime))
                               .scaleEffect(x:1, y:1)
                               .foregroundColor(.white)
                               .offset(y:isLuminanceReduced ? 17 : 8) //16/7
                           
                           // Minutes
                           Text(minuteString(from: currentTime))
                               .scaleEffect(x:1, y:1)
                               .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : .white)
                               .offset(y:isLuminanceReduced ? -26 : -14) //-30/-23
                        }
                        .font(.zenithBeta(size: 80, weight: .medium))
                            .scaleEffect(x:1, y:1.1)
                            .foregroundColor(.white)
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+10)
                            .offset(y:7)
                            //.ignoresSafeArea()
                            .onReceive(timeTimer) { input in
                                currentTime = input
                            }
                        
                        Spacer()
                            .frame(height: 20)
                        
                        VStack(alignment: .center, spacing: 1) {
                            // Date in format "Wed Nov 22"
                            Text(dateString(from: Date()))
                                .font(.system(size:14))
                                .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))

                            // Last finish time
                            Text("Race \(JournalManager.shared.allSessions.count)")
                               .font(.system(size: 14))
                               .foregroundColor(isLuminanceReduced ? .white.opacity(0.4) : .blue.opacity(0.7))
                        }
                        .frame(width: 180, height: 40)  // Extended width to accommodate text
                        .padding(.bottom, 0)
                        .offset(y:64) //25
                        
                        
                        Text(settings.teamName)
                            .font(.system(size: 14, weight: .bold)) //36 b4 adjustment
                            .rotationEffect(.degrees(270), anchor: .center)
                            .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(1)) // see how the code is referenced.
                            .position(x: 4, y: centerY/2+55)
                            .onReceive(timeTimer) { input in
                                currentTime = input
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
        // Get last finish time from your journal manager
        // This is a placeholder - replace with actual value
        let lastFinishTime = "00:00"  // Replace with actual value fetch
        return lastFinishTime
    }
    
    // Add these helper functions
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
