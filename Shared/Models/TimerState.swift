//
//  TimerState.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import Foundation
import SwiftUI
import UIKit

enum TimerMode {
    case setup
    case countdown
    case stopwatch
}

class TimerState: ObservableObject {
    @Published var mode: TimerMode = .setup
    @Published var previousMinutes: Int = 3  // Add this to track previous value
    @Published var selectedMinutes: Int = 3 {
        didSet {
            // Trigger animation when minutes change
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                // Any additional state updates if needed
            }
        }
    }
    
    func startFromShortcut(minutes: Int) {
        guard minutes >= 1 && minutes <= 30 else { return } //30max
        selectedMinutes = minutes
        currentTime = Double(minutes * 60)
        mode = .countdown
        isConfirmed = true
        isRunning = true
        // Any other necessary state updates
    }
    
    func updateMinutes(_ newValue: Int) {
        previousMinutes = selectedMinutes
        selectedMinutes = newValue
    }
    @Published var currentTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isConfirmed: Bool = false
    @Published private var currentSeparatorCount: Int = 5
    
    private var separatorAnimation: Animation?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let countdownFeedbackGenerator = UINotificationFeedbackGenerator()
    
    var formattedTime: String {
        switch mode {
        case .setup, .countdown:
            let minutes = Int(currentTime) / 60
            let seconds = Int(currentTime) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        case .stopwatch:
            let minutes = Int(currentTime) / 60
            let seconds = Int(currentTime) % 60
            let milliseconds = Int((currentTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
        }
    }
    
    var progress: Double {
        switch mode {
        case .setup:
            return 0
        case .countdown:
            return 1 - (currentTime / (Double(selectedMinutes) * 60)) //counterclockwise
        case .stopwatch:
            return (currentTime.truncatingRemainder(dividingBy: 60)) / 60 //clockwise
        }
    }
    
    func startTimer() {
        if mode == .setup {
            mode = .countdown
            currentTime = Double(selectedMinutes * 60)
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred(intensity: 1.0)
        }
        isRunning = true
    }
    
    func pauseTimer() {
        isRunning = false
    }
    
    func resetTimer() {
        mode = .setup
        isRunning = false
        currentTime = 0
        isConfirmed = false
    }
    
    func updateTimer() {
        guard isRunning else { return }
        
        if mode == .countdown {
            if currentTime > 0 {
                currentTime -= 0.01
                
                // Haptic feedback for last 5 seconds
                if currentTime <= 5.0 && currentTime > 0 {
                    _ = Int(ceil(currentTime))
                    if currentTime.truncatingRemainder(dividingBy: 1) <= 0.01 {
                        feedbackGenerator.impactOccurred(intensity: 0.7)
                    }
                }
            } else {
                mode = .stopwatch
                currentTime = 0
                countdownFeedbackGenerator.notificationOccurred(.success)
            }
        } else if mode == .stopwatch {
            currentTime += 0.01
        }
    }
}
