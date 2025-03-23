//
//  JournalManager+WeatherWaypoint.swift
//  Regatta
//
//  Created by Chikai Lai on 22/03/2025.
//

#if os(watchOS)
import Foundation
import CoreLocation

extension JournalManager {
    // Enhanced version of recordSessionEnd that includes weather and waypoint data
    func recordSessionEndWithEnrichment(totalTime: TimeInterval) {
        guard let session = currentSession else {
            print("📓 No current session to record")
            return
        }
        
        // Get weather data
        let weatherManager = WeatherManager()
        let weatherSpeed = weatherManager.windSpeed
        let weatherDirection = weatherManager.windDirection
        let weatherCardinalDirection = weatherManager.cardinalDirection
        let weatherTemperature = weatherManager.currentTemp
        let weatherCondition = weatherManager.condition
        
        // Get waypoint data
        let waypointManager = ActiveWaypointManager.shared
        let planActive = waypointManager.routeStarted
        
        var activePlanName: String? = nil
        var completedWaypointsCount: Int? = nil
        var totalWaypointsCount: Int? = nil
        var planCompletionPercentage: Double? = nil
        var waypointRecords: [WaypointRecord]? = nil
        
        if planActive {
            completedWaypointsCount = waypointManager.activeWaypointIndex
            totalWaypointsCount = waypointManager.totalSegments
            planCompletionPercentage = waypointManager.overallProgress * 100
            
            // Try to get plan name from UserDefaults
            activePlanName = UserDefaults.standard.string(forKey: "currentPlanName") ?? "Active Plan"
            
            // Get ALL waypoints from the WatchCruisePlanState
            // First, get the current plan data from UserDefaults
            if let planData = UserDefaults.standard.data(forKey: "currentCruisePlan"),
               let planPoints = try? JSONDecoder().decode([WatchPlanPoint].self, from: planData) {
                
                // Sort by order
                let sortedPoints = planPoints.sorted(by: { $0.order < $1.order })
                
                // Convert to WaypointRecords with completion status based on active waypoint index
                waypointRecords = sortedPoints.map { point -> WaypointRecord in
                    // Determine if this waypoint has been completed
                    let isCompleted = point.order < waypointManager.activeWaypointIndex
                    
                    // For the active waypoint, use current progress percentage
                    let isActiveWaypoint = point.order == waypointManager.activeWaypointIndex - 1
                    let progress = isActiveWaypoint ? waypointManager.currentSegmentProgress : nil
                    
                    // Get distance from previous waypoint if available
                    var distanceFromPrevious: Double? = nil
                    if point.order > 0, point.order < sortedPoints.count {
                        let previousPoint = sortedPoints[point.order - 1]
                        let previousLocation = CLLocation(
                            latitude: previousPoint.latitude,
                            longitude: previousPoint.longitude
                        )
                        let currentLocation = CLLocation(
                            latitude: point.latitude,
                            longitude: point.longitude
                        )
                        distanceFromPrevious = previousLocation.distance(from: currentLocation)
                    }
                    
                    return WaypointRecord(
                        latitude: point.latitude,
                        longitude: point.longitude,
                        order: point.order,
                        completed: isCompleted,
                        reachedAt: isCompleted ? Date() : nil, // We don't know exact time
                        distanceFromPrevious: distanceFromPrevious,
                        timeFromPrevious: nil,
                        progress: progress,
                        isActiveWaypoint: isActiveWaypoint
                    )
                }
            } else if let waypoint = waypointManager.activeWaypoint {
                // Fallback to just using the active waypoint if we can't get the full plan
                let currentRecord = WaypointRecord(
                    latitude: waypoint.latitude,
                    longitude: waypoint.longitude,
                    order: waypoint.order,
                    completed: false,
                    reachedAt: nil,
                    distanceFromPrevious: nil,
                    timeFromPrevious: nil,
                    progress: waypointManager.currentSegmentProgress,
                    isActiveWaypoint: true
                )
                
                waypointRecords = [currentRecord]
            }
        }
        
        // Get start line points from UserDefaults directly
        var leftPoint: LocationData? = nil
        var rightPoint: LocationData? = nil
        
        // This approach doesn't rely on the private StoredPoint
        if let leftData = UserDefaults.standard.data(forKey: "leftPoint"),
           let leftDict = try? JSONSerialization.jsonObject(with: leftData) as? [String: Any],
           let lat = leftDict["lat"] as? Double,
           let lon = leftDict["lon"] as? Double {
            leftPoint = LocationData(
                latitude: lat,
                longitude: lon,
                accuracy: 0
            )
        }
        
        if let rightData = UserDefaults.standard.data(forKey: "rightPoint"),
           let rightDict = try? JSONSerialization.jsonObject(with: rightData) as? [String: Any],
           let lat = rightDict["lat"] as? Double,
           let lon = rightDict["lon"] as? Double {
            rightPoint = LocationData(
                latitude: lat,
                longitude: lon,
                accuracy: 0
            )
        }
        
        // Create our enriched session
        // Note: We don't have access to sessionDataPoints, so we'll use what's in the current session
        let enrichedSession = RaceSession(
            date: session.date,
            countdownDuration: session.countdownDuration,
            raceStartTime: session.raceStartTime,
            raceDuration: totalTime,
            dataPoints: session.dataPoints,  // Use existing data points
            leftPoint: leftPoint,
            rightPoint: rightPoint,
            windSpeed: weatherSpeed,
            windDirection: weatherDirection,
            windCardinalDirection: weatherCardinalDirection,
            temperature: weatherTemperature,
            weatherCondition: weatherCondition,
            activePlanName: activePlanName,
            planActive: planActive,
            completedWaypointsCount: completedWaypointsCount,
            totalWaypointsCount: totalWaypointsCount,
            planCompletionPercentage: planCompletionPercentage,
            waypoints: waypointRecords
        )
        
        // Use the public API to clear the current session
        cancelSession()
        
        // Manually add our enriched session to the shared container
        // This will trigger a refresh of allSessions without us needing to access it directly
        var sessions = SharedDefaults.loadSessionsFromContainer() ?? []
        sessions.append(enrichedSession)
        SharedDefaults.saveSessionsToContainer(sessions)
        
        // Notify observers
        objectWillChange.send()
        
        print("📓 Recording enriched session with duration: \(totalTime)")
        
        // Request a transfer to iOS
        #if os(watchOS)
        WatchSessionManager.shared.transferSessions([enrichedSession])
        #endif
    }
    
