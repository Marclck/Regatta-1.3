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
        
        loadSessions()
        
        // Initialize Watch Connectivity
        _ = WatchSessionManager.shared  // Changed from PhoneSessionManager to WatchSessionManager
    }
    
    func loadSessions() {
        print("📱 iOS Store: Loading sessions directly")
        isLoading = true
        sessions = journalManager.allSessions
        print("📱 iOS Store: Direct load complete - sessions count: \(sessions.count)")
        isLoading = false
    }
    
    @objc func refreshSessions() {
        print("📱 iOS Store: Refreshing sessions")
        loadSessions()
    }
}
