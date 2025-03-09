//
//  JSONSessionDatabase.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation
import Combine

/// A JSON database manager specifically designed for RaceSession storage
/// Works alongside existing UserDefaults for seamless integration
class JSONSessionDatabase {
    // MARK: - Singleton Instance
    static let shared = JSONSessionDatabase()
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let sessionsFileName = "race_sessions_archive"
    
    // MARK: - Initialization
    private init() {
        print("💾 JSONSessionDatabase: Initializing")
        createDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    private func createDirectoryIfNeeded() {
        let directoryURL = getDirectoryURL()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                print("💾 Created database directory at: \(directoryURL.path)")
            } catch {
                print("💾 Error creating database directory: \(error)")
            }
        }
    }
    
    private func getDirectoryURL() -> URL {
        // Use the app group container if available, otherwise use documents directory
        #if os(iOS)
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourapp.regatta") {
            return containerURL.appendingPathComponent("Database", isDirectory: true)
        }
        #endif
        
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Database", isDirectory: true)
    }
    
    // MARK: - File URL
    private func getSessionsFileURL() -> URL {
        return getDirectoryURL().appendingPathComponent("\(sessionsFileName).json")
    }
    
    // MARK: - Session Operations
    
    /// Loads all archived sessions from JSON storage
    func loadArchivedSessions() -> [RaceSession] {
        let fileURL = getSessionsFileURL()
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("💾 No sessions archive file exists yet")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let sessions = try decoder.decode([RaceSession].self, from: data)
            print("💾 Successfully loaded \(sessions.count) sessions from JSON archive")
            return sessions
        } catch {
            print("💾 Error loading archived sessions: \(error)")
            return []
        }
    }
    
    /// Archives sessions to JSON storage
    func archiveSessions(_ sessions: [RaceSession]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(sessions)
            
            try data.write(to: getSessionsFileURL())
            print("💾 Successfully archived \(sessions.count) sessions to JSON database")
        } catch {
            print("💾 Error archiving sessions: \(error)")
        }
    }
    
    /// Archives new sessions while preserving existing ones
    func archiveNewSessions(_ newSessions: [RaceSession]) {
        let existingSessions = loadArchivedSessions()
        
        // Create a combined list with no duplicates
        var combinedSessions = existingSessions
        for session in newSessions {
            if !existingSessions.contains(where: { $0.id == session.id }) {
                combinedSessions.append(session)
            }
        }
        
        // Sort by date (newest first)
        combinedSessions.sort { $0.date > $1.date }
        
        // Archive the combined list
        archiveSessions(combinedSessions)
    }
    
    /// Returns all sessions (both active from UserDefaults and archived)
    func getAllSessions() -> [RaceSession] {
        // Get active sessions from UserDefaults
        let activeSessions = SharedDefaults.loadSessionsFromContainer() ?? []
        
        // Get archived sessions
        let archivedSessions = loadArchivedSessions()
        
        // Combine and deduplicate
        var allSessions = activeSessions
        for session in archivedSessions {
            if !activeSessions.contains(where: { $0.id == session.id }) {
                allSessions.append(session)
            }
        }
        
        // Sort by date (newest first)
        allSessions.sort { $0.date > $1.date }
        
        return allSessions
    }
    
    /// Delete a session from both active and archived storage
    func deleteSession(withID id: String) -> Bool {
        var deleted = false
        
        // First try to delete from active sessions
        if var activeSessions = SharedDefaults.loadSessionsFromContainer() {
            let originalCount = activeSessions.count
            activeSessions.removeAll { $0.id == id }
            
            if activeSessions.count < originalCount {
                SharedDefaults.saveSessionsToContainer(activeSessions)
                deleted = true
                print("💾 Deleted session from active sessions")
            }
        }
        
        // Also try to delete from archived sessions
        let archivedSessions = loadArchivedSessions()
        let originalCount = archivedSessions.count
        let filteredSessions = archivedSessions.filter { $0.id != id }
        
        if filteredSessions.count < originalCount {
            archiveSessions(filteredSessions)
            deleted = true
            print("💾 Deleted session from archived sessions")
        }
        
        return deleted
    }
    
    /// Archive old sessions to keep UserDefaults storage minimal
    func archiveOldSessions(keepRecentCount: Int = 10) {
        guard let activeSessions = SharedDefaults.loadSessionsFromContainer(),
              activeSessions.count > keepRecentCount else {
            return
        }
        
        // Sort by date (newest first)
        let sortedSessions = activeSessions.sorted { $0.date > $1.date }
        
        // Keep only the most recent sessions in active storage
        let sessionsToKeep = Array(sortedSessions.prefix(keepRecentCount))
        let sessionsToArchive = Array(sortedSessions.suffix(from: keepRecentCount))
        
        // Update active sessions
        SharedDefaults.saveSessionsToContainer(sessionsToKeep)
        
        // Archive the older sessions
        archiveNewSessions(sessionsToArchive)
        
        print("💾 Archived \(sessionsToArchive.count) old sessions, keeping \(sessionsToKeep.count) active")
    }
}
