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
                        .font(.system(size: 11, weight: .bold)) //14 b4 adjustment
                        .rotationEffect(.degrees(270), anchor: .center)
                        .foregroundColor(Color(hex: ColorTheme.speedPapaya.rawValue).opacity(1)) // see how the code is referenced.
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
                        
                        // Show current time
                        VStack(spacing: -10) {  // Adjust spacing as needed
                           // Hours
                           Text(hourString(from: currentTime))
                               .scaleEffect(x:1, y:0.9) //y0.9
                               .foregroundColor(.white)
                               .offset(y:isLuminanceReduced ? 10 : 4) //13
                           
                           // Minutes
                           Text(minuteString(from: currentTime))
                                .scaleEffect(x:1, y:0.9) //y0.9
                               .foregroundColor(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : .white)
                               .offset(y:isLuminanceReduced ? -40 : -24) //37
                           
                            
                        }
                        .font(.zenithBeta(size: 84, weight: .medium))
                        .scaleEffect(x:1, y:1.3) //y1.2
                            .foregroundColor(.white)
                            .frame(width: 150, height: 60)
                            .position(x: geometry.size.width/2, y: centerY/2+25)
                            .offset(y:12)
                            //.ignoresSafeArea()
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
    
    // Function to get first and second digits of hour separately
    private func hourDigits(from date: Date) -> (first: Int, second: Int) {
        let hourStr = hourString(from: date)
        
        // Convert the first character to integer
        let firstDigit = Int(String(hourStr.first!))!
        
        // Convert the second character to integer
        let secondDigit = Int(String(hourStr.last!))!
        
        return (firstDigit, secondDigit)
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
