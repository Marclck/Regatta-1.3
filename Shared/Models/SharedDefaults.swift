//
//  SharedDefaults.swift
//  Regatta
//
//  Created by Chikai Lai on 26/11/2024.
//

import Foundation
import WidgetKit

struct SharedDefaults {
    static let suiteName = "group.heart.Regatta.watchkitapp" // Replace with your group name
    static let shared = UserDefaults(suiteName: suiteName)!
    
    static let lastUsedTimeKey = "lastUsedTime"
    
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
}
