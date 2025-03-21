//
//  ActiveWaypointManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 19/03/2025.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

/// Class to manage and expose information about the active waypoint from WaypointProgressBarView
class ActiveWaypointManager: ObservableObject {
    // Shared instance for app-wide access
    static let shared = ActiveWaypointManager()
    
    // MARK: - UserDefaults Keys
    private struct Keys {
        static let activeWaypointIndex = "activeWaypointIndex"
        static let activeWaypointID = "activeWaypointID"
        static let currentSegmentProgress = "currentSegmentProgress"
        static let overallProgress = "overallProgress"
        static let totalSegments = "totalSegments"
        static let routeStarted = "routeStarted"
        static let activeWaypointLatitude = "activeWaypointLatitude"
        static let activeWaypointLongitude = "activeWaypointLongitude"
        static let activeWaypointOrder = "activeWaypointOrder"
    }
    
    // MARK: - Published Properties
    
    /// The index of the active waypoint (starting from 1, representing the end point of current segment)
    @Published var activeWaypointIndex: Int = 0 {
        didSet {
            UserDefaults.standard.set(activeWaypointIndex, forKey: Keys.activeWaypointIndex)
        }
    }
    
    /// The original WatchPlanPoint data for the active waypoint
    @Published var activeWaypoint: WatchPlanPoint? {
        didSet {
            if let waypoint = activeWaypoint {
                UserDefaults.standard.set(waypoint.id.uuidString, forKey: Keys.activeWaypointID)
                UserDefaults.standard.set(waypoint.latitude, forKey: Keys.activeWaypointLatitude)
                UserDefaults.standard.set(waypoint.longitude, forKey: Keys.activeWaypointLongitude)
                UserDefaults.standard.set(waypoint.order, forKey: Keys.activeWaypointOrder)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.activeWaypointID)
                UserDefaults.standard.removeObject(forKey: Keys.activeWaypointLatitude)
                UserDefaults.standard.removeObject(forKey: Keys.activeWaypointLongitude)
                UserDefaults.standard.removeObject(forKey: Keys.activeWaypointOrder)
            }
        }
    }
    
    /// Current progress to the active waypoint (0.0 to 1.0)
    @Published var currentSegmentProgress: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(currentSegmentProgress, forKey: Keys.currentSegmentProgress)
        }
    }
    
    /// Overall progress through all waypoints (0.0 to 1.0)
    @Published var overallProgress: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(overallProgress, forKey: Keys.overallProgress)
        }
    }
    
    /// Total number of segments in the current plan
    @Published var totalSegments: Int = 0 {
        didSet {
            UserDefaults.standard.set(totalSegments, forKey: Keys.totalSegments)
        }
    }
    
    /// Location of the active waypoint
    @Published var activeWaypointLocation: CLLocation?
    
    /// Whether the route has been started
    @Published var routeStarted: Bool = false {
        didSet {
            UserDefaults.standard.set(routeStarted, forKey: Keys.routeStarted)
        }
    }
    
    /// The starting points for each segment of the route
    @Published var segmentStartPoints: [CLLocation] = []
    
    // Private initializer to enforce singleton pattern
    private init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Public Methods
    
    /// Updates all active waypoint information at once
    /// - Parameters:
    ///   - index: Index of the active waypoint (end point of current segment)
    ///   - waypoint: The WatchPlanPoint data for the active waypoint
    ///   - segmentProgress: Progress to the active waypoint (0.0 to 1.0)
    ///   - overallProgress: Overall progress through all waypoints (0.0 to 1.0)
    ///   - totalSegments: Total number of segments in the current plan
    ///   - routeStarted: Whether the route has been started
    ///   - segmentStartPoints: The starting points for each segment of the route
    func updateActiveWaypointInfo(
        index: Int,
        waypoint: WatchPlanPoint?,
        segmentProgress: Double,
        overallProgress: Double,
        totalSegments: Int,
        routeStarted: Bool,
        segmentStartPoints: [CLLocation]
    ) {
        self.activeWaypointIndex = index + 1 // Converting from 0-indexed to 1-indexed for display
        self.activeWaypoint = waypoint
        self.currentSegmentProgress = segmentProgress
        self.overallProgress = overallProgress
        self.totalSegments = totalSegments
        self.routeStarted = routeStarted
        self.segmentStartPoints = segmentStartPoints
        
        // Update location if waypoint is available
        if let waypoint = waypoint {
            self.activeWaypointLocation = CLLocation(
                latitude: waypoint.latitude,
                longitude: waypoint.longitude
            )
        } else {
            self.activeWaypointLocation = nil
        }
        
        // Save all changes to UserDefaults
        saveToUserDefaults()
    }
    
    /// Resets all active waypoint information
    func reset() {
        activeWaypointIndex = 0
        activeWaypoint = nil
        currentSegmentProgress = 0.0
        overallProgress = 0.0
        totalSegments = 0
        activeWaypointLocation = nil
        routeStarted = false
        segmentStartPoints = []
        
        // Clear UserDefaults
        clearUserDefaults()
    }
    
    /// Request to complete the current segment via notification
    func requestSegmentCompletion() {
        NotificationCenter.default.post(
            name: Notification.Name("RequestSegmentCompletion"),
            object: nil
        )
    }
    
    // MARK: - UserDefaults Handling
    
    /// Save all current state to UserDefaults
    private func saveToUserDefaults() {
        UserDefaults.standard.set(activeWaypointIndex, forKey: Keys.activeWaypointIndex)
        UserDefaults.standard.set(currentSegmentProgress, forKey: Keys.currentSegmentProgress)
        UserDefaults.standard.set(overallProgress, forKey: Keys.overallProgress)
        UserDefaults.standard.set(totalSegments, forKey: Keys.totalSegments)
        UserDefaults.standard.set(routeStarted, forKey: Keys.routeStarted)
        
        // Save waypoint data if available
        if let waypoint = activeWaypoint {
            UserDefaults.standard.set(waypoint.id.uuidString, forKey: Keys.activeWaypointID)
            UserDefaults.standard.set(waypoint.latitude, forKey: Keys.activeWaypointLatitude)
            UserDefaults.standard.set(waypoint.longitude, forKey: Keys.activeWaypointLongitude)
            UserDefaults.standard.set(waypoint.order, forKey: Keys.activeWaypointOrder)
        }
        
        // Note: We don't save segmentStartPoints as CLLocation array
        // can't be directly saved to UserDefaults
    }
    
    /// Load all state from UserDefaults
    private func loadFromUserDefaults() {
        // Load basic values
        activeWaypointIndex = UserDefaults.standard.integer(forKey: Keys.activeWaypointIndex)
        currentSegmentProgress = UserDefaults.standard.double(forKey: Keys.currentSegmentProgress)
        overallProgress = UserDefaults.standard.double(forKey: Keys.overallProgress)
        totalSegments = UserDefaults.standard.integer(forKey: Keys.totalSegments)
        routeStarted = UserDefaults.standard.bool(forKey: Keys.routeStarted)
        
        // Try to reconstruct waypoint if data exists
        if let waypointIdString = UserDefaults.standard.string(forKey: Keys.activeWaypointID),
           let waypointId = UUID(uuidString: waypointIdString) {
            
            let latitude = UserDefaults.standard.double(forKey: Keys.activeWaypointLatitude)
            let longitude = UserDefaults.standard.double(forKey: Keys.activeWaypointLongitude)
            let order = UserDefaults.standard.integer(forKey: Keys.activeWaypointOrder)
            
            // Create a waypoint from stored data
            activeWaypoint = WatchPlanPoint(
                id: waypointId,
                latitude: latitude,
                longitude: longitude,
                accuracy: nil,
                order: order
            )
            
            // Also update the location
            activeWaypointLocation = CLLocation(latitude: latitude, longitude: longitude)
        }
    }
    
    /// Clear all related UserDefaults values
    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: Keys.activeWaypointIndex)
        UserDefaults.standard.removeObject(forKey: Keys.activeWaypointID)
        UserDefaults.standard.removeObject(forKey: Keys.currentSegmentProgress)
        UserDefaults.standard.removeObject(forKey: Keys.overallProgress)
        UserDefaults.standard.removeObject(forKey: Keys.totalSegments)
        UserDefaults.standard.removeObject(forKey: Keys.routeStarted)
        UserDefaults.standard.removeObject(forKey: Keys.activeWaypointLatitude)
        UserDefaults.standard.removeObject(forKey: Keys.activeWaypointLongitude)
        UserDefaults.standard.removeObject(forKey: Keys.activeWaypointOrder)
    }
}
