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
    private let journalManager = JournalManager.shared
    
    var lastThirtySecondHaptic = false
    
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
    
    // Add the new resetAndRestartStopwatch function
    func resetAndRestartStopwatch() {
        if mode == .stopwatch && isRunning {
            // Record the previous session
            journalManager.recordSessionEnd(totalTime: currentTime)
            let finishTime = persistentTimer.getCurrentTime()
            SharedDefaults.setLastFinishTime(finishTime)
            
            // Reset stopwatch
            currentTime = 0
            lastStopwatchMinute = 0
            
            // Start new session
            persistentTimer.resetTimer()
            persistentTimer.startCountdown(minutes: 0) // Start with 0 minutes for stopwatch
            mode = .stopwatch
            isRunning = true
            
            // Clear any existing finish time
            SharedDefaults.setLastFinishTime(0)
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
            let minutes = (Int(currentTime) + 1) / 60
            let seconds = (Int(currentTime) + 1) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        case .stopwatch:
            let minutes = Int(currentTime) / 60
            let seconds = Int(currentTime) % 60
            //let milliseconds = Int((currentTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%02d:%02d", minutes, seconds)
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
            SharedDefaults.setLastUsedTime(selectedMinutes)
            persistentTimer.startCountdown(minutes: selectedMinutes)
            WKInterfaceDevice.current().play(.start) //haptic
            ExtendedSessionManager.shared.startSession(timerState: self)
        }
        isRunning = true
    }
    
    func startFromMinutes(_ minutes: Int) {
        selectedMinutes = minutes
        mode = .countdown
        currentTime = Double(minutes * 60)
        isConfirmed = true
        isRunning = true
        UserDefaults.standard.set(minutes, forKey: "lastUsedTime")
        SharedDefaults.setLastUsedTime(minutes)
        persistentTimer.startCountdown(minutes: minutes)
        WKInterfaceDevice.current().play(.start)
        ExtendedSessionManager.shared.startSession(timerState: self)
    }

    func adjustMinutes(_ minutes: Int) {
        // Preserve current running state
        let wasRunning = isRunning
        if wasRunning {
            pauseTimer()
        }
        
        // In countdown mode, formattedTime shows currentTime + 1, so we need to account for this
        // Get the actual displayed seconds from formattedTime
        let displayedComponents = formattedTime.split(separator: ":")
        let displayedSeconds = Int(displayedComponents[1]) ?? 0
        let fractionalPart = currentTime.truncatingRemainder(dividingBy: 1)
        
        // Calculate new time preserving the displayed seconds
        let newTime = Double(minutes * 60 + displayedSeconds) - 1 + fractionalPart
        
        // Update timer state
        selectedMinutes = minutes
        currentTime = newTime
        
        // Update persistent timer with the exact time including seconds
        persistentTimer.startAmount = newTime
        persistentTimer.startTime = Date()
        persistentTimer.isTimerRunning = true
        persistentTimer.isInStopwatchMode = false
        persistentTimer.stopwatchStartTime = nil
        
        // Resume if was running
        if wasRunning {
            resumeTimer()
        }
    }
    
    
    func updateTimer() {
            guard isRunning else { return }
            
            // Update time from persistent timer
            currentTime = persistentTimer.getCurrentTime()
            
            // Update mode if needed
            if persistentTimer.isInStopwatchMode && mode != .stopwatch {
                mode = .stopwatch
                WKInterfaceDevice.current().play(.success)
                
                // Ensure stopwatch starts from 0
                lastStopwatchMinute = Int(currentTime) / 60
                journalManager.recordRaceStart() //record race start when mode change

                // Play haptic feedback for stopwatch start
                playDoubleHaptic()
            }
        
            
            if mode == .countdown {
                if currentTime > 0 {
                    let oldTime = currentTime
                    // Only decrement by 0.01 if called from the regular timer, not from the extended session
                    if let caller = Thread.callStackSymbols.first, caller.contains("updateTimerUI") {
                        // Called from extended session, don't decrement time
                        // Time will be updated from persistentTimer
                    } else {
                        currentTime -= 0.01
                    }
                    
                    // 2. Haptic at each minute mark
                    let currentMinute = Int(currentTime) / 60
                    let previousMinute = Int(oldTime) / 60
                    if currentMinute != previousMinute && currentTime > 5.0 {
                        // Play a stronger notification sequence for minute changes
                        WKInterfaceDevice.current().play(.notification)
                        // Add a second notification haptic for emphasis
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            WKInterfaceDevice.current().play(.notification)
                        }
                        print("⌚️ Playing enhanced minute haptic at \(currentTime) seconds")
                    }
                    
                    // 3. Haptic at 30 seconds remaining
                    if currentTime <= 30.0 && currentTime > 29.0 && !lastThirtySecondHaptic {
                        // Play medium strength haptic for 30 second warning
                        WKInterfaceDevice.current().play(.notification)
                        print("⌚️ Playing 30-second warning haptic at \(currentTime) seconds")
                        lastThirtySecondHaptic = true
                    } else if currentTime < 30.0 {
                        // Reset the flag when time is under 30 seconds
                        lastThirtySecondHaptic = false
                    }
                    
                    // 3. Haptic at last five seconds
                    if currentTime <= 5.0 {
                        let currentSecond = Int(ceil(currentTime))
                        if currentSecond != lastSecondHaptic {
                            switch currentSecond {
                            case 5:
                                // For 5 seconds remaining, use notification (stronger than click)
                                WKInterfaceDevice.current().play(.notification)
                                print("⌚️ Playing strong 5-second haptic")
                            case 4, 3, 2:
                                // For other seconds, use double click
                                WKInterfaceDevice.current().play(.click)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    WKInterfaceDevice.current().play(.click)
                                }
                                print("⌚️ Playing enhanced second haptic at \(currentTime) seconds")
                            case 1:
                                playLastSecondHaptic()
                                print("⌚️ Playing enhanced last second haptic at \(currentTime) seconds")
                            default:
                                break
                            }
                            lastSecondHaptic = currentSecond
                        }
                    }
                } else {
                    // Transition to stopwatch mode
                    mode = .stopwatch
                    lastStopwatchMinute = Int(currentTime) / 60
                    
                    // 4. Double haptic at start of stopwatch
                    playDoubleHaptic()
                    print("⌚️ Playing double haptic at stopwatch start")
                }
            } else if mode == .stopwatch {
                // Only increment by 0.01 if called from the regular timer, not from the extended session
                if let caller = Thread.callStackSymbols.first, caller.contains("updateTimerUI") {
                    // Called from extended session, don't increment time
                    // Time will be updated from persistentTimer
                } else {
                    currentTime += 0.01
                }
                
                // 5. Haptic at each minute of stopwatch
                let currentMinute = Int(currentTime) / 60
                if currentMinute != lastStopwatchMinute {
                    WKInterfaceDevice.current().play(.notification)
                    lastStopwatchMinute = currentMinute
                    print("⌚️ Playing stopwatch minute haptic at \(currentTime) seconds")
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
        WKInterfaceDevice.current().play(.start) //haptic
        ExtendedSessionManager.shared.startSession(timerState: self)
     }
    
    // Helper function for last second multiple haptics
    private func playLastSecondHaptic() {
        // Multiple strong haptics for the last second
        DispatchQueue.main.async {
            // Play a notification haptic first (stronger than click)
            WKInterfaceDevice.current().play(.notification)
            
            // Then add three click haptics in quick succession
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                WKInterfaceDevice.current().play(.click)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WKInterfaceDevice.current().play(.click)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    // Helper function for double haptic
    private func playDoubleHaptic() {
        DispatchQueue.main.async {
            // Use success type for a stronger initial haptic
            WKInterfaceDevice.current().play(.success)
            
            // Add a notification haptic slightly after for stronger feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WKInterfaceDevice.current().play(.notification)
            }
            
            // Add one more strong haptic for emphasis
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
    
    func resetTimer() {
        // Record finish time if in stopwatch mode and running
        if mode == .stopwatch {
            journalManager.recordSessionEnd(totalTime: currentTime)
            let finishTime = persistentTimer.getCurrentTime()
            SharedDefaults.setLastFinishTime(finishTime)
            print("⌚️ WatchTimerState: Recorded finish time: \(finishTime)")
        } else {
            journalManager.cancelSession()
            SharedDefaults.setLastFinishTime(0)
            print("⌚️ WatchTimerState: Reset finish time to 0")
        }
      
        mode = .setup
        isRunning = false
        currentTime = 0
        isConfirmed = false
        persistentTimer.resetTimer()
    }
}

