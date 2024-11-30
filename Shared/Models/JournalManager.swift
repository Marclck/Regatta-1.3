//
//  JournalManager.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation

struct RaceSession: Codable {
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
}

class JournalManager: ObservableObject {
    static let shared = JournalManager()
    
    @Published private(set) var currentSession: RaceSession?
    @Published private(set) var allSessions: [RaceSession] = []
    
    private let sessionsKey = "savedRaceSessions"
    private let currentSessionKey = "currentRaceSession"
    
    private init() {
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
    }
    
    // Record final time when cancelled
    func recordSessionEnd(totalTime: TimeInterval) {
        guard let session = currentSession else { return }
        
        let finalSession = RaceSession(
            date: session.date,
            countdownDuration: session.countdownDuration,
            raceStartTime: session.raceStartTime,
            raceDuration: totalTime
        )
        
        allSessions.append(finalSession)
        currentSession = nil
        
        saveSessions()
        clearCurrentSession()
    }
    
    // Cancel session without recording
    func cancelSession() {
        currentSession = nil
        clearCurrentSession()
    }
    
    // MARK: - Data Persistence
    
    private func saveCurrentSession() {
        if let encoded = try? JSONEncoder().encode(currentSession) {
            UserDefaults.standard.set(encoded, forKey: currentSessionKey)
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(allSessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadCurrentSession() {
        guard let data = UserDefaults.standard.data(forKey: currentSessionKey),
              let session = try? JSONDecoder().decode(RaceSession?.self, from: data) else {
            return
        }
        currentSession = session
    }
    
    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([RaceSession].self, from: data) else {
            return
        }
        allSessions = sessions
    }
    
    private func clearCurrentSession() {
        UserDefaults.standard.removeObject(forKey: currentSessionKey)
    }
}
