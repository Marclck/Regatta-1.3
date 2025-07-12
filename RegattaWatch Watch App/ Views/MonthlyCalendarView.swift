//
//  MonthlyCalendarView.swift
//  RegattaWatch Watch App
//
//  Created by Assistant on 03/07/2025.
//

import Foundation
import SwiftUI

struct MonthlyCalendarView: View {
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @State private var currentSecond: Double = 0
    
    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }
    
    private var secondsProgress: Double {
        currentSecond / 60.0
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            // Use the full screen width and height
            let barWidth = frame.width
            let barHeight = frame.height
            
            ZStack {
                /*
                // Background track - wrapping around screen edges
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .stroke(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3), lineWidth: 25)
                    .frame(width: barWidth, height: barHeight)
                    .position(x: frame.midX, y: frame.midY)

                // Progress fill - real-time seconds
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .trim(from: 0, to: secondsProgress)
                    .stroke(
                        Color(hex: colorManager.selectedTheme.rawValue),
                        style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                    )
                    .frame(width: barHeight, height: barWidth)
                    .position(x: frame.midX, y: frame.midY)
                    .rotationEffect(.degrees(-90))  // Align trim start to top
                 */

                // Month separators (4x the original trim length)
                ForEach(1...12, id: \.self) { month in
                    let separatorPosition = Double(month) / 12.0
                    let isCurrentMonth = month == currentMonth
                    
                    RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                        .trim(from: max(0, separatorPosition - 0.004),  // 4x original 0.002
                              to: min(1, separatorPosition + 0.004))    // 4x original 0.002
                        .stroke(
                            isCurrentMonth ?
                                Color(hex: ColorTheme.signalOrange.rawValue).opacity(1) :
                                (settings.lightMode ? Color.white : Color.black),
                            style: StrokeStyle(lineWidth: 32, lineCap: .butt)
                        )
                        .frame(width: barHeight, height: barWidth)
                        .position(x: frame.midX, y: frame.midY)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 0) // Added shadow
                }
                
                // 12 o'clock trim compensator (to clean up the top separator)
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .trim(from: 0, to: 0.002)  // 4x original 0.002
                    .stroke(
                        (currentMonth == 1) ?
                            Color(hex: ColorTheme.signalOrange.rawValue).opacity(1) :
                            (settings.lightMode ? Color.white : Color.black),
                        style: StrokeStyle(lineWidth: 32, lineCap: .butt)
                    )
                    .frame(width: barHeight, height: barWidth)
                    .position(x: frame.midX, y: frame.midY)
                    .rotationEffect(.degrees(-90))

                
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .trim(from: 0.998, to: 1)  // 4x original would be 0.008, so 1 - 0.008 = 0.992
                    .stroke(
                        (currentMonth == 1) ?
                            Color(hex: ColorTheme.signalOrange.rawValue).opacity(1) :
                            (settings.lightMode ? Color.white : Color.black),
                        style: StrokeStyle(lineWidth: 32, lineCap: .butt)
                    )
                    .frame(width: barHeight, height: barWidth)
                    .position(x: frame.midX, y: frame.midY)
                    .rotationEffect(.degrees(-90))

            }
        }
        .ignoresSafeArea()  // Allow the view to extend to the edges
        /*
        .onAppear {
            updateCurrentSecond()
        }
         */
    }
    
    /*
    private func updateCurrentSecond() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let now = Date()
            let seconds = Calendar.current.component(.second, from: now)
            let nanoseconds = Calendar.current.component(.nanosecond, from: now)
            currentSecond = Double(seconds) + Double(nanoseconds) / 1_000_000_000.0
        }
    }
    */
    
}
