//
//  iOSSessionStore.swift
//  Regatta
//
//  Created by Chikai Lai on 01/12/2024.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class iOSSessionStore: ObservableObject {
    @Published private(set) var sessions: [RaceSession] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // Add property to track Watch availability
    @Published private(set) var isWatchAvailable = false
    
    private let journalManager = JournalManager.shared
    private let archiveManager = SessionArchiveManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Flag to track if migration has been performed
    private var hasMigrated = false

    static let shared = iOSSessionStore()
    
    private init() {
        print("📱 iOS Store: Initializing")
        
        // Listen for Watch Connectivity updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshSessions),
            name: Notification.Name("SessionsUpdatedFromWatch"),
            object: nil
        )
        
        // Listen for Archive updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshSessions),
            name: Notification.Name("ArchiveUpdated"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateWatchState),
            name: Notification.Name("WatchReachabilityChanged"),
            object: nil
        )
        
        // Setup WatchConnectivity
        _ = WatchSessionManager.shared
        
        // Initialize archive support for Watch connectivity
        #if os(iOS)
        WatchSessionManagerArchiveSetup.initialize()
        #endif
        
        // Initial load
        loadSessions()
        
        // Check watch availability
        updateWatchAvailability()
    }
    
    // Method to check and update Watch availability
    func updateWatchAvailability() {
        let previousState = isWatchAvailable
        isWatchAvailable = WatchSessionManager.shared.isWatchReachable()
        
        // Log state changes
        if previousState != isWatchAvailable {
            print("📱 iOS Store: Watch availability changed from \(previousState) to \(isWatchAvailable)")
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    // Add a method to reset transfer state if stuck
    func resetTransferIfStuck() {
        print("📱 iOS Store: Checking if transfer is stuck")
        WatchSessionManager.shared.resetTransferState()
        
        // Update UI with status
        NotificationCenter.default.post(
            name: Notification.Name("WatchTransferAttempt"),
            object: nil,
            userInfo: ["message": "Reset transfer state - please try refreshing"]
        )
    }
    
    // Add this method to iOSSessionStore
    @objc func updateWatchState(_ notification: Notification) {
        if let isReachable = notification.userInfo?["isReachable"] as? Bool {
            DispatchQueue.main.async {
                self.isWatchAvailable = isReachable
                self.objectWillChange.send()
            }
        } else {
            // Just update normally
            updateWatchAvailability()
        }
    }
    
    @objc func refreshSessions() {
        print("📱 iOS Store: Refreshing sessions")
        
        // Update watch availability
        updateWatchAvailability()
        
        // Request sessions from Watch if available
        if isWatchAvailable {
            print("📱 iOS Store: Watch is available, requesting sessions")
            WatchSessionManager.shared.requestSessionsFromWatch()
            
            // Add a delayed force transfer request as backup
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                WatchSessionManager.shared.requestForceTransfer()
            }
        } else {
            print("📱 iOS Store: Watch is not available")
        }
        
        // Still load local sessions
        loadSessions()
    }
    
    func loadSessions() {
        print("📱 iOS Store: Loading sessions started")
        
        Task { @MainActor in
            isLoading = true
            defer {
                isLoading = false
                objectWillChange.send()  // Explicitly notify observers
            }
            
            // Perform migration if needed (only once per app launch)
            if !hasMigrated {
                archiveManager.migrateExistingSessionsToArchive()
                hasMigrated = true
            }
            
            // Load recent sessions from SharedDefaults
            let recentSessions = SharedDefaults.loadSessionsFromContainer() ?? []
            print("📱 iOS Store: Loaded \(recentSessions.count) recent sessions from UserDefaults")
            
            // Archive any new sessions received
            if !recentSessions.isEmpty {
                archiveManager.saveSessionsToArchive(recentSessions)
            }
            
            // Load all sessions from archive
            let archivedSessions = archiveManager.loadArchivedSessions()
            print("📱 iOS Store: Loaded \(archivedSessions.count) sessions from archive")
            
            // Sort by date (newest first)
            let allSessions = archivedSessions.sorted(by: { $0.date > $1.date })
            
            await MainActor.run {
                self.sessions = allSessions
                self.objectWillChange.send()  // Explicitly notify observers
            }
        }
    }
}
