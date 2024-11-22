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
    
    func startCountdown(minutes: Int) {
        startAmount = TimeInterval(minutes * 60)
        startTime = Date()
        isTimerRunning = true
        isInStopwatchMode = false
        stopwatchStartTime = nil
    }
    
    func getCurrentTime() -> TimeInterval {
        guard let startTime = startTime, isTimerRunning else { return startAmount }
        
        if isInStopwatchMode {
            guard let stopwatchStartTime = stopwatchStartTime else { return 0 }
            return Date().timeIntervalSince(stopwatchStartTime)
        } else {
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = startAmount - elapsed
            
            // Check if countdown finished
            if remaining <= 0 && !isInStopwatchMode {
                // Transition to stopwatch
                isInStopwatchMode = true
                stopwatchStartTime = Date()
                return 0
            }
            
            return remaining
        }
    }
    
    func pauseTimer() {
        isTimerRunning = false
    }
    
    func resumeTimer() {
        // Adjust start time to maintain correct elapsed time
        if !isInStopwatchMode {
            let elapsed = startAmount - getCurrentTime()
            startTime = Date().addingTimeInterval(-elapsed)
        }
        isTimerRunning = true
    }
    
    func resetTimer() {
        startTime = nil
        startAmount = 0
        isTimerRunning = false
        isInStopwatchMode = false
        stopwatchStartTime = nil
    }
}
