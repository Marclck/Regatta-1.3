//
//  WatchSessionManager+Extensions.swift
//  Regatta
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation
import WatchConnectivity

#if os(iOS)
// Extension for iOS only - adds archive support to the existing WatchSessionManager
extension WatchSessionManager {
    
    // Setup archiving observer - called during initialization
    func setupArchiving() {
        // Listen for the notification that sessions have been updated
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(archiveUpdatedSessions),
            name: Notification.Name("SessionsUpdatedFromWatch"),
            object: nil
        )
        
        print("🔄 Archive Extension: Archiving observer set up")
    }
    
    // Archive sessions when we receive the notification
    @objc private func archiveUpdatedSessions() {
        // Load the sessions from SharedDefaults and archive them
        if let sessions = SharedDefaults.loadSessionsFromContainer() {
            print("🔄 Archive Extension: Archiving \(sessions.count) sessions from notification")
            SessionArchiveManager.shared.saveSessionsToArchive(sessions)
            
            // Notify the session store to refresh its data
            DispatchQueue.main.async {
                // Post a custom notification for the archive update
                NotificationCenter.default.post(
                    name: Notification.Name("ArchiveUpdated"),
                    object: nil
                )
            }
        }
    }
}

// Initializer extension to set up archiving when WatchSessionManager is created
extension WatchSessionManager {
    // This will be called when the class is loaded, after the original init
    @objc func setupArchivingSupport() {
        setupArchiving()
    }
}

// Auto-setup for archiving when WatchSessionManager is loaded
class WatchSessionManagerArchiveSetup {
    private static let setup: Void = {
        // Wait a brief moment to ensure the WatchSessionManager has fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WatchSessionManager.shared.setupArchivingSupport()
        }
    }()
    
    static func initialize() {
        _ = setup  // Force the static initializer to run
    }
}
#endif
