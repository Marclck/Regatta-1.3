//
//  ButtonsView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/11/2024.
//

import Foundation
import SwiftUI

struct ButtonsView: View {
    @ObservedObject var timerState: WatchTimerState
    
    var body: some View {
        
        HStack(spacing: 12) {
            // Left Button
            Button(action: {
                print("⚡️ Left button tapped - Current mode: \(timerState.mode)")
                if timerState.mode == .setup {
                    if timerState.isConfirmed {
                        // Reset button pressed
                        HapticManager.shared.playFailureFeedback()
                        print("⚡️ Resetting timer")
                        timerState.resetTimer()
                    } else {
                        print("⚡️ Confirming selection")
                        // Confirm button pressed
                        HapticManager.shared.playConfirmFeedback()
                        timerState.confirmSelection()
                        print("⚡️ After confirmation - currentTime: \(timerState.currentTime)")

                    }
                } else {
                    print("⚡️ Resetting timer from non-setup mode")
                    HapticManager.shared.playFailureFeedback()
                    timerState.resetTimer()
                }
            }) {
                Image(systemName: leftButtonIcon)
                    .font(.system(size: 24, weight: .bold))
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(.white)
                    .frame(width: 65, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.gray.opacity(0.3))
                    )
                // Remove any additional backgrounds/shadows by clipping
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
                    .font(.system(size: 24, weight: .bold))
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(.cyan)
                    .frame(width: 65, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.blue.opacity(0.3))
                    )
                // Remove any additional backgrounds/shadows by clipping
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
        }
    }
    private var leftButtonIcon: String {
        switch timerState.mode {
        case TimerMode.setup:
            return timerState.isConfirmed ? "arrow.counterclockwise" : "checkmark"
        case TimerMode.countdown, TimerMode.stopwatch:
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
