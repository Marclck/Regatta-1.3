//
//  SessionManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on [Date]
//

import Foundation
import CoreLocation

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    private init() {} // Prevent external instantiation
    
    private var sessionDataPoints: [DataPoint] = []
    private var sessionStartTime: Date? = nil
    private var isSessionActive: Bool = false
    private var countdownMinutes: Int = 0 // Store countdown duration
    
    // Start a new GPS session - only called when timer actually starts
    func startSession(countdownMinutes: Int) {
        guard !isSessionActive else { return }
        
        sessionStartTime = Date()
        isSessionActive = true
        sessionDataPoints.removeAll()
        self.countdownMinutes = countdownMinutes // Store for later use
        
        // Don't create JournalManager session here - we'll manage everything ourselves
        print("🟢 AltGPSSessionManager: Started new GPS session with \(countdownMinutes) min countdown at \(sessionStartTime!)")
    }
    
    // Mark when the race actually starts (countdown ends)
    private var raceStartTime: Date? = nil
    
    // Record race start when timer transitions to stopwatch
    func recordRaceStart() {
        guard isSessionActive else { return }
        raceStartTime = Date()
        print("🟢 AltGPSSessionManager: Recorded race start at \(raceStartTime!)")
    }
    
    // End the current GPS session and save it - only called when timer is reset
    func endSession(totalTime: TimeInterval, lastReadingManager: LastReadingManager) {
        guard isSessionActive, let startTime = sessionStartTime else {
            print("🔴 AltGPSSessionManager: No active session to end")
            return
        }
        
        // Read start line points from UserDefaults
        let defaults = UserDefaults.standard
        var leftPoint: LocationData? = nil
        var rightPoint: LocationData? = nil
        
        // Load left point from UserDefaults
        if let leftData = defaults.data(forKey: "leftPoint") {
            do {
                let leftLocationPoint = try JSONDecoder().decode(StartLineManager.LocationPoint.self, from: leftData)
                leftPoint = LocationData(
                    latitude: leftLocationPoint.coordinate.latitude,
                    longitude: leftLocationPoint.coordinate.longitude,
                    accuracy: -1.0 // Use -1 to indicate manually set start line point
                )
            } catch {
                print("❌ Error loading left start line point: \(error)")
            }
        }
        
        // Load right point from UserDefaults
        if let rightData = defaults.data(forKey: "rightPoint") {
            do {
                let rightLocationPoint = try JSONDecoder().decode(StartLineManager.LocationPoint.self, from: rightData)
                rightPoint = LocationData(
                    latitude: rightLocationPoint.coordinate.latitude,
                    longitude: rightLocationPoint.coordinate.longitude,
                    accuracy: -1.0 // Use -1 to indicate manually set start line point
                )
            } catch {
                print("❌ Error loading right start line point: \(error)")
            }
        }
        
        // Create a complete RaceSession from our collected data
        let session = RaceSession(
            date: startTime,
            countdownDuration: countdownMinutes,
            raceStartTime: raceStartTime, // This will be nil if race never started
            raceDuration: totalTime,
            dataPoints: sessionDataPoints, // All our collected GPS data
            leftPoint: leftPoint,  // From StartLineManager
            rightPoint: rightPoint // From StartLineManager
        )
        
        // Save the complete session to JournalManager with enrichment
        JournalManager.shared.addCruiseSessionWithEnrichment(session, lastReadingManager: lastReadingManager)
        
        // Reset session state
        isSessionActive = false
        sessionStartTime = nil
        raceStartTime = nil
        sessionDataPoints.removeAll()
        countdownMinutes = 0
        
        print("🟢 AltGPSSessionManager: Ended GPS session with total time: \(totalTime)s and \(sessionDataPoints.count) data points")
    }
    
    // Cancel session without saving - called when timer is cancelled
    func cancelSession() {
        guard isSessionActive else { return }
        
        // Simply reset our state - don't save anything
        isSessionActive = false
        sessionStartTime = nil
        raceStartTime = nil
        sessionDataPoints.removeAll()
        
        print("🟢 AltGPSSessionManager: Cancelled GPS session")
    }
    
    // Add GPS data to current session - manages all data collection internally
    func addDataPointToSession(heartRate: Int?, speed: Double, location: CLLocation?) {
        guard isSessionActive else { return }
        
        let locationData = location.map { loc in
            LocationData(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                accuracy: loc.horizontalAccuracy
            )
        }
        
        let dataPoint = DataPoint(
            timestamp: Date(),
            heartRate: heartRate,
            speed: speed,
            location: locationData
        )
        
        sessionDataPoints.append(dataPoint)
        
        // Debug logging every 10 data points
        if sessionDataPoints.count % 10 == 0 {
            print("🟢 AltGPSSessionManager: Collected \(sessionDataPoints.count) data points")
        }
    }
    
    // Get first location for left point
    private func getFirstLocation() -> LocationData? {
        for point in sessionDataPoints {
            if let location = point.location {
                return location
            }
        }
        return nil
    }
    
    // Get last location for right point
    private func getLastLocation() -> LocationData? {
        for point in sessionDataPoints.reversed() {
            if let location = point.location {
                return location
            }
        }
        return nil
    }
    
    var hasActiveSession: Bool {
        return isSessionActive
    }
    
    var dataPointCount: Int {
        return sessionDataPoints.count
    }
    
    var sessionDuration: TimeInterval? {
        guard let startTime = sessionStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
}
