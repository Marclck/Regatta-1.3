//
//  JournalManager.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation

struct RaceSession: Codable {
    var id: String { date.timeIntervalSince1970.description }  // Create unique ID from date

    let date: Date
    let countdownDuration: Int  // in minutes
    let raceStartTime: Date?    // nil if cancelled before stopwatch
    let raceDuration: TimeInterval?  // nil if cancelled before finish
    
    var formattedStartTime: String {
        guard let startTime = raceStartTime else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: startTime)
    }
    
    var formattedRaceTime: String {
        guard let duration = raceDuration else { return "N/A" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private var formattedLastFinishTime: String {
        guard let lastSession = JournalManager.shared.allSessions.last,
              let duration = lastSession.raceDuration else {
            return "--:--"
        }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class JournalManager: ObservableObject {
    static let shared = JournalManager()
    
    @Published private(set) var currentSession: RaceSession?
    @Published private(set) var allSessions: [RaceSession] = [] {
        didSet {
            print("📓 allSessions updated, count: \(allSessions.count)")
            print("\(allSessions)")
        }
    }
    
    private let sessionsKey = SharedDefaults.sessionsKey
    private let currentSessionKey = SharedDefaults.currentSessionKey
    
        
    private let defaults = SharedDefaults.shared
    
    private init() {        
        print("🔵 SharedDefaults keys available:")
        print(defaults.dictionaryRepresentation().keys)
        loadSessions()
        loadCurrentSession()
    }
    
    // Start new session when countdown starts
    func startNewSession(countdownMinutes: Int) {
        let newSession = RaceSession(
            date: Date(),
            countdownDuration: countdownMinutes,
            raceStartTime: nil,
            raceDuration: nil
        )
        currentSession = newSession
        saveCurrentSession()
        print("new session started")
    }
    
    // Update when entering stopwatch mode
    func recordRaceStart() {
        guard var session = currentSession else { return }
        let updatedSession = RaceSession(
            date: session.date,
            countdownDuration: session.countdownDuration,
            raceStartTime: Date(),
            raceDuration: nil
        )
        currentSession = updatedSession
        saveCurrentSession()
        print("race start recorded \(updatedSession)")
    }
    
    // Record final time when cancelled
    func recordSessionEnd(totalTime: TimeInterval) {
        guard let session = currentSession else {
            print("📓 No current session to record")
            return
        }
        
        let finalSession = RaceSession(
            date: session.date,
            countdownDuration: session.countdownDuration,
            raceStartTime: session.raceStartTime,
            raceDuration: totalTime
        )
        
        print("📓 Recording session with duration: \(totalTime)")
        
        // Load existing sessions first to avoid overwriting
        loadSessions()  // Add this line
        allSessions.append(finalSession)
        currentSession = nil
        
        print("📓 Total sessions after adding new one: \(allSessions.count)")
        saveSessions()
        clearCurrentSession()
        
        // Force UI update
        objectWillChange.send()
    }
    
    // Cancel session without recording
    func cancelSession() {
        currentSession = nil
        clearCurrentSession()
        print("session cancelled.")
    }
    

    
    // MARK: - Data Persistence
    
    // Update all UserDefaults calls to use shared defaults
    private func saveCurrentSession() {
        if let encoded = try? JSONEncoder().encode(currentSession) {
            defaults.set(encoded, forKey: currentSessionKey)
        }
    }
    
    private func saveSessions() {
        SharedDefaults.saveSessionsToContainer(allSessions)
    }
    
    private func loadCurrentSession() {
        guard let data = defaults.data(forKey: currentSessionKey),
              let session = try? JSONDecoder().decode(RaceSession?.self, from: data) else {
            return
        }
        currentSession = session
    }
    
    private func loadSessions() {
        print("📓 Loading sessions from shared container")
        if let sessions = SharedDefaults.loadSessionsFromContainer() {
            allSessions = sessions
            print("📓 Loaded \(sessions.count) sessions successfully")
        }
    }
    
    private func clearCurrentSession() {
        defaults.removeObject(forKey: currentSessionKey)
        defaults.synchronize()
    }
}
