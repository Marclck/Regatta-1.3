//
//  JournalManager.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation
import CoreLocation

struct DataPoint: Codable {
    let timestamp: Date
    let heartRate: Int?
    let speed: Double?  // in knots
    let location: LocationData?
}

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
}

struct RaceSession: Codable {
    var id: String { date.timeIntervalSince1970.description }
    
    let date: Date
    let countdownDuration: Int
    let raceStartTime: Date?
    let raceDuration: TimeInterval?
    let timeZoneOffset: Int
    var dataPoints: [DataPoint]
    let leftPoint: LocationData?  // Added
    let rightPoint: LocationData?  // Added
    
    init(date: Date,
         countdownDuration: Int,
         raceStartTime: Date?,
         raceDuration: TimeInterval?,
         dataPoints: [DataPoint] = [],
         leftPoint: LocationData? = nil,
         rightPoint: LocationData? = nil) {
        self.date = date
        self.countdownDuration = countdownDuration
        self.raceStartTime = raceStartTime
        self.raceDuration = raceDuration
        self.timeZoneOffset = TimeZone.current.secondsFromGMT()
        self.dataPoints = dataPoints
        self.leftPoint = leftPoint
        self.rightPoint = rightPoint
    }
    
    var formattedStartTime: String {
        guard let startTime = raceStartTime else { return "N/A" }
        let formatter = DateFormatter()
        
        // Create timezone from stored offset
        let timeZone = TimeZone(secondsFromGMT: timeZoneOffset) ?? TimeZone.current
        formatter.timeZone = timeZone
        
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: startTime)
    }
    
    // Helper methods for SessionRowView
    func formattedDate() -> String {
        let formatter = DateFormatter()
        let timeZone = TimeZone(secondsFromGMT: timeZoneOffset) ?? TimeZone.current
        formatter.timeZone = timeZone
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        let timeZone = TimeZone(secondsFromGMT: timeZoneOffset) ?? TimeZone.current
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    func timeZoneString() -> String {
        let hours = abs(timeZoneOffset) / 3600
        let sign = timeZoneOffset >= 0 ? "+" : "-"
        return "GMT\(sign)\(hours)"
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
    
    private var sessionDataPoints: [DataPoint] = []
    
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
            raceDuration: nil,
            dataPoints: sessionDataPoints  // Add this line
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
            raceDuration: nil,
            dataPoints: sessionDataPoints  // Add this line
        )
        currentSession = updatedSession
        saveCurrentSession()
        print("race start recorded \(updatedSession)")
    }
    
    // Record final time when cancelled
    private struct StoredPoint: Codable {
        let coordinate: CLLocationCoordinate2D
        let timestamp: Date
        
        enum CodingKeys: String, CodingKey {
            case latitude = "lat"
            case longitude = "lon"
            case timestamp
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(coordinate.latitude, forKey: .latitude)
            try container.encode(coordinate.longitude, forKey: .longitude)
            try container.encode(timestamp, forKey: .timestamp)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let lat = try container.decode(Double.self, forKey: .latitude)
            let lon = try container.decode(Double.self, forKey: .longitude)
            let timestamp = try container.decode(Date.self, forKey: .timestamp)
            
            self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.timestamp = timestamp
        }
    }

    func recordSessionEnd(totalTime: TimeInterval) {
        guard let session = currentSession else {
            print("📓 No current session to record")
            return
        }
        
        // Get start line points from UserDefaults
        var leftPoint: LocationData? = nil
        var rightPoint: LocationData? = nil
        
        if let leftData = UserDefaults.standard.data(forKey: "leftPoint"),
           let leftLocation = try? JSONDecoder().decode(StoredPoint.self, from: leftData) {
            leftPoint = LocationData(
                latitude: leftLocation.coordinate.latitude,
                longitude: leftLocation.coordinate.longitude,
                accuracy: 0
            )
        }
        
        if let rightData = UserDefaults.standard.data(forKey: "rightPoint"),
           let rightLocation = try? JSONDecoder().decode(StoredPoint.self, from: rightData) {
            rightPoint = LocationData(
                latitude: rightLocation.coordinate.latitude,
                longitude: rightLocation.coordinate.longitude,
                accuracy: 0
            )
        }
        
        let finalSession = RaceSession(
            date: session.date,
            countdownDuration: session.countdownDuration,
            raceStartTime: session.raceStartTime,
            raceDuration: totalTime,
            dataPoints: sessionDataPoints,
            leftPoint: leftPoint,
            rightPoint: rightPoint
        )
        
        print("📓 Recording session with duration: \(totalTime)")
        print("📓 Start line points - Left: \(String(describing: leftPoint)), Right: \(String(describing: rightPoint))")
        
        loadSessions()
        allSessions.append(finalSession)
        currentSession = nil
        
        print("📓 Total sessions after adding new one: \(allSessions.count)")
        saveSessions()
        clearCurrentSession()
        
        objectWillChange.send()
    }
    
    // Cancel session without recording
    func cancelSession() {
        currentSession = nil
        clearCurrentSession()
        sessionDataPoints.removeAll()
        print("session cancelled.")
    }
    
    func addDataPoint(heartRate: Int?, speed: Double?, location: CLLocation?) {
        guard let session = currentSession, session.raceStartTime != nil else { return }
        
        let locationData = location.map { loc in
            LocationData(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                accuracy: loc.horizontalAccuracy
            )
        }
        
        let dataPoint = DataPoint(
            timestamp: Date(),
            heartRate: heartRate,
            speed: speed,  // Already in knots from SpeedDisplayView
            location: locationData
        )
        
        sessionDataPoints.append(dataPoint)
    }
    
    // MARK: - Data Persistence
    
    // Update all UserDefaults calls to use shared defaults
    private func saveCurrentSession() {
        if let encoded = try? JSONEncoder().encode(currentSession) {
            defaults.set(encoded, forKey: currentSessionKey)
        }
    }
    
    func saveSessions() {
        SharedDefaults.saveSessionsToContainer(self.allSessions)
        
        #if os(watchOS)
        guard !allSessions.isEmpty else {
            print("📓 No sessions to transfer")
            return
        }
        // Send to iOS
        WatchSessionManager.shared.transferSessions(self.allSessions)
        #endif
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
