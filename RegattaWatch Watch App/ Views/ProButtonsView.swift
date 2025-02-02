//
//  ProButtonsView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 02/02/2025.
//

import Foundation
import SwiftUI

struct ProButtonsView: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager

    
    var body: some View {
        
        HStack(spacing: 12) {
            // Left Button
            Button(action: {
                if timerState.mode == .countdown {
                    if timerState.isRunning {
                        // Round to nearest minute when paused
                        let seconds = timerState.currentTime.truncatingRemainder(dividingBy: 60)
                        let currentMinutes = Int(timerState.currentTime / 60)
                        let targetMinutes = seconds >= 30 ? currentMinutes + 1 : currentMinutes
                        timerState.startFromMinutes(targetMinutes > 0 ? targetMinutes : 1)
                    } else if !timerState.isRunning {
                        // Reset functionality when paused
                        HapticManager.shared.playFailureFeedback()
                        timerState.resetTimer()
                    }
                } else if timerState.mode == .setup {
                    // Quick start 5 minutes
                    timerState.startFromMinutes(5)
                } else {
                    // Stopwatch mode - keep existing reset behavior
                    HapticManager.shared.playFailureFeedback()
                    timerState.resetTimer()
                }
            }) {
                Image(systemName: leftButtonIcon)
                    .font(.system(size: 24))
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(leftButtonIcon == "xmark" ? .orange : .white)
                    .frame(width: 65, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(leftButtonIcon == "xmark" ? Color.orange.opacity(0.4) : Color.gray.opacity(0.4))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
            
            // Right Button
            Button(action: {
                if timerState.mode == .setup {
                      timerState.startTimer()  // Start new countdown in setup mode
                  } else if timerState.isRunning {
                      timerState.pauseTimer()  // Pause in countdown/stopwatch mode
                  } else {
                      timerState.resumeTimer() // Resume in countdown/stopwatch mode
                  }
            }) {
                Image(systemName: rightButtonIcon)
                    .font(.system(size: 24))
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(buttonForegroundColor)
                    .frame(width: 65, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(buttonColor)
                    )
                // Remove any additional backgrounds/shadows by clipping
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
        }
    }
    
    private var buttonForegroundColor: Color {
        if timerState.mode == .countdown && timerState.currentTime <= 60 {
            return Color(hex: colorManager.selectedTheme.rawValue)
        } else {
            return Color(hex: colorManager.selectedTheme.rawValue)
        }
    }
    
    private var buttonColor: Color {
        if timerState.mode == .countdown && timerState.currentTime <= 60 {
            return Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4)
        } else {
            return Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4)
        }
    }
    
    
    private var leftButtonIcon: String {
        switch timerState.mode {
        case .setup:
            return "bolt"
        case .countdown:
            return timerState.isRunning ?
                "arrow.counterclockwise" : "xmark"
        case .stopwatch:
            return "xmark"
        }
    }
    
    private var rightButtonIcon: String {
        if timerState.mode == TimerMode.setup {
            return "play"
        } else {
            return timerState.isRunning ? "pause" : "play"
        }
    }
}
