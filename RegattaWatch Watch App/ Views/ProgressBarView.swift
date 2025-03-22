//
//  ProgressBarView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/11/2024.
//

import Foundation
import SwiftUI

struct WatchProgressBarView: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            // Use the full screen width and height
            let barWidth = frame.width
            let barHeight = frame.height
            
            ZStack {
                // Background track - wrapping around screen edges
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .stroke(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3), lineWidth: 25)
                    .frame(width: barWidth, height: barHeight)
                    .position(x: frame.midX, y: frame.midY)

                // Progress fill
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .trim(from: 0, to: timerState.progress)
                    .stroke(
                        Color(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : Color(hex: colorManager.selectedTheme.rawValue)),
                        style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                    )
                    .frame(width: barHeight, height: barWidth)
                    .position(x: frame.midX, y: frame.midY)
                    .rotationEffect(.degrees(-90))  // Align trim start to top
                
                    // Only show separators for non-stopwatch modes
                    if timerState.mode != .stopwatch {
                        // 12 o'clock trim compensator (only needed if there are separators)
                        if timerState.selectedMinutes > 0 {
                            RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                                .trim(from: 0, to: 0.002)
                                .stroke(Color.black,
                                    style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                                )
                                .frame(width: barHeight, height: barWidth)
                                .position(x: frame.midX, y: frame.midY)
                                .rotationEffect(.degrees(-90))
                            
                            RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                                .trim(from: 0.998, to: 1)
                                .stroke(Color.black,
                                    style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                                )
                                .frame(width: barHeight, height: barWidth)
                                .position(x: frame.midX, y: frame.midY)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        // Regular minute separators
                        ForEach(0..<timerState.selectedMinutes, id: \.self) { index in
                            let separatorPosition = Double(index) / Double(timerState.selectedMinutes)
                            
                            RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                                .trim(from: max(0, separatorPosition - 0.002),
                                      to: min(1, separatorPosition + 0.002))
                                .stroke(Color.black,
                                    style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                                )
                                .frame(width: barHeight, height: barWidth)
                                .position(x: frame.midX, y: frame.midY)
                                .rotationEffect(.degrees(-90))
                                .transition(.scale.combined(with: .opacity))
                                .animation(
                                    .spring(
                                        response: 0.6,
                                        dampingFraction: 0.9,
                                        blendDuration: 0
                                    )
                                    .delay(calculateDelay(for: index)),
                                    value: timerState.selectedMinutes
                                )
                        }
                        
                        // Last minute separators (only in countdown mode and during last minute)
                        if timerState.mode == .countdown && timerState.currentTime <= 60 && timerState.currentTime > 0 && timerState.selectedMinutes > 0 {
                            ForEach(0..<5, id: \.self) { index in
                                let minuteSegmentWidth = 1.0 / Double(timerState.selectedMinutes)
                                let lastSegmentStart = minuteSegmentWidth
                                let subSegmentPosition = lastSegmentStart - (minuteSegmentWidth / 6.0 * Double(index + 1))
                                
                                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                                    .trim(from: max(0, subSegmentPosition - 0.002),
                                          to: min(1, subSegmentPosition + 0.002))
                                    .stroke(Color.black,
                                        style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                                    )
                                    .frame(width: barHeight, height: barWidth)
                                    .position(x: frame.midX, y: frame.midY)
                                    .rotationEffect(.degrees(-90))
                            }
                    }
                }
                
                /* Commented out original code
                // Separators overlay
                WatchSeparatorOverlay(
                    totalMinutes: timerState.selectedMinutes,
                    previousMinutes: timerState.previousMinutes,
                    mode: timerState.mode,
                    currentTime: timerState.currentTime,
                    size: CGSize(width: barWidth, height: barHeight),
                    center: CGPoint(x: frame.midX, y: frame.midY)
                )
                
                // Last minute separators with totalMinutes
               LastMinuteSeparatorView(
                   mode: timerState.mode,
                   currentTime: timerState.currentTime,
                   totalMinutes: timerState.selectedMinutes,  // Pass total minutes
                   size: CGSize(width: barWidth, height: barHeight),
                   center: CGPoint(x: frame.midX, y: frame.midY)
               )
                */
            }
        }
        .ignoresSafeArea()  // Allow the progress bar to extend to the edges
    }
    
    // Delay calculation for smooth animation when adding/removing separators
    private func calculateDelay(for index: Int) -> Double {
        let isAdding = timerState.selectedMinutes > timerState.previousMinutes
        
        if isAdding {
            guard index >= timerState.previousMinutes && index < timerState.selectedMinutes else { return 0 }
            return Double(index - timerState.previousMinutes) * 0.1
        } else {
            guard index < timerState.previousMinutes else { return 0 }
            let distanceFromEnd = timerState.previousMinutes - index - 1
            return Double(distanceFromEnd) * 0.1
        }
    }
}
