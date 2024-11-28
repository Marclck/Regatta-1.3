//
//  PersistentTimerManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 22/11/2024.
//

import Foundation
import SwiftUI

class PersistentTimerManager: ObservableObject {
    @AppStorage("startTime") private var storedStartTime: Double = 0
    @AppStorage("startAmount") private var storedStartAmount: Double = 0
    @AppStorage("isTimerRunning") private var storedIsTimerRunning: Bool = false
    @AppStorage("isInStopwatchMode") private var storedIsInStopwatchMode: Bool = false
    @AppStorage("stopwatchStartTime") private var storedStopwatchStartTime: Double = 0
    @AppStorage("pauseTime") private var storedPauseTime: Double = 0
    
    var startTime: Date? {
        get { storedStartTime > 0 ? Date(timeIntervalSince1970: storedStartTime) : nil }
        set { storedStartTime = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    var startAmount: TimeInterval {
        get { storedStartAmount }
        set { storedStartAmount = newValue }
    }
    
    var isTimerRunning: Bool {
        get { storedIsTimerRunning }
        set { storedIsTimerRunning = newValue }
    }
    
    var isInStopwatchMode: Bool {
        get { storedIsInStopwatchMode }
        set { storedIsInStopwatchMode = newValue }
    }
    
    var stopwatchStartTime: Date? {
        get { storedStopwatchStartTime > 0 ? Date(timeIntervalSince1970: storedStopwatchStartTime) : nil }
        set { storedStopwatchStartTime = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    var pauseTime: Date? {
        get { storedPauseTime > 0 ? Date(timeIntervalSince1970: storedPauseTime) : nil }
        set { storedPauseTime = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    func startCountdown(minutes: Int) {
        startAmount = TimeInterval(minutes * 60)
        startTime = Date()
        isTimerRunning = true
        isInStopwatchMode = false
        stopwatchStartTime = nil
        
        // Schedule notifications
        WatchNotificationManager.shared.scheduleTimerNotifications(
            duration: TimeInterval(minutes * 60)
        )
    }
    
    func checkBackgroundModeChange() {
        if isTimerRunning && !isInStopwatchMode {
            let currentTime = getCurrentTime()
            if currentTime <= 0 {
                let elapsed = abs(currentTime) // How long ago countdown ended
                let countdownEndTime = Date().addingTimeInterval(-elapsed)
                
                isInStopwatchMode = true
                print("DEBUG: Transition to Stopwatch Mode. Countdown End Time: \(countdownEndTime)")

                if stopwatchStartTime == nil {
                    stopwatchStartTime = countdownEndTime // Set accurate start time
                    print("DEBUG: Stopwatch Start Time Set: \(stopwatchStartTime!)")

                }
            }
        }
    }
    
    func getCurrentTime() -> TimeInterval {
        if isTimerRunning {
            let currentTime = Date().timeIntervalSince(startTime!)
            
            if isInStopwatchMode {
                print("DEBUG: Stopwatch Time Elapsed: \(currentTime)") // Log stopwatch time
                return currentTime - startAmount
            } else {
                let remainingTime = startAmount - currentTime
                //print("DEBUG: Countdown Remaining Time: \(remainingTime)") // Log countdown time
                
                // Check if countdown finished
                if remainingTime <= 0 {
                    // Transition to stopwatch mode
                    isInStopwatchMode = true
                    pauseTime = nil // Clear the pause time
                    return 0
                }
                
                return remainingTime
            }
        } else {
            if let pauseTime = pauseTime {
                return startAmount - Date().timeIntervalSince(pauseTime)
            } else {
                return startAmount
            }
        }
    }
    
    func pauseTimer() {
        isTimerRunning = false
        pauseTime = Date()
        WatchNotificationManager.shared.cancelAllNotifications()
    }
    
    func resumeTimer() {
        isTimerRunning = true
        
        let currentTime = getCurrentTime()
        let remainingTime = currentTime
        
        print("⏱️ Debug - Current time: \(currentTime)")
        print("⏱️ Debug - Start amount: \(startAmount)")
        print("⏱️ Debug - Remaining time: \(remainingTime)")
        
        if let pauseTime = pauseTime {
            let elapsedTimeSinceLastPause = Date().timeIntervalSince(pauseTime)
            startTime = startTime?.addingTimeInterval(elapsedTimeSinceLastPause)
            self.pauseTime = nil
            // Debug pause adjustment
            print("⏱️ Resume - Elapsed since pause: \(elapsedTimeSinceLastPause)")
            print("⏱️ Resume - Adjusted start time: \(startTime?.description ?? "nil")")
        }
        
        // Only schedule if enough time remains
        if remainingTime > 10 {
            WatchNotificationManager.shared.scheduleTimerNotifications(
                duration: remainingTime
            )
            print("⏱️ Resume - Notifications scheduled for \(remainingTime) seconds")
        } else {
            print("⏱️ Resume - Not enough time remaining for notifications")
        }
    }
        
        
        func resetTimer() {
            startTime = nil
            startAmount = 0
            isTimerRunning = false
            isInStopwatchMode = false
            stopwatchStartTime = nil
            WatchNotificationManager.shared.cancelAllNotifications()
            
        }
    }
    
