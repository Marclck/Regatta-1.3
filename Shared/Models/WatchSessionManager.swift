//
//  WatchSessionManager.swift
//  Regatta
//
//  Created by Chikai Lai on 21/12/2024.
//

//
//  WatchSessionManager.swift
//  Regatta
//
//  Created by Assistant on 21/12/2024.
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
                    self?.doTransferSessions(pendingSessions)
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
            doTransferSessions(pendingSessions)
            self.pendingSessions = nil
        }
    }
    
    // Public transfer method
    func transferSessions(_ sessions: [RaceSession]) {
        guard !sessions.isEmpty else {
            print("⌚️ No sessions to transfer")
            return
        }
        
        if isActivated {
            doTransferSessions(sessions)
        } else {
            print("⌚️ Session not activated yet, queueing transfer")
            pendingSessions = sessions
        }
    }
    
    // Private transfer implementation
    private func doTransferSessions(_ sessions: [RaceSession]) {
        queue.async { [weak self] in
            guard let self = self,
                  let session = self.session,
                  session.activationState == .activated else {
                print("⌚️ Watch Session not ready for transfer")
                return
            }
            
            print("⌚️ Attempting to transfer sessions...")
            print("⌚️ Session state - Activation: \(session.activationState.rawValue)")
            print("⌚️ Session state - Reachable: \(session.isReachable)")
            
            do {
                let data = try JSONEncoder().encode(sessions)
                let message = ["sessions": data]
                
                if session.isReachable {
                    session.sendMessage(message, replyHandler: { reply in
                        print("⌚️ Sessions sent successfully: \(reply)")
                    }) { error in
                        print("⌚️ Failed to send sessions: \(error.localizedDescription)")
                    }
                } else {
                    print("⌚️ Session not reachable, using application context")
                    try session.updateApplicationContext(message)
                    print("⌚️ Updated application context successfully")
                }
            } catch {
                print("⌚️ Error in transfer: \(error)")
            }
            
            // Always save to shared defaults as backup
            SharedDefaults.saveSessionsToContainer(sessions)
        }
    }
}

#else

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession?
    private let queue = DispatchQueue(label: "com.heart.regatta.watchsessionmanager")
    private var isActivated = false
    
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
            if let sessionData = message["sessions"] as? Data {
                do {
                    let sessions = try JSONDecoder().decode([RaceSession].self, from: sessionData)
                    DispatchQueue.main.async {
                        SharedDefaults.saveSessionsToContainer(sessions)
                        NotificationCenter.default.post(
                            name: Notification.Name("SessionsUpdatedFromWatch"),
                            object: nil
                        )
                    }
                    replyHandler(["status": "success"])
                } catch {
                    print("📱 Failed to decode received sessions: \(error)")
                    replyHandler(["status": "error", "message": error.localizedDescription])
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let sessionData = applicationContext["sessions"] as? Data {
            do {
                let sessions = try JSONDecoder().decode([RaceSession].self, from: sessionData)
                DispatchQueue.main.async {
                    SharedDefaults.saveSessionsToContainer(sessions)
                    NotificationCenter.default.post(
                        name: Notification.Name("SessionsUpdatedFromWatch"),
                        object: nil
                    )
                }
            } catch {
                print("📱 Failed to decode application context sessions: \(error)")
            }
        }
    }
}
#endif
