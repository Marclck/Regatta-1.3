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
    @Published var tackCount: Int = 0      // Added
    @Published var topSpeed: Double = 0     // Added
    @Published var tackAngle: Double = 0  // Add this
    
    private let defaults = UserDefaults.standard
    private let speedKey = "lastSpeed"
    private let distanceKey = "lastDistance"
    private let courseKey = "lastCourse"
    private let directionKey = "lastDirection"
    private let deviationKey = "lastDeviation"
    private let tackCountKey = "lastTackCount"  // Added
    private let topSpeedKey = "lastTopSpeed"    // Added
    private let tackAngleKey = "lastTackAngle"  // Add this

    init() {
        loadLastReading()
    }
    
    private func loadLastReading() {
        speed = defaults.double(forKey: speedKey)
        distance = defaults.double(forKey: distanceKey)
        course = defaults.double(forKey: courseKey)
        cardinalDirection = defaults.string(forKey: directionKey) ?? "N"
        deviation = defaults.double(forKey: deviationKey)
        tackCount = defaults.integer(forKey: tackCountKey)  // Added
        topSpeed = defaults.double(forKey: topSpeedKey)     // Added
        tackAngle = defaults.double(forKey: tackAngleKey)  // Add this
    }
    
    func saveReading(speed: Double, distance: Double, course: Double, direction: String, deviation: Double, tackCount: Int, topSpeed: Double, tackAngle: Double) {  // Add tackAngle
            self.speed = speed
            self.distance = distance
            self.course = course
            self.cardinalDirection = direction
            self.deviation = deviation
            self.tackCount = tackCount  // Now using the passed tackCount value
            self.topSpeed = topSpeed  // Save the passed topSpeed
        self.tackAngle = tackAngle  // Add this

            defaults.set(speed, forKey: speedKey)
            defaults.set(distance, forKey: distanceKey)
            defaults.set(course, forKey: courseKey)
            defaults.set(direction, forKey: directionKey)
            defaults.set(deviation, forKey: deviationKey)
            defaults.set(tackCount, forKey: tackCountKey)
            defaults.set(topSpeed, forKey: topSpeedKey)
        defaults.set(tackAngle, forKey: tackAngleKey)  // Add this
    }
    
    func resetDistance() {
        distance = 0
        tackCount = 0    // Reset tack count when distance is reset
        topSpeed = 0     // Reset top speed when distance is reset
        defaults.set(0, forKey: distanceKey)
        defaults.set(0, forKey: tackCountKey)
        defaults.set(0, forKey: topSpeedKey)
        defaults.set(0, forKey: tackAngleKey)  // Add this
    }
}
