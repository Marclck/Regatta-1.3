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
    @Published var deviation: Double = 0
    
    private let defaults = UserDefaults.standard
    private let speedKey = "lastSpeed"
    private let distanceKey = "lastDistance"
    private let courseKey = "lastCourse"
    private let directionKey = "lastDirection"
    private let deviationKey = "lastDeviation"
    
    init() {
        loadLastReading()
    }
    
    private func loadLastReading() {
        speed = defaults.double(forKey: speedKey)
        distance = defaults.double(forKey: distanceKey)
        course = defaults.double(forKey: courseKey)
        cardinalDirection = defaults.string(forKey: directionKey) ?? "N"
        deviation = defaults.double(forKey: deviationKey)
    }
    
    func saveReading(speed: Double, distance: Double, course: Double, direction: String, deviation: Double) {
        self.speed = speed
        self.distance = distance
        self.course = course
        self.cardinalDirection = direction
        self.deviation = deviation
        
        defaults.set(speed, forKey: speedKey)
        defaults.set(distance, forKey: distanceKey)
        defaults.set(course, forKey: courseKey)
        defaults.set(direction, forKey: directionKey)
        defaults.set(deviation, forKey: deviationKey)
    }
    
    func resetDistance() {
        distance = 0
        defaults.set(0, forKey: distanceKey)
    }
}
