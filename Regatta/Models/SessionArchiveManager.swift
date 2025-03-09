//
//  SessionArchiveManager.swift
//  Regatta
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation

class SessionArchiveManager {
    static let shared = SessionArchiveManager()
    
    private let fileManager = FileManager.default
    private var archiveURL: URL? {
        try? fileManager.url(for: .documentDirectory,
                          in: .userDomainMask,
                          appropriateFor: nil,
                          create: true)
            .appendingPathComponent("sessionArchive.json")
    }
    
    private init() {
        print("🗄️ Archive Manager: Initializing")
        // Create archive file if it doesn't exist
        createArchiveIfNeeded()
    }
    
    // MARK: - Archive Operations
    
    /// Create archive file if it doesn't exist
    private func createArchiveIfNeeded() {
        guard let url = archiveURL else {
            print("🗄️ Archive Manager: Failed to get archive URL")
            return
        }
        
        if !fileManager.fileExists(atPath: url.path) {
            print("🗄️ Archive Manager: Creating new archive file")
            // Create empty archive
            do {
                let emptyArchive: [RaceSession] = []
                let data = try JSONEncoder().encode(emptyArchive)
                try data.write(to: url)
                print("🗄️ Archive Manager: Created empty archive file at \(url.path)")
            } catch {
                print("🗄️ Archive Manager: Failed to create archive file - \(error.localizedDescription)")
            }
        } else {
            print("🗄️ Archive Manager: Archive file already exists at \(url.path)")
        }
    }
    
    /// Load all sessions from archive
    func loadArchivedSessions() -> [RaceSession] {
        guard let url = archiveURL else {
            print("🗄️ Archive Manager: Failed to get archive URL")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let sessions = try JSONDecoder().decode([RaceSession].self, from: data)
            print("🗄️ Archive Manager: Loaded \(sessions.count) sessions from archive")
            return sessions
        } catch {
            print("🗄️ Archive Manager: Failed to load archive - \(error.localizedDescription)")
            return []
        }
    }
    
    /// Save sessions to archive, avoiding duplicates
    func saveSessionsToArchive(_ sessions: [RaceSession]) {
        guard let url = archiveURL else {
            print("🗄️ Archive Manager: Failed to get archive URL")
            return
        }
        
        do {
            // Load existing archive
            let existingArchive = loadArchivedSessions()
            
            // Merge new sessions with existing ones, avoiding duplicates
            let mergedSessions = mergeSessions(existing: existingArchive, new: sessions)
            
            // Sort by date (newest first)
            let sortedSessions = mergedSessions.sorted(by: { $0.date > $1.date })
            
            // Save to file
            let data = try JSONEncoder().encode(sortedSessions)
            try data.write(to: url)
            print("🗄️ Archive Manager: Saved \(sortedSessions.count) sessions to archive")
        } catch {
            print("🗄️ Archive Manager: Failed to save archive - \(error.localizedDescription)")
        }
    }
    
    /// Merge sessions avoiding duplicates (using session date as unique identifier)
    private func mergeSessions(existing: [RaceSession], new: [RaceSession]) -> [RaceSession] {
        var sessionMap: [String: RaceSession] = [:]
        
        // Add existing sessions to map
        for session in existing {
            sessionMap[session.id] = session
        }
        
        // Add new sessions, overwriting if they exist
        for session in new {
            sessionMap[session.id] = session
        }
        
        // Convert map back to array
        return Array(sessionMap.values)
    }
    
    /// Migrate all sessions from UserDefaults to archive
    func migrateExistingSessionsToArchive() {
        print("🗄️ Archive Manager: Starting migration of existing sessions")
        
        // Load from SharedDefaults
        if let existingSessions = SharedDefaults.loadSessionsFromContainer() {
            print("🗄️ Archive Manager: Found \(existingSessions.count) sessions to migrate")
            
            // Save to archive
            saveSessionsToArchive(existingSessions)
            print("🗄️ Archive Manager: Migration completed")
        } else {
            print("🗄️ Archive Manager: No sessions found to migrate")
        }
    }
}