    // Enhanced version of addCruiseSession that includes weather and waypoint data
    func addCruiseSessionWithEnrichment(_ baseSession: RaceSession) {
        // Get weather data
        let weatherManager = WeatherManager()
        let weatherSpeed = weatherManager.windSpeed
        let weatherDirection = weatherManager.windDirection
        let weatherCardinalDirection = weatherManager.cardinalDirection
        let weatherTemperature = weatherManager.currentTemp
        let weatherCondition = weatherManager.condition
        
        // Get waypoint data
        let waypointManager = ActiveWaypointManager.shared
        let planActive = waypointManager.routeStarted
        
        var activePlanName: String? = nil
        var completedWaypointsCount: Int? = nil
        var totalWaypointsCount: Int? = nil
        var planCompletionPercentage: Double? = nil
        var waypointRecords: [WaypointRecord]? = nil
        
        if planActive {
            completedWaypointsCount = waypointManager.activeWaypointIndex
            totalWaypointsCount = waypointManager.totalSegments
            planCompletionPercentage = waypointManager.overallProgress * 100
            
            // Try to get plan name from UserDefaults
            activePlanName = UserDefaults.standard.string(forKey: "currentPlanName") ?? "Active Plan"
            
            // Get ALL waypoints from the WatchCruisePlanState
            // First, get the current plan data from UserDefaults
            if let planData = UserDefaults.standard.data(forKey: "currentCruisePlan"),
               let planPoints = try? JSONDecoder().decode([WatchPlanPoint].self, from: planData) {
                
                // Sort by order
                let sortedPoints = planPoints.sorted(by: { $0.order < $1.order })
                
                // Convert to WaypointRecords with completion status based on active waypoint index
                waypointRecords = sortedPoints.map { point -> WaypointRecord in
                    // Determine if this waypoint has been completed
                    let isCompleted = point.order < waypointManager.activeWaypointIndex
                    
                    // For the active waypoint, use current progress percentage
                    let isActiveWaypoint = point.order == waypointManager.activeWaypointIndex - 1
                    let progress = isActiveWaypoint ? waypointManager.currentSegmentProgress : nil
                    
                    // Get distance from previous waypoint if available
                    var distanceFromPrevious: Double? = nil
                    if point.order > 0, point.order < sortedPoints.count {
                        let previousPoint = sortedPoints[point.order - 1]
                        let previousLocation = CLLocation(
                            latitude: previousPoint.latitude,
                            longitude: previousPoint.longitude
                        )
                        let currentLocation = CLLocation(
                            latitude: point.latitude,
                            longitude: point.longitude
                        )
                        distanceFromPrevious = previousLocation.distance(from: currentLocation)
                    }
                    
                    return WaypointRecord(
                        latitude: point.latitude,
                        longitude: point.longitude,
                        order: point.order,
                        completed: isCompleted,
                        reachedAt: isCompleted ? Date() : nil, // We don't know exact time
                        distanceFromPrevious: distanceFromPrevious,
                        timeFromPrevious: nil,
                        progress: progress,
                        isActiveWaypoint: isActiveWaypoint
                    )
                }
            } else if let waypoint = waypointManager.activeWaypoint {
                // Fallback to just using the active waypoint if we can't get the full plan
                let currentRecord = WaypointRecord(
                    latitude: waypoint.latitude,
                    longitude: waypoint.longitude,
                    order: waypoint.order,
                    completed: false,
                    reachedAt: nil,
                    distanceFromPrevious: nil,
                    timeFromPrevious: nil,
                    progress: waypointManager.currentSegmentProgress,
                    isActiveWaypoint: true
                )
                
                waypointRecords = [currentRecord]
            }
        }
        
        // Create an enriched version of the provided session
        let enrichedSession = RaceSession(
            date: baseSession.date,
            countdownDuration: baseSession.countdownDuration,
            raceStartTime: baseSession.raceStartTime,
            raceDuration: baseSession.raceDuration,
            dataPoints: baseSession.dataPoints,
            leftPoint: baseSession.leftPoint,
            rightPoint: baseSession.rightPoint,
            windSpeed: weatherSpeed,
            windDirection: weatherDirection,
            windCardinalDirection: weatherCardinalDirection,
            temperature: weatherTemperature,
            weatherCondition: weatherCondition,
            activePlanName: activePlanName,
            planActive: planActive,
            completedWaypointsCount: completedWaypointsCount,
            totalWaypointsCount: totalWaypointsCount,
            planCompletionPercentage: planCompletionPercentage,
            waypoints: waypointRecords
        )
        
        // Use the original method to add the enriched session
        addCruiseSession(enrichedSession)
    }
}
#endif
