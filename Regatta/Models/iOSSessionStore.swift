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
    
    private let journalManager = JournalManager.shared
    private var cancellables = Set<AnyCancellable>()

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
        
        // Setup WatchConnectivity
        _ = WatchSessionManager.shared
        
        // Initial load
        loadSessions()
    }
    
    @objc func refreshSessions() {
        print("📱 iOS Store: Refreshing sessions")
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
            
            if let sessions = SharedDefaults.loadSessionsFromContainer() {
                print("📱 iOS Store: Loaded \(sessions.count) sessions")
                await MainActor.run {
                    self.sessions = sessions
                    self.objectWillChange.send()  // Explicitly notify observers
                }
            } else {
                print("📱 iOS Store: No sessions found")
                await MainActor.run {
                    self.sessions = []
                    self.objectWillChange.send()  // Explicitly notify observers
                }
            }
        }
    }
}
