//
//  ExtendedSessionManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 06/03/2025.
//

import Foundation
import WatchKit

class ExtendedSessionManager: NSObject, WKExtendedRuntimeSessionDelegate {
    static let shared = ExtendedSessionManager()
    
    private var extendedSession: WKExtendedRuntimeSession?
    private var updateTimer: Timer?
    private var timerState: WatchTimerState?
    
    private override init() {
        super.init()
    }
    
    func startSession(timerState: WatchTimerState) {
        self.timerState = timerState
        
        // If a session is already running, we need to stop it first
        if let existingSession = extendedSession, existingSession.state == .running {
            extendedSession?.invalidate()
            updateTimer?.invalidate()
        }
        
        // Create and start a new extended runtime session
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = self
        extendedSession?.start()
        
        print("⌚️ ExtendedSessionManager: Starting extended runtime session")
    }
    
    func stopSession() {
        // Invalidate the session and timer
        extendedSession?.invalidate()
        updateTimer?.invalidate()
        extendedSession = nil
        updateTimer = nil
        
        print("⌚️ ExtendedSessionManager: Stopping extended runtime session")
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("⌚️ ExtendedSessionManager: Extended runtime session started")
        
        // Create a timer that updates once per second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimerUI()
        }
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("⌚️ ExtendedSessionManager: Extended runtime session will expire")
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("⌚️ ExtendedSessionManager: Extended runtime session invalidated with reason: \(reason.rawValue)")
        
        // Clean up resources
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func updateTimerUI() {
        guard let timerState = timerState, timerState.isRunning else { return }
        
        DispatchQueue.main.async {
            // Update the timer state
            timerState.updateTimer()
            
            print("⌚️ ExtendedSessionManager: Updating timer UI during extended runtime session")
        }
    }
}
