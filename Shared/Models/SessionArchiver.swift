//
//  SessionArchiver.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation
import SwiftUI

/**
 SessionArchiver works alongside the existing JournalManager to archive older sessions
 to JSON storage while maintaining the same UserDefaults-based data flow for current sessions.
 */
class SessionArchiver: ObservableObject {
    // MARK: - Singleton Instance
    static let shared = SessionArchiver()
    
    // MARK: - Properties
    private let database = JSONSessionDatabase.shared
    
    // Published properties for UI updates
    @Published var isArchiving = false
    @Published var lastArchiveDate: Date?
    @Published var archivedSessionCount: Int = 0
    
    // MARK: - Initialization
    private init() {
        print("📚 SessionArchiver: Initializing")
        
        // Check archive on startup
        checkAndArchiveOldSessions()
        
        // Add observer for when sessions are updated
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkAndArchiveOldSessions),
            name: Notification.Name("SessionsUpdatedFromWatch"),
            object: nil
        )
    }
    
    // MARK: - Archiving Methods
    
    func archiveSpecificSessions(_ sessions: [RaceSession]) {
        print("📚 SessionArchiver: Archiving \(sessions.count) specific sessions")
        
        // Archive only the specified sessions
        database.archiveNewSessions(sessions)
        
        // Update UI state
        lastArchiveDate = Date()
        archivedSessionCount = database.loadArchivedSessions().count
        objectWillChange.send()
    }
    
    @objc func checkAndArchiveOldSessions() {
        // Don't interrupt the data flow - just archive old sessions
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isArchiving = true
            }
            
            // Archive sessions keeping the 10 most recent in UserDefaults
            self.database.archiveOldSessions(keepRecentCount: 10)
            
            // Update UI state
            DispatchQueue.main.async {
                self.isArchiving = false
                self.lastArchiveDate = Date()
                self.archivedSessionCount = self.database.loadArchivedSessions().count
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Access Methods
    
    /// Gets all sessions from both active and archived storage
    func getAllSessions() -> [RaceSession] {
        return database.getAllSessions()
    }
    
    /// Exports all sessions (both active and archived) as a JSON file
    func exportAllSessions() -> URL? {
        do {
            let allSessions = getAllSessions()
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let data = try encoder.encode(allSessions)
            
            let exportURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("regatta_sessions_export_\(Date().timeIntervalSince1970).json")
            
            try data.write(to: exportURL)
            return exportURL
        } catch {
            print("📚 Error exporting sessions: \(error)")
            return nil
        }
    }
    
    /// Imports sessions from a JSON file
    func importSessions(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            let importedSessions = try decoder.decode([RaceSession].self, from: data)
            
            // Add to archive
            database.archiveNewSessions(importedSessions)
            
            return true
        } catch {
            print("📚 Error importing sessions: \(error)")
            return false
        }
    }
    
    /// Delete a session from both active and archived storage
    func deleteSession(withID id: String) -> Bool {
        return database.deleteSession(withID: id)
    }
}

extension SessionArchiver {
    
    // Direct method to archive specific sessions without waiting for notification
    func archiveCurrentSessions(_ sessions: [RaceSession]) {
        print("📚 SessionArchiver: Directly archiving \(sessions.count) sessions")
        
        // Don't interrupt the data flow - archive in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Archive the sessions
            self.database.archiveNewSessions(sessions)
            
            // Update UI state
            DispatchQueue.main.async {
                self.lastArchiveDate = Date()
                self.archivedSessionCount = self.database.loadArchivedSessions().count
                self.objectWillChange.send()
            }
        }
    }
    
    // Initialize with additional notification observer
    func setupAdditionalObservers() {
        // Add observer for when journal manager directly updates sessions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkAndArchiveOldSessions),
            name: Notification.Name("SessionsUpdated"),
            object: nil
        )
    }
}
