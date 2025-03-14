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
    private var isTransferring = false
    
    override init() {
        super.init()
        setupSession()
    }
    
    // Add this method to handle UserInfo messages on watchOS
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("⌚️ Received user info from iOS: \(userInfo)")
        
        // Check if it's a request or command we should handle
        if let messageType = userInfo["messageType"] as? String {
            switch messageType {
            case "request_sessions":
                print("⌚️ Received session request via UserInfo")
                
                if isTransferring {
                    print("⌚️ Transfer already in progress, ignoring request")
                    return
                }
                
                let journalManager = JournalManager.shared
                let sessions = journalManager.allSessions
                
                print("⌚️ iOS requested sessions via UserInfo. Found \(sessions.count) sessions.")
                
                // Send acknowledgment back via direct message or UserInfo
                let ackMessage: [String: Any] = [
                    "messageType": "userinfo_ack",
                    "sessionCount": sessions.count,
                    "status": "success"
                ]
                
                if session.isReachable {
                    session.sendMessage(ackMessage, replyHandler: nil, errorHandler: { _ in
                        // Fall back to UserInfo if message fails
                        session.transferUserInfo(ackMessage)
                    })
                } else {
                    // Use UserInfo if not reachable
                    session.transferUserInfo(ackMessage)
                }
                
                // If we have sessions, start transferring them
                if !sessions.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("⌚️ Starting transfer of \(sessions.count) sessions to iOS (from UserInfo request)")
                        // Force activation flag to true if session is activated
                        if let session = self.session, session.activationState == .activated {
                            self.isActivated = true
                        }
                        // Reset transfer flag if it might be stuck
                        if self.isTransferring {
                            print("⌚️ Resetting stuck transfer flag before starting new transfer")
                            self.isTransferring = false
                        }
                        // Now transfer should work even if previously blocked
                        self.transferSessions(sessions)
                    }
                }
                
            case "ping":
                // Simple ping to check connectivity
                let pongMessage: [String: Any] = [
                    "messageType": "pong",
                    "timestamp": Date().timeIntervalSince1970
                ]
                
                if session.isReachable {
                    session.sendMessage(pongMessage, replyHandler: nil, errorHandler: { _ in
                        // Fall back to UserInfo
                        session.transferUserInfo(pongMessage)
                    })
                } else {
                    session.transferUserInfo(pongMessage)
                }
                
            case "reset_transfer_state":
                print("⌚️ Received request to reset transfer state")
                
                // Reset transfer flags
                isTransferring = false
                transferStartTime = nil
                pendingSessions = nil
                
                // Acknowledge reset
                let resetAckMessage: [String: Any] = [
                    "messageType": "reset_ack",
                    "status": "success",
                    "timestamp": Date().timeIntervalSince1970
                ]
                
                if session.isReachable {
                    session.sendMessage(resetAckMessage, replyHandler: nil, errorHandler: { _ in
                        session.transferUserInfo(resetAckMessage)
                    })
                } else {
                    session.transferUserInfo(resetAckMessage)
                }
                
            case "force_activate_transfer":
                forceActivationAndTransfer()
                
            default:
                print("⌚️ Unknown UserInfo message type: \(messageType)")
            }
        }
    }
    
    // Add this to handle incoming messages from iOS
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("⌚️ Received message from iOS: \(message)")
        
        if let messageType = message["messageType"] as? String {
            switch messageType {
            case "request_sessions":
                handleSessionRequest(replyHandler: replyHandler)
            case "force_activate_transfer":
                forceActivationAndTransfer()
                replyHandler(["status": "success", "message": "Force activation attempted"])
            default:
                print("⌚️ Unknown message type: \(messageType)")
                replyHandler(["status": "error", "message": "Unknown message type"])
            }
        } else {
            print("⌚️ Invalid message format: no messageType")
            replyHandler(["status": "error", "message": "Invalid message format"])
        }
    }

    // Add helper method to handle session requests
    private func handleSessionRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        // If already transferring, reject new requests
        if isTransferring {
            print("⌚️ Transfer already in progress, rejecting new request")
            replyHandler([
                "status": "busy",
                "message": "Transfer already in progress"
            ])
            return
        }
        
        // Get all available sessions from JournalManager
        let journalManager = JournalManager.shared
        let sessions = journalManager.allSessions
        
        print("⌚️ iOS requested sessions transfer. Found \(sessions.count) sessions.")
        
        // Reply with session count
        replyHandler([
            "status": "success",
            "sessionCount": sessions.count,
            "message": "Initiating transfer of \(sessions.count) sessions"
        ])
        
        // If we have sessions, start transferring them
        if !sessions.isEmpty {
            // Use slight delay to ensure the reply handler has completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("⌚️ Starting transfer of \(sessions.count) sessions to iOS")
                self.transferSessions(sessions)
            }
        }
    }

    // Add method to force activation and handle stuck transfers
    func forceActivationAndTransfer() {
        print("⌚️ Force activation and transfer attempt - AGGRESSIVE RESET")
        
        // ALWAYS reset transfer flag when force is called
        if isTransferring {
            print("⌚️ Force resetting transfer state")
            isTransferring = false
            transferStartTime = nil
        }
        
        // Check and fix session activation state
        if let session = self.session {
            print("⌚️ Current session state: \(session.activationState.rawValue), isReachable: \(session.isReachable)")
            
            // Force activation flag to match session state
            if session.activationState == .activated {
                print("⌚️ Ensuring activation flag matches session state")
                isActivated = true
            }
            
            // Try to activate if needed
            if session.activationState != .activated {
                print("⌚️ Attempting to activate session")
                session.activate()
            }
            
            // Send status
            let statusMessage: [String: Any] = [
                "messageType": "transfer_status",
                "message": "Watch preparing for session transfer..."
            ]
            
            if session.isReachable {
                session.sendMessage(statusMessage, replyHandler: nil, errorHandler: { _ in
                    session.transferUserInfo(statusMessage)
                })
            } else {
                session.transferUserInfo(statusMessage)
            }
        }
        
        // Get sessions to transfer
        let journalManager = JournalManager.shared
        let sessions = journalManager.allSessions
        
        // If we have sessions, force a new transfer ignoring any pending queue
        if !sessions.isEmpty {
            print("⌚️ Force initiating transfer of \(sessions.count) sessions")
            // Use delay to ensure state reset is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Clear any pending queue first
                self.pendingSessions = nil
                // Start fresh transfer
                self.transferSessionsOneByOne(sessions)
                
                // Send count
                if let session = self.session {
                    let countMessage: [String: Any] = [
                        "messageType": "transfer_status",
                        "message": "Transferring \(sessions.count) sessions..."
                    ]
                    
                    if session.isReachable {
                        session.sendMessage(countMessage, replyHandler: nil, errorHandler: { _ in
                            session.transferUserInfo(countMessage)
                        })
                    } else {
                        session.transferUserInfo(countMessage)
                    }
                }
            }
        } else {
            print("⌚️ No sessions available to transfer")
            
            // Send status
            if let session = self.session {
                let noSessionsMessage: [String: Any] = [
                    "messageType": "transfer_status",
                    "message": "No sessions available on Watch"
                ]
                
                if session.isReachable {
                    session.sendMessage(noSessionsMessage, replyHandler: nil, errorHandler: { _ in
                        session.transferUserInfo(noSessionsMessage)
                    })
                } else {
                    session.transferUserInfo(noSessionsMessage)
                }
            }
        }
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
                if let pendingSessions = self?.pendingSessions, !(self?.isTransferring ?? true) {
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
        if session.isReachable, let pendingSessions = pendingSessions, !isTransferring {
            print("⌚️ Attempting to send pending sessions after becoming reachable")
            transferSessionsOneByOne(pendingSessions)
            self.pendingSessions = nil
        }
    }
    
    // Add this property to track when a transfer started
    private var transferStartTime: Date?

    // Update the transferSessions method to handle potentially stuck state
    func transferSessions(_ sessions: [RaceSession]) {
        guard !sessions.isEmpty else {
            print("⌚️ No sessions to transfer")
            return
        }
        
        // Always save to shared defaults as backup
        SharedDefaults.saveSessionsToContainer(sessions)
        
        // Check if transfer appears to be stuck
        if isTransferring, let startTime = transferStartTime {
            let stuckDuration = Date().timeIntervalSince(startTime)
            print("⌚️ Current transfer running for \(Int(stuckDuration)) seconds")
            
            if stuckDuration > 30 {  // Consider stuck after 30 seconds with no completion
                print("⌚️ Detected stuck transfer - resetting transfer state")
                isTransferring = false
                transferStartTime = nil
            }
        }
        
        // Ensure activation flag matches actual session state
        if let session = self.session, session.activationState == .activated {
            isActivated = true
        }
        
        if isActivated && !isTransferring {
            transferSessionsOneByOne(sessions)
        } else {
            print("⌚️ Session not activated yet or transfer in progress, queueing transfer")
            pendingSessions = sessions
        }
    }
    
    // Transfer sessions one by one
    // Update the transferSessionsOneByOne method to track start and end times
    private func transferSessionsOneByOne(_ sessions: [RaceSession]) {
        guard !isTransferring else {
            print("⌚️ Transfer already in progress, queueing")
            pendingSessions = sessions
            return
        }
        
        print("⌚️ Beginning to transfer \(sessions.count) sessions one by one...")
        isTransferring = true
        transferStartTime = Date()  // Track when this transfer started
        
        queue.async { [weak self] in
            guard let self = self,
                  let session = self.session,
                  session.activationState == .activated else {
                DispatchQueue.main.async {
                    self?.isTransferring = false
                    self?.transferStartTime = nil
                    print("⌚️ Watch Session not ready for transfer, resetting transfer state")
                }
                return
            }
            
            // Use defer to ensure cleanup happens even if there's an error
            defer {
                DispatchQueue.main.async {
                    self.isTransferring = false
                    self.transferStartTime = nil
                    print("⌚️ Transfer complete, reset transfer state")
                    
                    // If there are pending sessions, process them now
                    if let pending = self.pendingSessions {
                        print("⌚️ Processing \(pending.count) pending sessions")
                        self.pendingSessions = nil
                        self.transferSessionsOneByOne(pending)
                    }
                }
            }
            
            // Process each session individually
            for (index, raceSession) in sessions.enumerated() {
                autoreleasepool {
                    // First, send session metadata (without dataPoints)
                    self.transferSessionMetadata(raceSession, index: index, total: sessions.count, wcSession: session)
                    
                    // Then, transfer data points in chunks if there are any
                    if !raceSession.dataPoints.isEmpty {
                        self.transferDataPoints(for: raceSession.id, dataPoints: raceSession.dataPoints, wcSession: session)
                    }
                }
            }
            
            // Send a completion message
            self.sendCompletionMessage(wcSession: session)
            
            print("⌚️ Completed transferring all sessions")
        }
    }
    
    // Send session metadata (everything except dataPoints)
    private func transferSessionMetadata(_ raceSession: RaceSession, index: Int, total: Int, wcSession: WCSession) {
        print("⌚️ Preparing session \(index+1)/\(total) metadata for transfer")
        
        // Create a dictionary with session metadata
        let sessionDict: [String: Any] = [
            "messageType": "session_metadata",
            "id": raceSession.id,
            "date": raceSession.date.timeIntervalSince1970,
            "countdownDuration": raceSession.countdownDuration,
            "raceStartTime": raceSession.raceStartTime?.timeIntervalSince1970 as Any,
            "raceDuration": raceSession.raceDuration as Any,
            "timeZoneOffset": raceSession.timeZoneOffset,
            "dataPointsCount": raceSession.dataPoints.count,
            "sessionIndex": index,
            "totalSessions": total
        ]
        
        // Add left/right points if available
        var messageDict = sessionDict
        
        if let leftPoint = raceSession.leftPoint {
            messageDict["leftPoint"] = [
                "latitude": leftPoint.latitude,
                "longitude": leftPoint.longitude,
                "accuracy": leftPoint.accuracy
            ]
        }
        
        if let rightPoint = raceSession.rightPoint {
            messageDict["rightPoint"] = [
                "latitude": rightPoint.latitude,
                "longitude": rightPoint.longitude,
                "accuracy": rightPoint.accuracy
            ]
        }
        
        // Try to send status update via UserInfo as well
        let statusMessage: [String: Any] = [
            "messageType": "transfer_status",
            "message": "Transferring session \(index+1) of \(total)..."
        ]
        wcSession.transferUserInfo(statusMessage)
        
        // Send the metadata message
        do {
            if wcSession.isReachable {
                let semaphore = DispatchSemaphore(value: 0)
                var sendSuccess = false
                
                wcSession.sendMessage(messageDict, replyHandler: { reply in
                    print("⌚️ Session \(index+1) metadata sent successfully: \(reply)")
                    sendSuccess = true
                    semaphore.signal()
                }) { error in
                    print("⌚️ Failed to send session \(index+1) metadata: \(error.localizedDescription)")
                    semaphore.signal()
                }
                
                // Wait with timeout
                _ = semaphore.wait(timeout: .now() + 5.0)
                
                // If direct message failed, try userInfo as fallback
                if !sendSuccess {
                    print("⌚️ Falling back to transferUserInfo for session metadata")
                    wcSession.transferUserInfo(messageDict)
                }
                
                // Add delay between transfers
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                // Use transferUserInfo as fallback when not reachable
                print("⌚️ Watch not reachable, using transferUserInfo for metadata")
                wcSession.transferUserInfo(messageDict)
                Thread.sleep(forTimeInterval: 0.5)
            }
        } catch {
            print("⌚️ Error sending session \(index+1) metadata: \(error.localizedDescription)")
        }
    }
    
    // Transfer data points in chunks
    private func transferDataPoints(for sessionId: String, dataPoints: [DataPoint], wcSession: WCSession) {
        // Skip if no data points
        if dataPoints.isEmpty {
            print("⌚️ No data points to transfer for session \(sessionId)")
            return
        }
        
        print("⌚️ Transferring \(dataPoints.count) data points for session \(sessionId)")
        
        // Transfer in chunks of 20 data points
        let chunkSize = 100
        let chunksCount = Int(ceil(Double(dataPoints.count) / Double(chunkSize)))
        
        for chunkIndex in 0..<chunksCount {
            autoreleasepool {
                // Calculate start and end indices for this chunk
                let startIndex = chunkIndex * chunkSize
                let endIndex = min(startIndex + chunkSize, dataPoints.count)
                let chunk = Array(dataPoints[startIndex..<endIndex])
                
                // Convert data points to dictionaries
                var dataPointDicts: [[String: Any]] = []
                
                for dp in chunk {
                    var dpDict: [String: Any] = [
                        "timestamp": dp.timestamp.timeIntervalSince1970
                    ]
                    
                    if let heartRate = dp.heartRate {
                        dpDict["heartRate"] = heartRate
                    }
                    
                    if let speed = dp.speed {
                        dpDict["speed"] = speed
                    }
                    
                    if let location = dp.location {
                        dpDict["location"] = [
                            "latitude": location.latitude,
                            "longitude": location.longitude,
                            "accuracy": location.accuracy
                        ]
                    }
                    
                    dataPointDicts.append(dpDict)
                }
                
                // Create message with chunk data
                let message: [String: Any] = [
                    "messageType": "data_points",
                    "sessionId": sessionId,
                    "chunkIndex": chunkIndex,
                    "totalChunks": chunksCount,
                    "startIndex": startIndex,
                    "endIndex": endIndex,
                    "dataPoints": dataPointDicts
                ]
                
                // Send the chunk
                if wcSession.isReachable {
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    wcSession.sendMessage(message, replyHandler: { reply in
                        print("⌚️ Data points chunk \(chunkIndex+1)/\(chunksCount) sent successfully: \(reply)")
                        semaphore.signal()
                    }) { error in
                        print("⌚️ Failed to send data points chunk \(chunkIndex+1): \(error.localizedDescription)")
                        semaphore.signal()
                    }
                    
                    // Wait with timeout
                    _ = semaphore.wait(timeout: .now() + 5.0)
                    
                    // Add delay between transfers
                    Thread.sleep(forTimeInterval: 0.3)
                } else {
                    print("⌚️ Watch not reachable for data points chunk \(chunkIndex+1)")
                    // Cannot use updateApplicationContext here as we need to ensure order
                    // Just skip and continue
                }
            }
        }
        
        print("⌚️ Completed transferring all data points for session \(sessionId)")
    }
    
    // Send completion message
    private func sendCompletionMessage(wcSession: WCSession) {
        let completionMessage: [String: Any] = [
            "messageType": "transfer_complete",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if wcSession.isReachable {
            let semaphore = DispatchSemaphore(value: 0)
            var transferSuccessful = false
            
            wcSession.sendMessage(completionMessage, replyHandler: { reply in
                print("⌚️ Transfer completion message sent successfully: \(reply)")
                if let status = reply["status"] as? String, status == "success" {
                    transferSuccessful = true
                }
                semaphore.signal()
            }) { error in
                print("⌚️ Failed to send completion message: \(error.localizedDescription)")
                semaphore.signal()
            }
            
            // Wait with timeout
            let result = semaphore.wait(timeout: .now() + 5.0)
            
            if result == .success && transferSuccessful {
                // Clean up after successful transfer
                DispatchQueue.main.async {
                    print("⌚️ Transfer confirmed complete, cleaning up sessions")
                    // Clear all sessions from JournalManager
                    JournalManager.shared.clearAllSessions()
                    // Clear from SharedDefaults
                    SharedDefaults.clearSessionsFromContainer()
                }
            }
        }
    }
    
    // Add this method to WatchSessionManager
    func sendThemeUpdate(theme: ColorTheme) {
        guard let session = self.session, session.activationState == .activated else {
            print("⌚️ Session not activated, can't send theme")
            return
        }
        
        let message: [String: Any] = [
            "messageType": "theme_update",
            "selectedTheme": theme.rawValue
        ]
        
        queue.async {
            if session.isReachable {
                // Use sendMessage with reply handler
                session.sendMessage(message, replyHandler: { reply in
                    print("⌚️ Theme sent successfully to phone: \(reply)")
                }) { error in
                    print("⌚️ Error sending theme to phone: \(error.localizedDescription)")
                    
                    // Try again without reply handler as fallback
                    session.sendMessage(message, replyHandler: nil)
                    print("⌚️ Attempted to send theme without reply handler as fallback")
                }
            } else {
                // Use transferUserInfo instead of applicationContext
                let userInfoTransfer = session.transferUserInfo(message)
                print("⌚️ Phone not reachable, queued theme update via userInfo transfer: \(userInfoTransfer.isTransferring)")
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
    
    // Keep track of received session data
    private var receivingSessionsData: [String: ReceivedSessionData] = [:]
    
    // Struct to track received session data
    private struct ReceivedSessionData {
        var metadata: [String: Any]
        var dataPoints: [DataPoint]
        var receivedChunks: Set<Int>
        var totalChunks: Int
        var isComplete: Bool {
            return receivedChunks.count == totalChunks
        }
    }
    
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
    
    // Add to iOS side of WatchSessionManager

    // This method should be added to the iOS side WatchSessionManager class
    func resetTransferState() {
        print("📱 Manually resetting transfer state")
        
        // Notify Watch to reset its state
        if let session = self.session, session.activationState == .activated {
            let resetMessage: [String: Any] = [
                "messageType": "reset_transfer_state",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            // Try message first
            if session.isReachable {
                session.sendMessage(resetMessage, replyHandler: { reply in
                    print("📱 Watch acknowledged transfer state reset: \(reply)")
                }, errorHandler: { error in
                    print("📱 Failed to send reset command: \(error.localizedDescription)")
                    // Try UserInfo as fallback
                    session.transferUserInfo(resetMessage)
                })
            } else {
                // Use UserInfo if not reachable
                session.transferUserInfo(resetMessage)
            }
        }
        
        // Reset local transfer tracking state
        receivingSessionsData.removeAll()
        
        // Force a reactivation of the session
        if let session = self.session {
            if session.activationState != .activated {
                session.activate()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        print("📱 Phone Session reachability changed: \(isReachable)")
        
        // Notify UI of reachability change
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("WatchReachabilityChanged"),
                object: nil,
                userInfo: ["isReachable": isReachable]
            )
        }
        
        // If now reachable, check for any pending session updates
        if isReachable {
            print("📱 Watch became reachable, checking for sessions")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestSessionsFromWatch()
            }
        }
    }
    
    // New method to force reachability update
    func forceReachabilityUpdate() {
        // This will trigger a re-evaluation of isReachable
        if let session = self.session, session.activationState == .activated {
            print("📱 Force updating reachability: current state is \(session.isReachable)")
            
            // Try to wake up the counterpart app
            session.sendMessage(["messageType": "ping"], replyHandler: { reply in
                print("📱 Watch is responsive to ping: \(reply)")
                // Force a reachability update notification
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("WatchReachabilityChanged"),
                        object: nil,
                        userInfo: ["isReachable": true]
                    )
                }
            }, errorHandler: { error in
                print("📱 Watch ping failed: \(error.localizedDescription)")
            })
        } else {
            print("📱 Session not activated, cannot force reachability update")
        }
    }

    
    // Request forced activation and transfer from Watch
    func requestForceTransfer() {
        guard let session = self.session else {
            print("📱 No session available for force transfer request")
            return
        }
        
        print("📱 FORCING TRANSFER - session state: \(session.activationState.rawValue), reachable: \(session.isReachable)")
        
        // Try to activate if needed
        if session.activationState != .activated {
            print("📱 Attempting to activate iOS session")
            session.activate()
            
            // Give it a moment to activate
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sendForceTransferMessage()
            }
            return
        }
        
        sendForceTransferMessage()
    }
    
    // Check if Watch is reachable
    func isWatchReachable() -> Bool {
        guard let session = self.session else { return false }
        
        let activationOK = session.activationState == .activated
        let reachableOK = session.isReachable
        
        print("📱 Watch reachability check - activated: \(activationOK), reachable: \(reachableOK)")
        
        // Even if not flagged as reachable, check if paired and installed
        if activationOK && !reachableOK && session.isPaired {
            print("📱 Watch is paired and app installed but not flagged reachable - may still respond")
            // Try to force a reachability update but don't block on it
            DispatchQueue.main.async {
                self.forceReachabilityUpdate()
            }
            
            // Return true if paired and installed, we'll attempt transfer anyway
            return true
        }
        
        return activationOK && reachableOK
    }

    private var lastRequestTime: Date?
    private let requestCooldown: TimeInterval = 3.0 // 3 seconds cooldown
    
    // Request sessions from Watch
    func requestSessionsFromWatch() {
        // Check if we're in cooldown period
        if let lastTime = lastRequestTime, Date().timeIntervalSince(lastTime) < requestCooldown {
            print("📱 Request cooldown active, please wait")
            return
        }
        
        guard let session = self.session, session.activationState == .activated else {
            print("📱 Session not activated, cannot request sessions")
            return
        }
        
        // Update last request time
        lastRequestTime = Date()
        
        // IMPORTANT: Try even if not flagged as reachable
        let isReachable = session.isReachable
        print("📱 Requesting sessions - session reachable: \(isReachable), attempting anyway")
        
        // Send request message to Watch
        let message: [String: Any] = [
            "messageType": "request_sessions",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Try with replyHandler first
        session.sendMessage(message, replyHandler: { reply in
            print("📱 Watch acknowledged session request: \(reply)")
            
            // Update UI to show watch is actually reachable
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("WatchReachabilityChanged"),
                    object: nil,
                    userInfo: ["isReachable": true]
                )
            }
            
            // If watch reports it's busy, respect that
            if let status = reply["status"] as? String, status == "busy" {
                print("📱 Watch is busy with another transfer, will try later")
            }
        }, errorHandler: { error in
            print("📱 Failed to request sessions from Watch: \(error.localizedDescription)")
            
            // If direct message fails, try using transferUserInfo as fallback
            print("📱 Trying fallback method via transferUserInfo")
            let transfer = session.transferUserInfo(message)
            
            // Show status in UI
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("WatchTransferAttempt"),
                    object: nil,
                    userInfo: ["message": "Using fallback transfer method..."]
                )
            }
            
            print("📱 Fallback transfer queued: \(transfer.isTransferring)")
        })
    }

    
    private func sendForceTransferMessage() {
        guard let session = self.session, session.activationState == .activated else {
            print("📱 Session not activated, cannot force transfer")
            return
        }
        
        if session.isReachable {
            let message: [String: Any] = [
                "messageType": "force_activate_transfer",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            // Before sending message, tell iOS user we're trying
            NotificationCenter.default.post(
                name: Notification.Name("WatchTransferAttempt"),
                object: nil,
                userInfo: ["message": "Attempting to force session transfer..."]
            )
            
            session.sendMessage(message, replyHandler: { reply in
                print("📱 Force transfer request sent: \(reply)")
                
                // Notify listeners of attempt outcome
                NotificationCenter.default.post(
                    name: Notification.Name("WatchTransferAttempt"),
                    object: nil,
                    userInfo: ["message": "Force transfer requested ✓"]
                )
            }) { error in
                print("📱 Failed to send force transfer request: \(error.localizedDescription)")
                
                // Notify listeners of failure
                NotificationCenter.default.post(
                    name: Notification.Name("WatchTransferAttempt"),
                    object: nil,
                    userInfo: ["message": "Force transfer failed: \(error.localizedDescription)"]
                )
            }
        } else {
            print("📱 Watch not reachable for force transfer request")
            
            // Notify listeners that Watch is unreachable
            NotificationCenter.default.post(
                name: Notification.Name("WatchTransferAttempt"),
                object: nil,
                userInfo: ["message": "Watch is not reachable. Please open the Watch app."]
            )
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
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        queue.async {
            print("📱 Received user info from Watch: \(userInfo)")
            
            // Handle session transfer status updates
            if let messageType = userInfo["messageType"] as? String,
               messageType == "transfer_status" {
                // Show status update in UI
                if let statusMessage = userInfo["message"] as? String {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: Notification.Name("WatchTransferAttempt"),
                            object: nil,
                            userInfo: ["message": statusMessage]
                        )
                    }
                }
            } else {
                // Process other messages as normal
                self.processMessage(userInfo)
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        queue.async {
            print("📱 Received message from Watch")
            
            // Special handling for completion message
            if let messageType = message["messageType"] as? String, messageType == "transfer_complete" {
                print("📱 Received transfer completion message from Watch")
                self.processMessage(message)
                
                // Send confirmation that it's safe to delete sessions on the Watch
                replyHandler(["status": "success", "message": "All sessions received and processed"])
            } else {
                // Normal handling for other messages
                self.processMessage(message)
                replyHandler(["status": "success", "timestamp": Date().timeIntervalSince1970])
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        queue.async {
            print("📱 Received application context from Watch")
            self.processMessage(applicationContext)
        }
    }
    
    // Process incoming messages
    private func processMessage(_ message: [String: Any]) {
        guard let messageType = message["messageType"] as? String else {
            print("📱 Invalid message format: no messageType")
            return
        }
        
        switch messageType {
        case "session_metadata":
            processSessionMetadata(message)
            
        case "data_points":
            processDataPoints(message)
            
        case "transfer_complete":
            processTransferCompletion()
            
        case "theme_update":
            processThemeUpdate(message)
            
        default:
            print("📱 Unknown message type: \(messageType)")
        }
    }

    // Add this new method
    private func processThemeUpdate(_ message: [String: Any]) {
        guard let themeString = message["selectedTheme"] as? String else {
            print("📱 Theme update missing selectedTheme value")
            return
        }
        
        // Handle the # prefix if present
        let normalizedThemeString = themeString.hasPrefix("#") ? String(themeString.dropFirst()) : themeString
        
        if let newTheme = ColorTheme(rawValue: normalizedThemeString) ?? ColorTheme(rawValue: themeString) {
            DispatchQueue.main.async {
                print("📱 Setting theme to: \(newTheme.name)")
                ColorManager.shared.selectedTheme = newTheme
                
                // Post notification when theme is updated
                NotificationCenter.default.post(
                    name: Notification.Name("ThemeUpdatedFromWatch"),
                    object: nil
                )
            }
        } else {
            print("📱 Invalid theme value: \(themeString)")
            print("📱 Available theme values: \(ColorTheme.allCases.map { $0.rawValue })")
        }
    }
    
    // Process session metadata
    private func processSessionMetadata(_ message: [String: Any]) {
        guard let sessionId = message["id"] as? String else {
            print("📱 Invalid session metadata: no id")
            return
        }
        
        print("📱 Received metadata for session: \(sessionId)")
        
        // If we're already receiving this session, clear existing data
        if receivingSessionsData[sessionId] != nil {
            print("📱 Clearing existing data for session: \(sessionId)")
            receivingSessionsData[sessionId] = nil
        }
        
        // Get data points count
        guard let dataPointsCount = message["dataPointsCount"] as? Int else {
            print("📱 Missing dataPointsCount in metadata")
            return
        }
        
        // Calculate expected chunks
        let chunkSize = 20
        let totalChunks = dataPointsCount > 0 ? Int(ceil(Double(dataPointsCount) / Double(chunkSize))) : 0
        
        // Store metadata
        receivingSessionsData[sessionId] = ReceivedSessionData(
            metadata: message,
            dataPoints: [],
            receivedChunks: Set<Int>(),
            totalChunks: totalChunks
        )
        
        print("📱 Initialized session \(sessionId) with \(dataPointsCount) expected data points in \(totalChunks) chunks")
        
        // If no data points expected, complete this session immediately
        if dataPointsCount == 0 {
            print("📱 No data points expected for session \(sessionId), completing")
            completeSession(sessionId)
        }
    }
    
    // Process data points chunk
    private func processDataPoints(_ message: [String: Any]) {
        guard let sessionId = message["sessionId"] as? String,
              let chunkIndex = message["chunkIndex"] as? Int,
              let totalChunks = message["totalChunks"] as? Int,
              let startIndex = message["startIndex"] as? Int,
              let endIndex = message["endIndex"] as? Int,
              let dataPointsArray = message["dataPoints"] as? [[String: Any]] else {
            print("📱 Invalid data points message format")
            return
        }
        
        print("📱 Received data points chunk \(chunkIndex+1)/\(totalChunks) for session \(sessionId)")
        
        // Check if we have metadata for this session
        guard var sessionData = receivingSessionsData[sessionId] else {
            print("📱 Received data points for unknown session: \(sessionId)")
            return
        }
        
        // Check if we already processed this chunk
        if sessionData.receivedChunks.contains(chunkIndex) {
            print("📱 Duplicate chunk \(chunkIndex+1), skipping")
            return
        }
        
        // Parse data points
        var parsedDataPoints: [DataPoint] = []
        
        for dpDict in dataPointsArray {
            guard let timestampValue = dpDict["timestamp"] as? TimeInterval else {
                print("📱 Data point missing timestamp, skipping")
                continue
            }
            
            let timestamp = Date(timeIntervalSince1970: timestampValue)
            let heartRate = dpDict["heartRate"] as? Int
            let speed = dpDict["speed"] as? Double
            
            var locationData: LocationData? = nil
            if let locationDict = dpDict["location"] as? [String: Any],
               let latitude = locationDict["latitude"] as? Double,
               let longitude = locationDict["longitude"] as? Double,
               let accuracy = locationDict["accuracy"] as? Double {
                locationData = LocationData(
                    latitude: latitude,
                    longitude: longitude,
                    accuracy: accuracy
                )
            }
            
            let dataPoint = DataPoint(
                timestamp: timestamp,
                heartRate: heartRate,
                speed: speed,
                location: locationData
            )
            
            parsedDataPoints.append(dataPoint)
        }
        
        // Ensure our data points array is large enough
        while sessionData.dataPoints.count < endIndex {
            sessionData.dataPoints.append(contentsOf: Array(repeating: DataPoint(timestamp: Date(), heartRate: nil, speed: nil, location: nil), count: endIndex - sessionData.dataPoints.count))
        }
        
        // Place data points at correct indices
        for i in 0..<parsedDataPoints.count {
            let targetIndex = startIndex + i
            if targetIndex < sessionData.dataPoints.count {
                sessionData.dataPoints[targetIndex] = parsedDataPoints[i]
            }
        }
        
        // Mark chunk as received
        sessionData.receivedChunks.insert(chunkIndex)
        sessionData.totalChunks = totalChunks // Update in case it changed
        
        // Update session data
        receivingSessionsData[sessionId] = sessionData
        
        print("📱 Processed chunk \(chunkIndex+1)/\(totalChunks) for session \(sessionId)")
        
        // Check if session is complete
        if sessionData.isComplete {
            print("📱 All chunks received for session \(sessionId), completing")
            completeSession(sessionId)
        }
    }
    
    // Complete a session when all chunks received
    private func completeSession(_ sessionId: String) {
        guard let sessionData = receivingSessionsData[sessionId] else {
            print("📱 Cannot complete unknown session: \(sessionId)")
            return
        }
        
        let metadata = sessionData.metadata
        let dataPoints = sessionData.dataPoints
        
        guard let dateTimeInterval = metadata["date"] as? TimeInterval,
              let countdownDuration = metadata["countdownDuration"] as? Int,
              let timeZoneOffset = metadata["timeZoneOffset"] as? Int else {
            print("📱 Missing required session data for \(sessionId)")
            return
        }
        
        // Create session
        let date = Date(timeIntervalSince1970: dateTimeInterval)
        
        // Optional values
        let raceStartTime: Date?
        if let startTimeInterval = metadata["raceStartTime"] as? TimeInterval {
            raceStartTime = Date(timeIntervalSince1970: startTimeInterval)
        } else {
            raceStartTime = nil
        }
        
        let raceDuration = metadata["raceDuration"] as? TimeInterval
        
        // Parse left/right points if present
        var leftPoint: LocationData? = nil
        if let leftDict = metadata["leftPoint"] as? [String: Any],
           let latitude = leftDict["latitude"] as? Double,
           let longitude = leftDict["longitude"] as? Double,
           let accuracy = leftDict["accuracy"] as? Double {
            leftPoint = LocationData(
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy
            )
        }
        
        var rightPoint: LocationData? = nil
        if let rightDict = metadata["rightPoint"] as? [String: Any],
           let latitude = rightDict["latitude"] as? Double,
           let longitude = rightDict["longitude"] as? Double,
           let accuracy = rightDict["accuracy"] as? Double {
            rightPoint = LocationData(
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy
            )
        }
        
        // Create the session with all data
        let session = RaceSession(
            date: date,
            countdownDuration: countdownDuration,
            raceStartTime: raceStartTime,
            raceDuration: raceDuration,
            dataPoints: dataPoints,
            leftPoint: leftPoint,
            rightPoint: rightPoint
        )
        
        print("📱 Session \(sessionId) completed with \(dataPoints.count) data points")
        
        // Save to archive
        DispatchQueue.main.async {
            SessionArchiveManager.shared.saveSessionsToArchive([session])
            
            // No need to notify until all transfers complete
            // We'll do that in processTransferCompletion
        }
        
        // Clean up the data
        receivingSessionsData.removeValue(forKey: sessionId)
    }
    
    // Process transfer completion
    private func processTransferCompletion() {
        print("📱 Transfer completion received")
        
        // Check if any sessions are still incomplete
        let incompleteSessionIds = receivingSessionsData.filter { !$0.value.isComplete }.keys
        
        for sessionId in incompleteSessionIds {
            print("📱 Completing incomplete session: \(sessionId)")
            completeSession(sessionId)
        }
        
        // Clear all cached data
        receivingSessionsData.removeAll()
        
        // Notify UI
        DispatchQueue.main.async {
            print("📱 All sessions processed, notifying listeners")
            NotificationCenter.default.post(
                name: Notification.Name("SessionsUpdatedFromWatch"),
                object: nil
            )
        }
    }
}
#endif
