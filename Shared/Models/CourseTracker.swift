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
    
    // Constants
    private let lockThreshold: Double = 6.0  // degrees
    private let lockDuration: TimeInterval = 2.0  // seconds
    private let maxDeviation: Double = 30.0  // degrees
    
    // Course history tracking
    private var courseHistory: [(timestamp: Date, course: Double)] = []
    private var lockTimer: Timer?
    
    func updateCourse(_ newCourse: Double) {
        // Add new course to history
        let now = Date()
        courseHistory.append((now, newCourse))
        
        // Remove old entries (older than lockDuration)
        courseHistory = courseHistory.filter { now.timeIntervalSince($0.timestamp) <= lockDuration }
        
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
        }
    }
    
    private func checkForLock() {
        // Need at least 5 seconds of data
        guard courseHistory.count >= 5 else { return }
        
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
        lockedCourse = nil
        isLocked = false
        currentDeviation = 0
        courseHistory.removeAll()
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
}
