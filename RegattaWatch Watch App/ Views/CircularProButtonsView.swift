//
//  CircularProButtonsView.swift
//  RegattaWatch Watch App
//
//  Created by YourName on 02/02/2025. // Update with your actual name and date
//

import Foundation
import SwiftUI

struct CircularProButtonsView: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @State private var isResetPrimed = false
    @State private var resetTimer: Timer?
    @EnvironmentObject var settings: AppSettings

    // Opacity states for animation in Circular Buttons
    @State private var leftButtonCurrentOpacity: Double = 0.05
    @State private var rightButtonCurrentOpacity: Double = 0.05

    var body: some View {
        HStack(spacing: 90) {
            // Left Circular Button
            Button(action: {
                // Same logic as ProButtonsView, duplicated as per "minimal changes to existing"
                if timerState.mode == .countdown {
                    if timerState.isRunning {
                        let seconds = timerState.currentTime.truncatingRemainder(dividingBy: 60)
                        let currentMinutes = Int(timerState.currentTime / 60)
                        let targetMinutes = seconds >= 30 ? currentMinutes + 1 : currentMinutes
                        timerState.startFromMinutes(targetMinutes > 0 ? targetMinutes : 1)
                    } else if !timerState.isRunning {
                        HapticManager.shared.playFailureFeedback()
                        timerState.resetTimer()
                    }
                } else if timerState.mode == .setup {
                    timerState.startFromMinutes(settings.quickStartMinutes)
                } else {
                    if timerState.isRunning {
                        if !isResetPrimed {
                            isResetPrimed = true
                            HapticManager.shared.playFailureFeedback()
                            resetTimer?.invalidate()
                            resetTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                                isResetPrimed = false
                            }
                        } else {
                            isResetPrimed = false
                            resetTimer?.invalidate()
                            timerState.resetAndRestartStopwatch()
                            HapticManager.shared.playConfirmFeedback()
                        }
                    } else {
                        HapticManager.shared.playFailureFeedback()
                        timerState.resetTimer()
                    }
                }

                // Animation specific to circular buttons
                withAnimation(.easeOut(duration: 0.1)) { // Immediate change on tap
                    leftButtonCurrentOpacity = 1.0 // Fully opaque when tapped
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay to show full opacity
                    withAnimation(.easeInOut(duration: 2)) {
                        leftButtonCurrentOpacity = 0.05 // Fade back to default
                    }
                }
            }) {
                Image(systemName: leftButtonIcon)
                    .font(.system(size: 12)) // Smaller font for circular button
                    .scaleEffect(leftButtonIcon == "bolt.ring.closed" ? 1.2 : 1.0)
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(leftButtonForegroundColor.opacity(leftButtonCurrentOpacity)) // Apply currentOpacity to foreground
                    .frame(width: 30, height: 30) // Set the total frame size for the button content
                    .background(
                        Circle() // Circular shape
                            .fill(leftButtonColorBase) // Use base color, opacity handled by currentOpacity
                            .opacity(leftButtonCurrentOpacity) // Apply dynamic opacity to background
                    )
            }
            .clipShape(Circle()) // Clip the entire content AFTER the frame is established
            .frame(width: 30, height: 30) // Set the total frame size for the button content
            .buttonStyle(.plain)

            // No buttonStyle or glassEffect for circular buttons

            // Right Circular Button
            Button(action: {
                // Same logic as ProButtonsView, duplicated as per "minimal changes to existing"
                if timerState.mode == .setup {
                    timerState.startTimer()
                } else if timerState.isRunning {
                    timerState.pauseTimer()
                } else {
                    timerState.resumeTimer()
                }

                // Animation specific to circular buttons
                withAnimation(.easeOut(duration: 0.1)) { // Immediate change on tap
                    rightButtonCurrentOpacity = 1.0 // Fully opaque when tapped
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay to show full opacity
                    withAnimation(.easeInOut(duration: 2)) {
                        rightButtonCurrentOpacity = 0.05 // Fade back to default
                    }
                }
            }) {
                Image(systemName: rightButtonIcon)
                    .font(.system(size: 12)) // Smaller font for circular button
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(rightButtonForegroundColor.opacity(rightButtonCurrentOpacity)) // Apply currentOpacity to foreground
                    .frame(width: 30, height: 30) // Set the total frame size for the button content
                    .background(
                        Circle() // Circular shape
                            .fill(rightButtonColorBase) // Use base color, opacity handled by currentOpacity
                            .opacity(rightButtonCurrentOpacity) // Apply dynamic opacity to background
                    )
            }
            .clipShape(Circle()) // Clip the entire content AFTER the frame is established
            .frame(width: 30, height: 30) // Set the total frame size for the button content
            .buttonStyle(.plain)

            // No buttonStyle or glassEffect for circular buttons
        }
    }
    
    // MARK: - Computed Properties (Duplicated from ProButtonsView with minor adjustments for circular appearance)
    private var leftButtonForegroundColor: Color {
        if timerState.mode == .stopwatch && isResetPrimed {
            return .orange.opacity(2)
        } else if leftButtonIcon == "xmark" {
            return .orange.opacity(2)
        } else {
            return settings.lightMode ? .black : .black
        }
    }
    
    // Renamed to 'Base' to indicate opacity is applied separately
    private var leftButtonColorBase: Color {
        if timerState.mode == .stopwatch && isResetPrimed {
            return Color.orange
        } else if leftButtonIcon == "xmark" {
            return Color.orange
        } else {
            return Color.gray
        }
    }
    
    private var rightButtonForegroundColor: Color { // Renamed for consistency
        if timerState.mode == .countdown && timerState.currentTime <= 60 {
            return Color(hex: colorManager.selectedTheme.rawValue)
        } else {
            return Color(hex: colorManager.selectedTheme.rawValue)
        }
    }
    
    // Renamed to 'Base' to indicate opacity is applied separately
    private var rightButtonColorBase: Color { // Renamed for consistency
        if timerState.mode == .countdown && timerState.currentTime <= 60 {
            return Color(hex: colorManager.selectedTheme.rawValue)
        } else {
            return Color(hex: colorManager.selectedTheme.rawValue)
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
