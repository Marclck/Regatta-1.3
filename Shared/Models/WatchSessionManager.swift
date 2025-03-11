//
//  WatchSessionManager.swift
//  Regatta
//
//  Created by Chikai Lai on 21/12/2024.
//

import Foundation
import WatchConnectivity

#if os(watchOS)
class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession?
    private let queue = DispatchQueue(label: "com.heart.regatta.watchsessionmanager")
    
    // Queue for pending transfers
    private var pendingSessions: [RaceSession]?
    private var isActivated = false
    private var currentSessionIndex = 0
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("⌚️ Watch Session initialized and activating...")
        }
    }
    
    // Required protocol methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("⌚️ Watch Session activation failed: \(error.localizedDescription)")
                return
            }
            
            print("⌚️ Watch Session activated with state: \(activationState.rawValue)")
            print("⌚️ Watch Session isReachable: \(session.isReachable)")
            print("⌚️ Watch Session isCompanionAppInstalled: \(session.isCompanionAppInstalled)")
            
            if activationState == .activated {
                self?.isActivated = true
                // Try to send any pending sessions
                if let pendingSessions = self?.pendingSessions {
                    print("⌚️ Processing pending sessions after activation")
                    self?.transferSessionsOneByOne(pendingSessions)
                    self?.pendingSessions = nil
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("⌚️ Watch Session reachability changed: \(session.isReachable)")
        // Try to send pending sessions if we become reachable
        if session.isReachable, let pendingSessions = pendingSessions {
            print("⌚️ Attempting to send pending sessions after becoming reachable")
            transferSessionsOneByOne(pendingSessions)
            self.pendingSessions = nil
        }
    }
    
    // Public transfer method
    func transferSessions(_ sessions: [RaceSession]) {
        guard !sessions.isEmpty else {
            print("⌚️ No sessions to transfer")
            return
        }
        
        // Always save to shared defaults as backup
        SharedDefaults.saveSessionsToContainer(sessions)
        
        if isActivated {
            transferSessionsOneByOne(sessions)
        } else {
            print("⌚️ Session not activated yet, queueing transfer")
            pendingSessions = sessions
        }
    }
    
    // Transfer sessions one by one using application context
    private func transferSessionsOneByOne(_ sessions: [RaceSession]) {
        // Reset current index
        currentSessionIndex = 0
        
        // Start the transfer process
        transferNextSession(sessions)
    }
    
    private func transferNextSession(_ sessions: [RaceSession]) {
        guard currentSessionIndex < sessions.count else {
            print("⌚️ All sessions transferred successfully")
            return
        }
        
        queue.async { [weak self] in
            guard let self = self,
                  let session = self.session,
                  session.activationState == .activated else {
                print("⌚️ Watch Session not ready for transfer")
                return
            }
            
            let sessionToTransfer = sessions[self.currentSessionIndex]
            print("⌚️ Transferring session \(self.currentSessionIndex + 1)/\(sessions.count) - Date: \(sessionToTransfer.date)")
            
            do {
                // Convert session to dictionary format
                let sessionDict: [String: Any] = [
                    "id": sessionToTransfer.id,
                    "date": sessionToTransfer.date.timeIntervalSince1970,
                    "countdownDuration": sessionToTransfer.countdownDuration,
                    "raceStartTime": sessionToTransfer.raceStartTime?.timeIntervalSince1970 as Any,
                    "raceDuration": sessionToTransfer.raceDuration as Any,
                    "timeZoneOffset": sessionToTransfer.timeZoneOffset,
                    "sessionIndex": self.currentSessionIndex,
                    "totalSessions": sessions.count
                ]
                
                let applicationContext: [String: Any] = [
                    "singleSession": sessionDict,
                    "timestamp": Date().timeIntervalSince1970 // To ensure context is considered "changed"
                ]
                
                try session.updateApplicationContext(applicationContext)
                print("⌚️ Updated application context with session \(self.currentSessionIndex + 1)")
                
                // Move to next session after a short delay
                self.currentSessionIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.transferNextSession(sessions)
                }
            } catch {
                print("⌚️ Error transferring session \(self.currentSessionIndex + 1): \(error)")
                
                // Try to move to next session despite error
                self.currentSessionIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.transferNextSession(sessions)
                }
            }
        }
    }
}

#else

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession?
    private let queue = DispatchQueue(label: "com.heart.regatta.watchsessionmanager")
    private var isActivated = false
    
    // Track received sessions
    private var receivedSessionsCount = 0
    private var expectedSessionsTotal = 0
    private var receivedSessions: [RaceSession] = []
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("📱 Phone Session initialized and activating...")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("📱 Phone Session activation failed: \(error.localizedDescription)")
                return
            }
            
            print("📱 Phone Session activated with state: \(activationState.rawValue)")
            print("📱 Phone Session isReachable: \(session.isReachable)")
            print("📱 Phone Session isPaired: \(session.isPaired)")
            
            if activationState == .activated {
                self.isActivated = true
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 Phone Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 Phone Session deactivated - reactivating")
        session.activate()
    }
    
    // Handle application context updates (one session at a time)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let sessionDict = applicationContext["singleSession"] as? [String: Any] {
            processReceivedSession(sessionDict)
        }
    }
    
    private func processReceivedSession(_ sessionDict: [String: Any]) {
        guard let id = sessionDict["id"] as? String,
              let dateTimeInterval = sessionDict["date"] as? TimeInterval,
              let countdownDuration = sessionDict["countdownDuration"] as? Int,
              let timeZoneOffset = sessionDict["timeZoneOffset"] as? Int,
              let sessionIndex = sessionDict["sessionIndex"] as? Int,
              let totalSessions = sessionDict["totalSessions"] as? Int else {
            print("📱 Missing required session data")
            return
        }
        
        // Update tracking counters
        expectedSessionsTotal = totalSessions
        
        // Create date objects
        let date = Date(timeIntervalSince1970: dateTimeInterval)
        
        // Handle optional values
        let raceStartTime: Date?
        if let startTimeInterval = sessionDict["raceStartTime"] as? TimeInterval {
            raceStartTime = Date(timeIntervalSince1970: startTimeInterval)
        } else {
            raceStartTime = nil
        }
        
        let raceDuration = sessionDict["raceDuration"] as? TimeInterval
        
        // Create a RaceSession object (without data points for now)
        let session = RaceSession(
            date: date,
            countdownDuration: countdownDuration,
            raceStartTime: raceStartTime,
            raceDuration: raceDuration
        )
        
        print("📱 Received session \(sessionIndex + 1) of \(totalSessions): \(id)")
        
        // Add to our collection
        receivedSessions.append(session)
        receivedSessionsCount += 1
        
        // Check if we've received all expected sessions
        if receivedSessionsCount >= expectedSessionsTotal {
            saveAndNotifyCompletion()
        }
    }
    
    private func saveAndNotifyCompletion() {
        // Archive all received sessions
        if !receivedSessions.isEmpty {
            print("📱 All \(receivedSessions.count) sessions received")
            
            // Save sessions to session archive
            SessionArchiveManager.shared.saveSessionsToArchive(receivedSessions)
            
            // Also save to shared defaults
            SharedDefaults.saveSessionsToContainer(receivedSessions)
            
            // Notify UI to refresh
            NotificationCenter.default.post(
                name: Notification.Name("SessionsUpdatedFromWatch"),
                object: nil
            )
            
            // Reset tracking
            receivedSessionsCount = 0
            expectedSessionsTotal = 0
            receivedSessions.removeAll()
        }
    }
}
#endif
