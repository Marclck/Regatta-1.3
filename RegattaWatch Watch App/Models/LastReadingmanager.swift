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
    @Published var tackCount: Int = 0
    @Published var topSpeed: Double = 0
    @Published var tackAngle: Double = 0
    @Published var waypointDistance: Double = 0  // Add this
    @Published var waypointIndex: Int = 0        // Add this
    
    private let defaults = UserDefaults.standard
    private let speedKey = "lastSpeed"
    private let distanceKey = "lastDistance"
    private let courseKey = "lastCourse"
    private let directionKey = "lastDirection"
    private let deviationKey = "lastDeviation"
    private let tackCountKey = "lastTackCount"
    private let topSpeedKey = "lastTopSpeed"
    private let tackAngleKey = "lastTackAngle"
    private let waypointDistanceKey = "lastWaypointDistance"  // Add this
    private let waypointIndexKey = "lastWaypointIndex"        // Add this
    
    // Cruise session tracking
    private var cruiseSessionDataPoints: [DataPoint] = []
    private var cruiseSessionStartTime: Date? = nil
    private var isCruiseSessionActive: Bool = false
    
    init() {
        loadLastReading()
    }
    
    // Add this public method to LastReadingManager
    func endCruiseSession() {
        // If we have an active session, end and save it
        if isCruiseSessionActive && !cruiseSessionDataPoints.isEmpty {
            saveCurrentSessionToJournal()
        }
    }
    
    private func loadLastReading() {
        speed = defaults.double(forKey: speedKey)
        distance = defaults.double(forKey: distanceKey)
        course = defaults.double(forKey: courseKey)
        cardinalDirection = defaults.string(forKey: directionKey) ?? "N"
        deviation = defaults.double(forKey: deviationKey)
        tackCount = defaults.integer(forKey: tackCountKey)
        topSpeed = defaults.double(forKey: topSpeedKey)
        tackAngle = defaults.double(forKey: tackAngleKey)
        waypointDistance = defaults.double(forKey: waypointDistanceKey)  // Add this
        waypointIndex = defaults.integer(forKey: waypointIndexKey)       // Add this
    }
    
    func saveReading(speed: Double, distance: Double, course: Double, direction: String, deviation: Double, tackCount: Int, topSpeed: Double, tackAngle: Double) {
        self.speed = speed
        self.distance = distance
        self.course = course
        self.cardinalDirection = direction
        self.deviation = deviation
        self.tackCount = tackCount
        self.topSpeed = topSpeed
        self.tackAngle = tackAngle

        defaults.set(speed, forKey: speedKey)
        defaults.set(distance, forKey: distanceKey)
        defaults.set(course, forKey: courseKey)
        defaults.set(direction, forKey: directionKey)
        defaults.set(deviation, forKey: deviationKey)
        defaults.set(tackCount, forKey: tackCountKey)
        defaults.set(topSpeed, forKey: topSpeedKey)
        defaults.set(tackAngle, forKey: tackAngleKey)
    }
    
    // Add new method to save waypoint information
    func saveWaypointInfo(distance: Double, index: Int) {
        self.waypointDistance = distance
        self.waypointIndex = index
        
        defaults.set(distance, forKey: waypointDistanceKey)
        defaults.set(index, forKey: waypointIndexKey)
    }
    
    func resetDistance(isMonitoring: Bool = false) {
        // End any active session before resetting
        handleDistanceZero(isMonitoring: isMonitoring)
        
        // Original reset code
        distance = 0
        tackCount = 0    // Reset tack count when distance is reset
        topSpeed = 0     // Reset top speed when distance is reset
        waypointDistance = 0  // Reset waypoint distance
        waypointIndex = 0     // Reset waypoint index
        
        defaults.set(0, forKey: distanceKey)
        defaults.set(0, forKey: tackCountKey)
        defaults.set(0, forKey: topSpeedKey)
        defaults.set(0, forKey: tackAngleKey)
        defaults.set(0, forKey: waypointDistanceKey)  // Add this
        defaults.set(0, forKey: waypointIndexKey)     // Add this
    }
    
    // Handle when distance becomes zero (reset or otherwise)
    private func handleDistanceZero(isMonitoring: Bool) {
        // If we have an active session, end and save it
        if isCruiseSessionActive && !cruiseSessionDataPoints.isEmpty {
            saveCurrentSessionToJournal()
        }
        
        // Start a new session immediately if GPS is ON
        if isMonitoring {
            startNewCruiseSession()
        }
    }

    // Start a new cruise session
    private func startNewCruiseSession() {
        cruiseSessionStartTime = Date()
        isCruiseSessionActive = true
        cruiseSessionDataPoints.removeAll()
        print("Started new cruise session at \(cruiseSessionStartTime!)")
    }

    // Save the current session to JournalManager
    private func saveCurrentSessionToJournal() {
        guard isCruiseSessionActive, let startTime = cruiseSessionStartTime, !cruiseSessionDataPoints.isEmpty else {
            return
        }
        
        // Get timestamp of last data point as end time
        let endTime = cruiseSessionDataPoints.last?.timestamp ?? Date()
        
        // Calculate duration from start to last recorded point
        let duration = endTime.timeIntervalSince(startTime)
        
        // Get first and last location points for left and right markers
        var leftPoint: LocationData? = nil
        var rightPoint: LocationData? = nil
        
        // Find first data point with location
        for point in cruiseSessionDataPoints {
            if let location = point.location {
                leftPoint = location
                break
            }
        }
        
        // Find last data point with location
        for point in cruiseSessionDataPoints.reversed() {
            if let location = point.location {
                rightPoint = location
                break
            }
        }
        
        // Create a RaceSession (using 999 as marker for cruise session)
        let session = RaceSession(
            date: startTime,
            countdownDuration: 999, // Special marker for cruise session
            raceStartTime: startTime, // Using start time as race start
            raceDuration: duration,
            dataPoints: cruiseSessionDataPoints,
            leftPoint: leftPoint,  // First GPS location
            rightPoint: rightPoint // Last GPS location
        )
        
        // Save to JournalManager
        JournalManager.shared.addCruiseSessionWithEnrichment(session)
        
        // Reset our session state
        isCruiseSessionActive = false
        cruiseSessionStartTime = nil
        cruiseSessionDataPoints.removeAll()
        
        print("Saved cruise session with duration: \(duration)s and \(cruiseSessionDataPoints.count) data points")
        print("Start location: \(String(describing: leftPoint)), End location: \(String(describing: rightPoint))")
    }

    // Add a location data point to the current session
    func addLocationToSession(speed: Double, location: CLLocation) {
        guard isCruiseSessionActive else { return }
        
        let locationData = LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy
        )
        
        let dataPoint = DataPoint(
            timestamp: Date(),
            heartRate: nil,
            speed: speed,  // Speed in knots
            location: locationData
        )
        
        cruiseSessionDataPoints.append(dataPoint)
    }

    // Handle GPS status changes
    func handleGPSStatusChange(isMonitoring: Bool) {
        if isMonitoring {
            // Always start a new session when GPS turns ON (regardless of distance)
            if !isCruiseSessionActive {
                startNewCruiseSession()
            }
        } else {
            // End session when GPS turns OFF
            endCruiseSession()
        }
    }
}
