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
        print("📱 iOS Store: Initial JournalManager sessions count: \(journalManager.allSessions.count)")
        
        journalManager.$allSessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedSessions in
                print("📱 iOS Store: Received update from JournalManager with \(updatedSessions.count) sessions")
                self?.sessions = updatedSessions
            }
            .store(in: &cancellables)
        
        loadSessions()
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
