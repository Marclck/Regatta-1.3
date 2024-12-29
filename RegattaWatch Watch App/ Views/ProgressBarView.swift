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

    private var isUltraWatch: Bool {
        #if os(watchOS)
        return WKInterfaceDevice.current().name.contains("Ultra")
        #else
        return false
        #endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            // Use the full screen width and height
            let barWidth = frame.width
            let barHeight = frame.height
            
            ZStack {
                    // Background track - wrapping around screen edges
                    RoundedRectangle(cornerRadius: 55)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 25)
                        .frame(width: barWidth, height: barHeight)
                        .position(x: frame.midX, y: frame.midY)

                // Progress fill
                    RoundedRectangle(cornerRadius: 55)
                        .trim(from: 0, to: timerState.progress)
                        .stroke(
                            Color(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : Color(hex: colorManager.selectedTheme.rawValue)),
                            style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                        )
                        .frame(width: barHeight, height: barWidth)
                        .position(x: frame.midX, y: frame.midY)
                        .rotationEffect(.degrees(-90))  // Align trim start to top
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
            }
        }
        .ignoresSafeArea()  // Allow the progress bar to extend to the edges
    }
}

#Preview {
    ContentView()
        .environmentObject(ColorManager())
        .environmentObject(AppSettings())
}
