//
//  WatchTimerState.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 18/11/2024.
//

import Foundation
import SwiftUI
import WatchKit
import WidgetKit

class WatchTimerState: ObservableObject {
    @Published var mode: TimerMode = .setup
    @Published var selectedMinutes: Int = UserDefaults.standard.integer(forKey: "lastUsedTime") != 0 ? UserDefaults.standard.integer(forKey: "lastUsedTime") : 5  // Load saved time or default to 5
    @Published var currentTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isConfirmed: Bool = false
    @Published var previousMinutes: Int = 2
    
    // Add persistent timer manager
    private let persistentTimer = PersistentTimerManager()
    
    init() {
        
        // Add observer for shortcut notifications
        NotificationCenter.default.addObserver(
            forName: Notification.Name("StartCountdownFromShortcut"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let minutes = notification.userInfo?["minutes"] as? Int {
                self?.startFromShortcut(minutes: minutes)
            }
        }
        
        // Check for existing timer state
        if persistentTimer.isTimerRunning {
            mode = persistentTimer.isInStopwatchMode ? .stopwatch : .countdown
            isRunning = true
            currentTime = persistentTimer.getCurrentTime()
        }
    }
    
    
    // Add these properties to track last haptic times
    private var lastMinuteHaptic: Int = 0
    private var lastSecondHaptic: Int = 0
    private var lastStopwatchMinute: Int = 0
    
    var progress: Double {
        switch mode {
        case .setup:
            return 1
        case .countdown:
            return (currentTime / (Double(selectedMinutes) * 60)) //counterclockwise
        case .stopwatch:
            return (currentTime.truncatingRemainder(dividingBy: 60)) / 60 //clockwise
        }
    }
    
    var formattedTime: String {
        switch mode {
        case .setup:
            // Show selected time when confirmed, otherwise show picker value
            if isConfirmed {
                let minutes = Int(currentTime) / 60
                let seconds = Int(currentTime) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            } else {
                return String(format: "%02d:00", selectedMinutes)
            }
        case .countdown:
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
    
    private func startFromShortcut(minutes: Int) {
        // Validate minutes
        guard minutes >= 1 && minutes <= 30 else { return } //max 30
        
        // Set up timer state
        selectedMinutes = minutes
        mode = .countdown
        currentTime = Double(minutes * 60)
        isConfirmed = true
        isRunning = true
        
        // Start persistent timer
        persistentTimer.startCountdown(minutes: minutes)
    }
    
    
    func confirmSelection() {
        isConfirmed = true
        currentTime = Double(selectedMinutes * 60)  // Set the current time when confirming
        print("Confirmed time: \(currentTime) seconds") // Debug print
    }
    
    func startTimer() {
        if mode == .setup {
            mode = .countdown
            // Don't reset currentTime if already confirmed
            currentTime = Double(selectedMinutes * 60)
            UserDefaults.standard.set(selectedMinutes, forKey: "lastUsedTime")
            persistentTimer.startCountdown(minutes: selectedMinutes)
            WKInterfaceDevice.current().play(.start) //haptic
        }
        isRunning = true
        persistentTimer.resumeTimer() // Add this to ensure persistent timer starts
    }
   
    func updateTimer() {
        guard isRunning else { return }
        
        // Update time from persistent timer
        currentTime = persistentTimer.getCurrentTime()
        
        // Update mode if needed
        if persistentTimer.isInStopwatchMode && mode != .stopwatch {
            mode = .stopwatch
            WKInterfaceDevice.current().play(.success)
        }
    
        
        if mode == .countdown {
            if currentTime > 0 {
                let oldTime = currentTime
                currentTime -= 0.01
                
                // 2. Haptic at each minute mark
                let currentMinute = Int(currentTime) / 60
                let previousMinute = Int(oldTime) / 60
                if currentMinute != previousMinute && currentTime > 5.0 {
                    WKInterfaceDevice.current().play(.notification)
                }
                
                // 3. Haptic at last five seconds
                if currentTime <= 5.0 {
                    let currentSecond = Int(ceil(currentTime))
                    if currentSecond != lastSecondHaptic {
                        switch currentSecond {
                        case 5, 4, 3, 2:
                            WKInterfaceDevice.current().play(.click)
                        case 1:
                            playLastSecondHaptic()
                        default:
                            break
                        }
                        lastSecondHaptic = currentSecond
                    }
                }
            } else {
                mode = .stopwatch
                currentTime = 0
                lastStopwatchMinute = 0
                
                // 4. Double haptic at start of stopwatch
                playDoubleHaptic()
            }
        } else if mode == .stopwatch {
            currentTime += 0.01
            
            // 5. Haptic at each minute of stopwatch
            let currentMinute = Int(currentTime) / 60
            if currentMinute != lastStopwatchMinute {
                WKInterfaceDevice.current().play(.notification)
                lastStopwatchMinute = currentMinute
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        WKInterfaceDevice.current().play(.stop)
        persistentTimer.pauseTimer()

    }
    
    func resumeTimer() {
         isRunning = true
         persistentTimer.resumeTimer()
     }
    
    // Helper function for last second multiple haptics
    private func playLastSecondHaptic() {
        // Three quick haptics for the last second
        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(.click)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                WKInterfaceDevice.current().play(.click)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    // Helper function for double haptic
    private func playDoubleHaptic() {
        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
    
    func resetTimer() {
        mode = .setup
        isRunning = false
        currentTime = 0
        isConfirmed = false
        persistentTimer.resetTimer()

    }
}

