//
//  ActiveWaypointManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 19/03/2025.
//

import Foundation
import Foundation
import CoreLocation
import SwiftUI
import Combine

/// Class to manage and expose information about the active waypoint from WaypointProgressBarView
class ActiveWaypointManager: ObservableObject {
    // Shared instance for app-wide access
    static let shared = ActiveWaypointManager()
    
    // MARK: - Published Properties
    
    /// The index of the active waypoint (starting from 1, representing the end point of current segment)
    @Published var activeWaypointIndex: Int = 0
    
    /// The original WatchPlanPoint data for the active waypoint
    @Published var activeWaypoint: WatchPlanPoint?
    
    /// Current progress to the active waypoint (0.0 to 1.0)
    @Published var currentSegmentProgress: Double = 0.0
    
    /// Overall progress through all waypoints (0.0 to 1.0)
    @Published var overallProgress: Double = 0.0
    
    /// Total number of segments in the current plan
    @Published var totalSegments: Int = 0
    
    /// Location of the active waypoint
    @Published var activeWaypointLocation: CLLocation?
    
    /// Whether the route has been started
    @Published var routeStarted: Bool = false
    
    /// The starting points for each segment of the route
    @Published var segmentStartPoints: [CLLocation] = []
    
    // Private initializer to enforce singleton pattern
    private init() {}
    
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
    }
    
    func requestSegmentCompletion() {
        NotificationCenter.default.post(
            name: Notification.Name("RequestSegmentCompletion"),
            object: nil
        )
    }
}
