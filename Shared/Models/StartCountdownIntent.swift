//
//  StartCountdownIntent.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 24/11/2024.
//

import Foundation
import AppIntents
import SwiftUI

struct StartCountdownIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Countdown"
    static var description: LocalizedStringResource = "Start the regatta countdown timer"
    
    // Remove default value, we'll handle it in the initializer
    @Parameter(title: "Minutes",
              description: "Number of minutes for countdown (1-30)") //30 max
    var minutes: Int
    
    init() {
        // Set default value here
        let lastUsed = UserDefaults.standard.integer(forKey: "lastUsedTime")
        self.minutes = lastUsed > 0 ? lastUsed : 5
    }
    
    init(minutes: Int) {
        self.minutes = minutes
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$minutes) minute countdown")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard minutes >= 1 && minutes <= 30 else { //30 max
            throw Error.invalidMinutes
        }
        
#if os(iOS)
// iOS specific notification
NotificationCenter.default.post(
    name: Notification.Name("StartCountdownFromShortcut"),
    object: nil,
    userInfo: ["minutes": minutes]
)
#else
// watchOS specific notification
NotificationCenter.default.post(
    name: Notification.Name("StartCountdownFromShortcut"),
    object: nil,
    userInfo: ["minutes": minutes]
)
#endif
        
        return .result()
    }
    
    enum Error: Swift.Error {
        case invalidMinutes
    }
}

struct RegattaShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartCountdownIntent(),
            phrases: [
                "Start regatta countdown",
                "Start countdown timer",
                "Begin regatta timer"
            ],
            shortTitle: "Start Timer",
            systemImageName: "timer.circle.fill"
        )
    }
}
