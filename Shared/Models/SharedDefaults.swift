//
//  SharedDefaults.swift
//  Regatta
//
//  Created by Chikai Lai on 26/11/2024.
//

//
//  SharedDefaults.swift
//  Regatta
//
//  Created by Chikai Lai on 26/11/2024.
//

import Foundation
import WidgetKit

struct SharedDefaults {
    private static let appGroupIdentifier = "group.com.heart.astrolabe.watchkitapp"
    
    // Used for migrating old sessions
    private struct LegacyRaceSession: Codable {
        let date: Date
        let countdownDuration: Int
        let raceStartTime: Date?
        let raceDuration: TimeInterval?
    }

    static let shared: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            fatalError("Failed to create shared UserDefaults with suite: \(appGroupIdentifier)")
        }
        return defaults
    }()
    
    static let container: URL = {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("Failed to create container URL for group: \(appGroupIdentifier)")
        }
        return url
    }()
    
    static let lastUsedTimeKey = "lastUsedTime"
    static let lastFinishTimeKey = "lastFinishTime"
    static let sessionsKey = "savedRaceSessions"
    static let currentSessionKey = "currentRaceSession"
    
    static func saveSessionsToContainer(_ sessions: [RaceSession]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(sessions)
            
            // Create a temporary file first
            let tempFileURL = container.appendingPathComponent("sessions.json.tmp")
            try data.write(to: tempFileURL)
            
            // Get the final file URL
            let fileURL = container.appendingPathComponent("sessions.json")
            
            // If a file exists at the destination, remove it
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            // Move the temporary file to the final location
            try FileManager.default.moveItem(at: tempFileURL, to: fileURL)
            
            // Also save to UserDefaults as backup
            shared.set(data, forKey: sessionsKey)
            shared.synchronize()
            
            print("📱 SharedDefaults: Saved sessions to container")
        } catch {
            print("📱 SharedDefaults: Error saving sessions to container: \(error)")
        }
    }
    
    static func loadSessionsFromContainer() -> [RaceSession]? {
        let fileURL = container.appendingPathComponent("sessions.json")
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            
            // First try to decode as current version
            do {
                let sessions = try decoder.decode([RaceSession].self, from: data)
                print("📱 SharedDefaults: Loaded \(sessions.count) sessions from container")
                return sessions
            } catch DecodingError.keyNotFound(let key, _) where key.stringValue == "timeZoneOffset" {
                // If timeZoneOffset is missing, try to decode as legacy format and migrate
                print("📱 SharedDefaults: Attempting to migrate legacy sessions")
                do {
                    let legacySessions = try decoder.decode([LegacyRaceSession].self, from: data)
                    
                    // Convert legacy sessions to current format
                    let migratedSessions = legacySessions.map { legacy in
                        RaceSession(
                            date: legacy.date,
                            countdownDuration: legacy.countdownDuration,
                            raceStartTime: legacy.raceStartTime,
                            raceDuration: legacy.raceDuration
                        )
                    }
                    
                    // Save migrated sessions back to container
                    saveSessionsToContainer(migratedSessions)
                    print("📱 SharedDefaults: Successfully migrated \(migratedSessions.count) sessions")
                    return migratedSessions
                } catch {
                    print("📱 SharedDefaults: Failed to decode legacy sessions: \(error)")
                    // Fall through to try UserDefaults backup
                }
            }
        } catch {
            print("📱 SharedDefaults: Error loading sessions from container: \(error)")
        }
        
        // Try loading from UserDefaults as backup
        if let data = shared.data(forKey: sessionsKey) {
            do {
                // Try current version first
                let sessions = try JSONDecoder().decode([RaceSession].self, from: data)
                print("📱 SharedDefaults: Loaded \(sessions.count) sessions from UserDefaults backup")
                return sessions
            } catch DecodingError.keyNotFound(let key, _) where key.stringValue == "timeZoneOffset" {
                // Try legacy version if timeZoneOffset is missing
                do {
                    let legacySessions = try JSONDecoder().decode([LegacyRaceSession].self, from: data)
                    let migratedSessions = legacySessions.map { legacy in
                        RaceSession(
                            date: legacy.date,
                            countdownDuration: legacy.countdownDuration,
                            raceStartTime: legacy.raceStartTime,
                            raceDuration: legacy.raceDuration
                        )
                    }
                    print("📱 SharedDefaults: Migrated \(migratedSessions.count) sessions from UserDefaults backup")
                    return migratedSessions
                } catch {
                    print("📱 SharedDefaults: Failed to decode legacy sessions from UserDefaults: \(error)")
                }
            } catch {
                print("📱 SharedDefaults: Failed to decode sessions from UserDefaults: \(error)")
            }
        }
        
        print("📱 SharedDefaults: No valid sessions found in container or UserDefaults")
        return nil
    }
    
    
    static func setLastUsedTime(_ minutes: Int) {
        shared.set(minutes, forKey: lastUsedTimeKey)
        print("📱 SharedDefaults: Saved last used time: \(minutes) minutes")
        WidgetCenter.shared.reloadAllTimelines()  // This triggers widget update

    }
    
    static func getLastUsedTime() -> Int {
        let time = shared.integer(forKey: lastUsedTimeKey)
        print("📱 SharedDefaults: Retrieved last used time: \(time) minutes")
        return time
    }
    
    static func setLastFinishTime(_ time: Double) {
        shared.set(time, forKey: lastFinishTimeKey)
        print("📱 SharedDefaults: Saved last finish time: \(time) seconds")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func getLastFinishTime() -> Double {
        let time = shared.double(forKey: lastFinishTimeKey)
        print("📱 SharedDefaults: Retrieved last finish time: \(time) seconds")
        return time
    }
    
    static let themeKey = "selectedTheme"
    
    static func saveTheme(_ theme: ColorTheme) {
        shared.set(theme.rawValue, forKey: themeKey)
        print("📱 SharedDefaults: Saved theme: \(theme.name)")
        WidgetCenter.shared.reloadAllTimelines()  // Reload widgets when theme changes
    }
    
    static func getTheme() -> ColorTheme {
        if let savedTheme = shared.string(forKey: themeKey),
           let theme = ColorTheme(rawValue: savedTheme) {
            print("📱 SharedDefaults: Retrieved theme: \(theme.name)")
            return theme
        }
        print("📱 SharedDefaults: Using default theme: Cambridge Blue")
        return .cambridgeBlue
    }
    
}
