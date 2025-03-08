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
    
    // State tracking
    private var isStartingSession = false
    private var lastStartAttempt = Date(timeIntervalSince1970: 0)
    private let startCooldown: TimeInterval = 3.0
    
    private override init() {
        super.init()
        print("⌚️ ExtendedSessionManager: Initialized")
    }
    
    func startSession(timerState: WatchTimerState? = nil) {
        // Update timerState if provided
        if let timerState = timerState {
            self.timerState = timerState
        }
        
        // Check if we're already starting a session
        if isStartingSession {
            print("⌚️ ExtendedSessionManager: Already in the process of starting a session")
            return
        }
        
        // Check cooldown period
        let now = Date()
        if now.timeIntervalSince(lastStartAttempt) < startCooldown {
            print("⌚️ ExtendedSessionManager: In cooldown period")
            return
        }
        
        // Check existing session state
        if let existingSession = extendedSession {
            print("⌚️ ExtendedSessionManager: Current session state: \(existingSession.state.rawValue)")
            
            // Check for expiration date if available
            if let expirationDate = existingSession.expirationDate {
                print("⌚️ ExtendedSessionManager: Session expires at: \(expirationDate)")
            }
            
            // Only create a new session if current one is invalid
            if existingSession.state != .invalid {
                print("⌚️ ExtendedSessionManager: Session already exists in valid state")
                return
            }
        }
        
        // Create a new session and start it immediately
        isStartingSession = true
        lastStartAttempt = now
        
        print("⌚️ ExtendedSessionManager: Creating new extended runtime session")
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = self
        
        // Use start() instead of start(at:)
        extendedSession?.start()
        print("⌚️ ExtendedSessionManager: Started session immediately")
    }
    
    func stopSession() {
        if let session = extendedSession {
            print("⌚️ ExtendedSessionManager: Invalidating session")
            session.invalidate()
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("⌚️ ExtendedSessionManager: Session started successfully")
        isStartingSession = false
        
        // Get expiration information if available
        if let expirationDate = extendedRuntimeSession.expirationDate {
            let timeRemaining = expirationDate.timeIntervalSinceNow
            print("⌚️ ExtendedSessionManager: Session will expire in \(timeRemaining) seconds")
        }
        
        // Start the update timer
        startUpdateTimer()
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("⌚️ ExtendedSessionManager: Session will expire soon")
        
        // Attempt to create a new session before this one expires
        DispatchQueue.main.async { [weak self] in
            self?.startSession()
        }
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("⌚️ ExtendedSessionManager: Session invalidated with reason: \(reason.rawValue)")
        
        // Handle standard invalidation reasons
        switch reason {
        case .error:
            print("⌚️ ExtendedSessionManager: Session invalidated due to an error")
        case .none:
            print("⌚️ ExtendedSessionManager: Session ended normally")
        case .sessionInProgress:
            print("⌚️ ExtendedSessionManager: Session invalidated because another session is in progress")
        case .expired:
            print("⌚️ ExtendedSessionManager: Session used all allocated time and expired")
        case .resignedFrontmost:
            print("⌚️ ExtendedSessionManager: Session invalidated because app lost frontmost status")
        case .suppressedBySystem:
            print("⌚️ ExtendedSessionManager: Session invalidated because system doesn't allow it")
        @unknown default:
            print("⌚️ ExtendedSessionManager: Unknown invalidation reason: \(reason.rawValue)")
        }
        
        // Handle the error if present
        if let error = error as? NSError {
            if let errorCode = WKExtendedRuntimeSessionErrorCode(rawValue: error.code) {
                // Handle standard error codes
                handleStandardErrorCode(errorCode)
            } else {
                // Handle other errors
                print("⌚️ ExtendedSessionManager: Error domain: \(error.domain), code: \(error.code)")
                print("⌚️ ExtendedSessionManager: \(error.localizedDescription)")
            }
        }
        
        // Clean up resources
        isStartingSession = false
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Attempt to restart based on the invalidation reason
        switch reason {
        case .error, .expired, .none:
            // These are cases where we might want to restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                print("⌚️ ExtendedSessionManager: Attempting to restart session")
                self?.startSession()
            }
        case .sessionInProgress:
            // No need to restart if another session is running
            print("⌚️ ExtendedSessionManager: Not restarting - another session is already running")
        case .resignedFrontmost, .suppressedBySystem:
            // Not appropriate to restart in these cases
            print("⌚️ ExtendedSessionManager: Not restarting due to system conditions")
        @unknown default:
            // For unknown reasons, attempt restart with longer delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                print("⌚️ ExtendedSessionManager: Attempting to restart after unknown invalidation")
                self?.startSession()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleStandardErrorCode(_ errorCode: WKExtendedRuntimeSessionErrorCode) {
        switch errorCode {
        case .unknown:
            print("⌚️ ExtendedSessionManager: Unknown error occurred")
        case .scheduledTooFarInAdvance:
            print("⌚️ ExtendedSessionManager: Session scheduled too far in advance")
        case .mustBeActiveToStartOrSchedule:
            print("⌚️ ExtendedSessionManager: App must be active to start session")
        case .notYetStarted:
            print("⌚️ ExtendedSessionManager: Session invalidated before it started")
        case .exceededResourceLimits:
            print("⌚️ ExtendedSessionManager: Session exceeded resource limits")
        case .barDisabled:
            print("⌚️ ExtendedSessionManager: Background app refresh is disabled")
        case .notApprovedToStartSession:
            print("⌚️ ExtendedSessionManager: App not approved to start session")
        case .notApprovedToSchedule:
            print("⌚️ ExtendedSessionManager: App not approved to schedule session")
        case .mustBeActiveToPrompt:
            print("⌚️ ExtendedSessionManager: App must be active to prompt")
        case .unsupportedSessionType:
            print("⌚️ ExtendedSessionManager: Unsupported session type")
        @unknown default:
            print("⌚️ ExtendedSessionManager: New unknown error code")
        }
    }
    
    private func startUpdateTimer() {
        // Don't create a timer if one already exists
        guard updateTimer == nil else { return }
        
        print("⌚️ ExtendedSessionManager: Starting update timer")
        
        // Create a timer that updates once per second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            // Update timer state if available and running
            if let timerState = self.timerState, timerState.isRunning {
                timerState.updateTimer()
            }
        }
    }
}
