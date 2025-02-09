//
//  LastReadingmanager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 09/02/2025.
//

import Foundation
import CoreLocation

class LastReadingManager: ObservableObject {
    @Published var speed: Double = 0
    @Published var distance: Double = 0
    @Published var course: Double = 0
    @Published var cardinalDirection: String = "N"
    
    private let defaults = UserDefaults.standard
    private let speedKey = "lastSpeed"
    private let distanceKey = "lastDistance"
    private let courseKey = "lastCourse"
    private let directionKey = "lastDirection"
    
    init() {
        loadLastReading()
    }
    
    private func loadLastReading() {
        speed = defaults.double(forKey: speedKey)
        distance = defaults.double(forKey: distanceKey)
        course = defaults.double(forKey: courseKey)
        cardinalDirection = defaults.string(forKey: directionKey) ?? "N"
    }
    
    func saveReading(speed: Double, distance: Double, course: Double, direction: String) {
        self.speed = speed
        self.distance = distance
        self.course = course
        self.cardinalDirection = direction
        
        defaults.set(speed, forKey: speedKey)
        defaults.set(distance, forKey: distanceKey)
        defaults.set(course, forKey: courseKey)
        defaults.set(direction, forKey: directionKey)
    }
    
    func resetDistance() {
        distance = 0
        defaults.set(0, forKey: distanceKey)
    }
}
