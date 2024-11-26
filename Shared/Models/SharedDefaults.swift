//
//  SharedDefaults.swift
//  Regatta
//
//  Created by Chikai Lai on 26/11/2024.
//

import Foundation

struct SharedDefaults {
    static let suiteName = "group.heart.Regatta.watchkitapp" // Replace with your group
    static let shared = UserDefaults(suiteName: suiteName)!
    
    static let lastUsedTimeKey = "lastUsedTime"
}
