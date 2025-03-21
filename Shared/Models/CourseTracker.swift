//
//  CourseTracker.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 31/01/2025.
//

import Foundation
import Combine
import CoreLocation

class CourseTracker: ObservableObject {
    // Published properties for UI updates
    @Published var lockedCourse: Double?
    @Published var currentDeviation: Double = 0
    @Published var isLocked: Bool = false
    @Published var tackCount: Int = 0
    @Published var previousLockedCourse: Double?  // Store previous locked course
    @Published var tackAngle: Double = 0  // Store the tack angle
    
    // Constants
    private let lockThreshold: Double = 6.0  // degrees
    private let lockDuration: TimeInterval = 6.0  // seconds
    private let maxDeviation: Double = 30.0  // degrees
    
    // Course history tracking
    private var courseHistory: [(timestamp: Date, course: Double)] = []
    private var previousCourse: Double?
    
    func updateCourse(_ newCourse: Double) {
        // Add new course to history
        let now = Date()
        courseHistory.append((now, newCourse))
        
        // Remove old entries (older than lockDuration)
        courseHistory = courseHistory.filter { now.timeIntervalSince($0.timestamp) <= lockDuration }
        
        // Check for tack
        if let lastCourse = previousCourse {
            let courseChange = abs(angleDifference(newCourse, lastCourse))
            if courseChange >= maxDeviation {
                tackCount += 1
            }
        }
        previousCourse = newCourse
        
        if isLocked {
            // Calculate deviation from locked course
            if let lockedCourse = lockedCourse {
                let rawDeviation = angleDifference(newCourse, lockedCourse)
                currentDeviation = min(max(-maxDeviation, rawDeviation), maxDeviation)
                
                // Check if deviation exceeds max, trigger reset
                if abs(currentDeviation) >= maxDeviation {
                    resetLock()
                }
            }
        } else {
            checkForLock()
            
            // Update tack angle if we have a previous locked course
            if let prevLocked = previousLockedCourse {
                tackAngle = calculateTackAngle(currentCourse: newCourse, referenceCourse: prevLocked)
            }
        }
    }
    
    private func checkForLock() {
        // Need at least 5 seconds of data
        guard courseHistory.count >= 3 else { return }
        
        // Calculate max variation in current history
        let courses = courseHistory.map { $0.course }
        let maxVariation = courses.reduce((min: courses[0], max: courses[0])) { result, course in
            (
                min: min(result.min, course),
                max: max(result.max, course)
            )
        }
        
        // Check if variation is within threshold
        if angleDifference(maxVariation.max, maxVariation.min) <= lockThreshold {
            // Calculate average course
            let avgCourse = courses.reduce(0.0, +) / Double(courses.count)
            lockCourse(avgCourse)
        }
    }
    
    private func lockCourse(_ course: Double) {
        lockedCourse = course
        isLocked = true
    }
    
    func resetLock() {
        // Store the current locked course before resetting
        if let currentLocked = lockedCourse {
            previousLockedCourse = currentLocked
            
            // Update tack angle if we have a current course
            if let currentCourse = previousCourse {
                tackAngle = calculateTackAngle(currentCourse: currentCourse, referenceCourse: currentLocked)
            }
        }
        
        lockedCourse = nil
        isLocked = false
        currentDeviation = 0
        courseHistory.removeAll()
    }
    
    func resetTackCount() {
        tackCount = 0
        previousCourse = nil
        tackAngle = 0
        previousLockedCourse = nil
    }
    
    private func angleDifference(_ angle1: Double, _ angle2: Double) -> Double {
        let diff = (angle1 - angle2).truncatingRemainder(dividingBy: 360)
        if diff > 180 {
            return diff - 360
        } else if diff < -180 {
            return diff + 360
        }
        return diff
    }
    
    private func calculateTackAngle(currentCourse: Double, referenceCourse: Double) -> Double {
        let diff = abs(angleDifference(currentCourse, referenceCourse))
        return min(diff, 360 - diff) // Returns the smaller angle (always less than 180)
    }
}
