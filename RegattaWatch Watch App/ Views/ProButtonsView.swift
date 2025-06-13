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
    @State private var isResetPrimed = false
    @State private var resetTimer: Timer?
    @EnvironmentObject var settings: AppSettings

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
                    timerState.startFromMinutes(settings.quickStartMinutes)
                } else {
                    // Stopwatch mode behavior
                    if timerState.isRunning {
                        // Prime for reset if not already primed
                        if !isResetPrimed {
                            isResetPrimed = true
                            HapticManager.shared.playFailureFeedback()
                            // Reset the primed state after 0.5 seconds
                            resetTimer?.invalidate()
                            resetTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                                isResetPrimed = false
                            }
                        } else {
                            // Second tap within 0.5 seconds - reset and restart
                            isResetPrimed = false
                            resetTimer?.invalidate()
                            timerState.resetAndRestartStopwatch()
                            HapticManager.shared.playConfirmFeedback()
                        }
                    } else {
                        // Not running - normal reset behavior
                        HapticManager.shared.playFailureFeedback()
                        timerState.resetTimer()
                    }
                }
            }) {
                Image(systemName: leftButtonIcon)
                    .font(.system(size: 24))
                    .scaleEffect(leftButtonIcon == "bolt.ring.closed" ? 1.2 : 1.0)
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(leftButtonForegroundColor)
                    .frame(width: 65, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(leftButtonColor)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Right Button
            Button(action: {
                if timerState.mode == .setup {
                    timerState.startTimer()
                } else if timerState.isRunning {
                    timerState.pauseTimer()
                } else {
                    timerState.resumeTimer()
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
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var leftButtonForegroundColor: Color {
        if timerState.mode == .stopwatch && isResetPrimed {
            return .orange
        } else if leftButtonIcon == "xmark" {
            return .orange
        } else {
            return settings.lightMode ? .black : .white
        }
    }
    
    private var leftButtonColor: Color {
        if timerState.mode == .stopwatch && isResetPrimed {
            return Color.orange.opacity(0.4)
        } else if leftButtonIcon == "xmark" {
            return Color.orange.opacity(0.4)
        } else {
            return Color.gray.opacity(0.4)
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
                "bolt.ring.closed" : "xmark"
        case .stopwatch:
            if timerState.isRunning {
                return "arrow.counterclockwise"
            } else {
                return "xmark"
            }
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
