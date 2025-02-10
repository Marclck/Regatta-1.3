//
//  TimerDisplayAsCurrentTimeView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 01/12/2024.
//

import Foundation
import SwiftUI
import WatchKit

struct TimerDisplayAsCurrentTime: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager

    
    var body: some View {
        Text(displayText)
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
    }
    
    private var displayText: String {
        switch timerState.mode {
        case .setup:
            return String(format: "%02d:00", timerState.selectedMinutes)
        case .countdown, .stopwatch:
            return timerState.formattedTime
        }
    }
    
    private var backgroundColor: Color {
        timerState.mode == .countdown && timerState.currentTime <= 60
            ? Color.orange.opacity(1)
            : Color(hex: colorManager.selectedTheme.rawValue).opacity(1)
    }
}
