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
    private var transferStartTime: Date?
    
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
    
    // Send completion message
    private func sendCompletionMessage(wcSession: WCSession) {
        let completionMessage: [String: Any] = [
            "messageType": "transfer_complete",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if wcSession.isReachable {
            // Use a semaphore to wait for the reply
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
                // Only delete sessions if the completion message was confirmed
                print("⌚️ All sessions transferred successfully, cleaning up local storage")
                DispatchQueue.main.async {
                    self.cleanupTransferredSessions()
                }
            } else {
                print("⌚️ Transfer completion not confirmed, keeping sessions for retry")
            }
        } else {
            print("⌚️ Watch not reachable for completion message, will keep sessions for retry")
        }
    }

    // Clean up sessions after successful transfer
    private func cleanupTransferredSessions() {
        // Create a JournalManager reference
        let journalManager = JournalManager.shared
        
        // First, clear the sessions from memory
        journalManager.clearAllSessions() // You'll need to add this method to JournalManager
        
        // Then clear from SharedDefaults
        SharedDefaults.clearSessionsFromContainer()
        
        print("⌚️ Sessions cleared from Watch after successful transfer")
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
                
                // Try to send any pending sessions with a slight delay to ensure activation is complete
                if let pendingSessions = self?.pendingSessions, !(self?.isTransferring ?? true) {
                    print("⌚️ Processing pending sessions after activation")
                    
                    // Use a delay to ensure activation has fully completed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.transferSessionsOneByOne(pendingSessions)
                        self?.pendingSessions = nil
                    }
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("⌚️ Watch Session reachability changed: \(session.isReachable)")
        
        // If we've been transferring for more than 2 minutes, reset the flag
        if let startTime = transferStartTime, Date().timeIntervalSince(startTime) > 120 {
            print("⌚️ Transfer appears to be stuck - resetting transfer state")
            isTransferring = false
            transferStartTime = nil
        }
        
        // Try to send pending sessions if we become reachable
        if session.isReachable, let pendingSessions = pendingSessions, !isTransferring {
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
        
        // Print detailed session and transfer state
        print("⌚️ Transfer requested for \(sessions.count) sessions")
        print("⌚️ Current status - isActivated: \(isActivated), isTransferring: \(isTransferring)")
        
        // Check the actual session state, not just the isActivated flag
        if let session = self.session {
            print("⌚️ Session state: \(session.activationState.rawValue), isReachable: \(session.isReachable)")
            
            // Update isActivated based on actual session state
            if session.activationState == .activated && !isActivated {
                print("⌚️ Session is actually activated but flag wasn't set - fixing")
                isActivated = true
            }
        }
        
        // Check if the transfer has been stuck
        if let startTime = transferStartTime, Date().timeIntervalSince(startTime) > 120 {
            print("⌚️ Previous transfer appears to be stuck - resetting transfer state")
            isTransferring = false
            transferStartTime = nil
        }
        
        if isActivated && !isTransferring {
            print("⌚️ Starting transfer immediately")
            transferSessionsOneByOne(sessions)
        } else {
            print("⌚️ Session not activated yet or transfer in progress, queueing transfer")
            pendingSessions = sessions
            
            // If session exists but isn't activated, try to reactivate
            if let session = self.session, session.activationState != .activated {
                print("⌚️ Attempting to reactivate session")
                session.activate()
            }
        }
    }
    
    // Transfer sessions one by one
    private func transferSessionsOneByOne(_ sessions: [RaceSession]) {
        // Check again if already transferring
        if isTransferring {
            print("⌚️ Transfer already in progress, queueing")
            pendingSessions = sessions
            return
        }
        
        print("⌚️ Beginning to transfer \(sessions.count) sessions one by one...")
        isTransferring = true
        transferStartTime = Date()
        
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
                    
                    // Process any pending sessions that arrived during this transfer
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
        
        // Send the metadata message
        do {
            if wcSession.isReachable {
                let semaphore = DispatchSemaphore(value: 0)
                
                wcSession.sendMessage(messageDict, replyHandler: { reply in
                    print("⌚️ Session \(index+1) metadata sent successfully: \(reply)")
                    semaphore.signal()
                }) { error in
                    print("⌚️ Failed to send session \(index+1) metadata: \(error.localizedDescription)")
                    semaphore.signal()
                }
                
                // Wait with timeout
                _ = semaphore.wait(timeout: .now() + 5.0)
                
                // Add delay between transfers
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                print("⌚️ Watch not reachable, using application context for session \(index+1) metadata")
                try wcSession.updateApplicationContext(messageDict)
                Thread.sleep(forTimeInterval: 1.0)
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
        
        // Transfer in chunks of 100 data points
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
    
    // In WatchSessionManager.swift, iOS section, update the processMessage method
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
            // Forward theme updates to ColorManager via notification
            if let themeString = message["selectedTheme"] as? String,
               let newTheme = ColorTheme(rawValue: themeString) {
                print("📱 Received theme update in WatchSessionManager: \(themeString)")
                DispatchQueue.main.async {
                    // Update the shared defaults directly
                    SharedDefaults.saveTheme(newTheme)
                    
                    // Notify ColorManager
                    NotificationCenter.default.post(
                        name: Notification.Name("ThemeUpdatedFromWatch"),
                        object: nil,
                        userInfo: ["theme": themeString]
                    )
                }
            } else {
                print("📱 Invalid theme update format")
            }
            
        default:
            print("📱 Unknown message type: \(messageType)")
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
        let chunkSize = 100  // Updated to match watch side
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
