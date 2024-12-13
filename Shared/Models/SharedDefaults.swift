//
//  SharedDefaults.swift
//  Regatta
//
//  Created by Chikai Lai on 26/11/2024.
//

import Foundation
import WidgetKit

struct SharedDefaults {
    private static let appGroupIdentifier = "group.heart.Regatta.watchkitapp"

    static let shared: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            fatalError("Failed to create shared UserDefaults with suite: \(appGroupIdentifier)")
        }
        return defaults
    }()
    
    // Add container URL for file-based sharing
    static let container: URL = {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("Failed to create container URL for group: \(appGroupIdentifier)")
        }
        return url
    }()
    
    static let lastUsedTimeKey = "lastUsedTime"
    static let lastFinishTimeKey = "lastFinishTime"  // New key

    static let sessionsKey = "savedRaceSessions"
    static let currentSessionKey = "currentRaceSession"
    
    // Methods using container for file-based storage
    static func saveSessionsToContainer(_ sessions: [RaceSession]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(sessions)
            let fileURL = container.appendingPathComponent("sessions.json")
            try data.write(to: fileURL)
            print("📱 SharedDefaults: Saved sessions to container")
            
            // Also save to UserDefaults as backup
            shared.set(data, forKey: sessionsKey)
            shared.synchronize()
        } catch {
            print("📱 SharedDefaults: Error saving sessions to container: \(error)")
        }
    }
    
    static func loadSessionsFromContainer() -> [RaceSession]? {
        let fileURL = container.appendingPathComponent("sessions.json")
        do {
            let data = try Data(contentsOf: fileURL)
            let sessions = try JSONDecoder().decode([RaceSession].self, from: data)
            print("📱 SharedDefaults: Loaded \(sessions.count) sessions from container")
            return sessions
        } catch {
            print("📱 SharedDefaults: Error loading sessions from container: \(error)")
            
            // Try loading from UserDefaults as backup
            if let data = shared.data(forKey: sessionsKey),
               let sessions = try? JSONDecoder().decode([RaceSession].self, from: data) {
                return sessions
            }
            return nil
        }
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
