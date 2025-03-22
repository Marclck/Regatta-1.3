//
//  WaypointProgressBarView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 18/03/2025.
//

import Foundation
import SwiftUI
import CoreLocation

struct WaypointProgressBarView: View {
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var plannerManager: WatchPlannerDataManager
    @ObservedObject var locationManager: LocationManager
    @EnvironmentObject var cruisePlanState: WatchCruisePlanState
    
    // Reference to the active waypoint manager for sharing data
    private let activeWaypointManager = ActiveWaypointManager.shared

    // Current segment being tracked (0-indexed)
    @State private var currentSegment: Int = 0
    // Progress value for current segment (0.0 to 1.0)
    @State private var segmentProgress: Double = 0.0
    // Overall progress value (0.0 to 1.0)
    @State private var overallProgress: Double = 0.0
    @State private var currentSecond: Double = 0

    // Timer for updates, similar to SecondProgressBarView
    @State private var timer = Timer.publish(every: AppSettings().timerInterval, on: .main, in: .common).autoconnect()

    @State private var segmentStartPoints: [CLLocation] = []
    @State private var routeStarted: Bool = false
    
    private func updateSecond() {
        let components = Calendar.current.dateComponents([.second, .nanosecond], from: Date())
        
        // If timer interval is 1 second, only update on exact seconds
        if settings.timerInterval == 1.0 {
            currentSecond = Double(components.second!)
        } else {
            // For smooth animation, include nanoseconds
            currentSecond = Double(components.second!) + Double(components.nanosecond!) / 1_000_000_000
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            let barWidth = frame.width
            let barHeight = frame.height
            
            ZStack {
                // Background track - reusing style from SecondProgressBarView
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .stroke(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3), lineWidth: 25)
                    .frame(width: barWidth, height: barHeight)
                    .position(x: frame.midX, y: frame.midY)
                
                // Progress fill - reusing style from SecondProgressBarView
                if !locationManager.isMonitoring {
                    // Progress fill for seconds
                        RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                            .trim(from: 0, to: currentSecond/60)
                            .stroke(
                                Color(hex: colorManager.selectedTheme.rawValue),
                                style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                            )
                            .frame(width: barHeight, height: barWidth)
                            .position(x: frame.midX, y: frame.midY)
                            .rotationEffect(.degrees(-90))  // Align trim start to top
                } else {
                    RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                        .trim(from: 0, to: overallProgress)
                        .stroke(
                            Color(hex: colorManager.selectedTheme.rawValue),
                            style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                        )
                        .frame(width: barHeight, height: barWidth)
                        .position(x: frame.midX, y: frame.midY)
                        .rotationEffect(.degrees(-90))  // Align trim start to top
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: overallProgress)
                }
                //12 oclock trim compensator
                RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                    .trim(from: 0, to: 0.002)
                    .stroke(
                        settings.lightMode ? Color.white : Color.black,
                        style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                    )
                    .frame(width: barHeight, height: barWidth)
                    .position(x: frame.midX, y: frame.midY)
                    .rotationEffect(.degrees(-90))
                
                // Segment separators
                ForEach(0..<plannerManager.currentPlan.count + 1, id: \.self) { index in
                    if index > 0 {
                        // Calculate the trim value for each segment separator
                        let segmentCount = Double(plannerManager.currentPlan.count)
                        let segmentTrim = (1.0/segmentCount) * (segmentCount - Double(index) + 1.0)
                        let adjustedTrim = segmentTrim > 1.0 ? segmentTrim - 1.0 : segmentTrim
                        
                        // Create the separator mark
                        RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                            .trim(from: max(0, adjustedTrim - 0.002), to: min(1, adjustedTrim + 0.002))
                            .stroke(
                                settings.lightMode ? Color.white : Color.black,
                                style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                            )
                            .frame(width: barHeight, height: barWidth)
                            .position(x: frame.midX, y: frame.midY)
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Update the active waypoint manager with initial data
            updateActiveWaypointManager()
            
            NotificationCenter.default.addObserver(
                forName: Notification.Name("RequestSegmentCompletion"),
                object: nil,
                queue: .main
            ) { [self] _ in
                completeCurrentSegment()
            }
            
            if let currentLocation = locationManager.lastLocation {
                print("🔍 Location update started: \(String(describing: currentLocation))")
                // Call the same functions that would be called in onReceive
                updateProgress(for: currentLocation)
            } else {
                updateSecond()
            }
        }
        .onReceive(locationManager.$lastLocation) { newLocation in
            print("🔍 Location update received: \(String(describing: newLocation))")
            updateProgress(for: newLocation)
        }
        .onReceive(timer) { _ in
            // Regular timer updates, similar to SecondProgressBarView
//            if let location = locationManager.lastLocation {
//                updateProgress(for: location)
//            }
            updateSecond()
        }
        .onChange(of: cruisePlanState.isActive) { _, isActive in
            if !isActive {
                resetRoute()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name("RequestSegmentCompletion"),
                object: nil
            )
        }
    }
    
    // Update progress based on current GPS location
    private func updateProgress(for location: CLLocation?) {
        guard let currentLocation = location,
              !plannerManager.currentPlan.isEmpty else {
            return
        }
        
        // Convert waypoints to array of CLLocation objects
        let waypoints = plannerManager.currentPlan.map { waypoint in
            CLLocation(latitude: waypoint.latitude, longitude: waypoint.longitude)
        }
        
        // Create segments only once when we start the route
        if !routeStarted {
            segmentStartPoints = [currentLocation] + waypoints
            routeStarted = true
            print("🛣️ Route started with \(segmentStartPoints.count) points")
        }
        
        // Create segments using stored start points
        var segments: [(start: CLLocation, end: CLLocation)] = []
        
        // Create segments from saved points
        if segmentStartPoints.count >= 2 {
            for i in 0..<segmentStartPoints.count-1 {
                segments.append((segmentStartPoints[i], segmentStartPoints[i+1]))
            }
        }
        
        
        print("Segments created: \(segments.count)")
        segments.enumerated().forEach { (i, segment) in
            print("Segment \(i): \(segment.start.coordinate) to \(segment.end.coordinate)")
        }
        
        // Ensure we have segments to work with
        guard !segments.isEmpty else { return }
        
        // INSERT THE NEW CODE HERE - Distance-based waypoint threshold check
        let distanceToWaypointThreshold = 15.0 // meters
        if currentSegment < segmentStartPoints.count - 2 {
            let waypointLocation = segmentStartPoints[currentSegment + 1]
            if currentLocation.distance(from: waypointLocation) < distanceToWaypointThreshold {
                print("🏁 Reached waypoint threshold, advancing segment")
                currentSegment += 1
                self.segmentProgress = 0.0
                updateProgress(for: location)
                return
            }
        }
        
        // Calculate progress within the current segment
        let segmentProgress = calculateSegmentProgress(
            currentLocation: currentLocation,
            segment: segments[currentSegment]
        )
        
        // Check if we need to advance to next segment
        if segmentProgress >= 1.0 && currentSegment < segments.count - 1 {
            currentSegment += 1
            self.segmentProgress = 0.0
            // Recalculate with new segment
            updateProgress(for: location)
            return
        }
        
        self.segmentProgress = segmentProgress
        
        // Calculate overall progress
        if segments.isEmpty {
            overallProgress = 0.0
        } else {
            let segmentSize = 1.0 / Double(segments.count)
            overallProgress = (Double(currentSegment) * segmentSize) + (segmentProgress * segmentSize)
        }
        print("✅ Progress calculated: \(overallProgress)")
        
        // Update the active waypoint manager with the new data
        updateActiveWaypointManager()
        
        var activeWaypoint: WatchPlanPoint? = nil
        if currentSegment < plannerManager.currentPlan.count {
            activeWaypoint = plannerManager.currentPlan[currentSegment]
        }

        // Then update the direction manager
        if cruisePlanState.isActive && currentLocation != nil && activeWaypoint != nil {
            // Get the waypoint coordinate
            let waypointCoordinate = CLLocationCoordinate2D(
                latitude: activeWaypoint!.latitude,
                longitude: activeWaypoint!.longitude
            )
            
            // Calculate bearing to active waypoint
            let bearing = WaypointDirectionManager.shared.calculateBearing(
                from: currentLocation.coordinate,
                to: waypointCoordinate
            )
            
            // Calculate distance to waypoint
            let waypointLocation = CLLocation(
                latitude: activeWaypoint!.latitude,
                longitude: activeWaypoint!.longitude
            )
            let distance = currentLocation.distance(from: waypointLocation)
            
            // Update direction manager
            WaypointDirectionManager.shared.updateDirectionData(
                isActive: true,
                waypointBearing: bearing,
                distanceToWaypoint: distance,
                activeWaypoint: activeWaypoint,
                currentLocation: currentLocation
            )
            
            print("💫 Direction manager updated with active waypoint \(activeWaypoint!.order)")
        } else {
            // Only reset if cruise plan is inactive
            if !cruisePlanState.isActive {
                WaypointDirectionManager.shared.reset()
            }
            
            print("⚠️ Cannot update direction manager: active=\(cruisePlanState.isActive), location=\(currentLocation != nil), waypoint=\(activeWaypoint != nil)")
        }
    }
    
    // Calculate progress within a segment based on projection
    private func calculateSegmentProgress(
        currentLocation: CLLocation,
        segment: (start: CLLocation, end: CLLocation)
    ) -> Double {
        // Get coordinates
        let x = currentLocation.coordinate.longitude
        let y = currentLocation.coordinate.latitude
        let x1 = segment.start.coordinate.longitude
        let y1 = segment.start.coordinate.latitude
        let x2 = segment.end.coordinate.longitude
        let y2 = segment.end.coordinate.latitude
        
        // Calculate projection onto the segment line
        let dx = x2 - x1
        let dy = y2 - y1
        
        // Handle case where start and end points are the same
        if dx == 0 && dy == 0 {
            return 0.0
        }
        
        // Calculate the projection parameter t
        let numerator = (x - x1) * dx + (y - y1) * dy
        let denominator = dx * dx + dy * dy
        print("Projection calc: (x-x1)=\(x-x1), dx=\(dx), (y-y1)=\(y-y1), dy=\(dy)")
        print("Numerator: \(numerator), Denominator: \(denominator)")
        let t = numerator / denominator
        print("Projection param t: \(t), clampedT: \(max(0, min(1, t)))")
        
        // Clamp t to [0, 1]
        let clampedT = max(0, min(1, t))
        
        // Check if projection point is outside the segment
        if clampedT <= 0 {
            // Closer to start point, return 0%
            return 0.0
        } else if clampedT >= 1 {
            // Closer to end point, return 100%
            return 1.0
        }
        
        // Calculate projection point coordinates
        let projX = x1 + clampedT * dx
        let projY = y1 + clampedT * dy
        
        // Create projection point location
        let projectionPoint = CLLocation(
            latitude: projY,
            longitude: projX
        )
        
        // Calculate distances
        let distanceFromStart = segment.start.distance(from: projectionPoint)
        let totalDistance = segment.start.distance(from: segment.end)
        
        print("Distance from start: \(distanceFromStart), total distance: \(totalDistance)")
        
        // Calculate progress as percentage of total distance
        return totalDistance > 0 ? distanceFromStart / totalDistance : 0.0
    }
    
    // MARK: - Route Management
    
    func resetRoute() {
        routeStarted = false
        segmentStartPoints = []
        currentSegment = 0
        segmentProgress = 0.0
        overallProgress = 0.0
        
        // Also reset the ActiveWaypointManager
        activeWaypointManager.reset()
        
        WaypointDirectionManager.shared.reset()
    }
    
    // MARK: - Active Waypoint Manager Updates
    
    /// Updates the ActiveWaypointManager with the latest progress and waypoint information
    private func updateActiveWaypointManager() {
        var activeWaypoint: WatchPlanPoint? = nil
        
        // Determine the active waypoint (end point of current segment)
        // currentSegment is the 0-indexed segment we're currently traveling on
        // The destination is the next point in the plan
        if !plannerManager.currentPlan.isEmpty && currentSegment < plannerManager.currentPlan.count {
            activeWaypoint = plannerManager.currentPlan[currentSegment]
        }
        
        // Update the active waypoint manager with the new, expanded parameters
        activeWaypointManager.updateActiveWaypointInfo(
            index: currentSegment,
            waypoint: activeWaypoint,
            segmentProgress: segmentProgress,
            overallProgress: overallProgress,
            totalSegments: plannerManager.currentPlan.count,
            routeStarted: routeStarted,
            segmentStartPoints: segmentStartPoints
        )
    }
    
    // MARK: - Manual Segment Completion
    func completeCurrentSegment() {
        if !routeStarted {
            routeStarted = true
            
            // Initialize segment start points if they're empty
            if segmentStartPoints.isEmpty && !plannerManager.currentPlan.isEmpty {
                // Use a mock starting location if no current location is available
                let startLocation = locationManager.lastLocation ??
                    CLLocation(latitude: plannerManager.currentPlan[0].latitude,
                              longitude: plannerManager.currentPlan[0].longitude)
                
                // Create segment points from available waypoints
                segmentStartPoints = [startLocation] + plannerManager.currentPlan.map { waypoint in
                    CLLocation(latitude: waypoint.latitude, longitude: waypoint.longitude)
                }
                
                print("🛣️ Route initialized with \(segmentStartPoints.count) points")
            }
        }
        
        // Modify guard condition to be less restrictive
        guard segmentStartPoints.count >= 2, currentSegment < segmentStartPoints.count - 2 else {
            print("⚠️ Cannot complete segment: insufficient waypoints or already at last segment")
            return
        }
        
        print("🏁 Manually marking segment \(currentSegment) as complete")
        
        // Advance to next segment
        currentSegment += 1
        segmentProgress = 0.0
        
        // Recalculate overall progress
        if segmentStartPoints.count >= 2 {
            let segmentSize = 1.0 / Double(segmentStartPoints.count - 1)
            overallProgress = (Double(currentSegment) * segmentSize)
        }
        
        // Update the active waypoint manager
        updateActiveWaypointManager()
        
        print("✅ Advanced to segment \(currentSegment), overall progress: \(overallProgress)")
    }
}

// MARK: - Waypoint Direction Manager
class WaypointDirectionManager: ObservableObject {
    static let shared = WaypointDirectionManager()
    
    @Published var isActive: Bool = false
    @Published var waypointBearing: Double = 0.0
    @Published var distanceToWaypoint: Double = 0.0
    @Published var activeWaypoint: WatchPlanPoint?
    @Published var currentLocation: CLLocation?
    
    private init() {}
    
    // Update manager data from WaypointProgressBarView
    func updateDirectionData(
        isActive: Bool,
        waypointBearing: Double,
        distanceToWaypoint: Double,
        activeWaypoint: WatchPlanPoint?,
        currentLocation: CLLocation?
    ) {
        self.isActive = isActive
        self.waypointBearing = waypointBearing
        self.distanceToWaypoint = distanceToWaypoint
        self.activeWaypoint = activeWaypoint
        self.currentLocation = currentLocation
        
        // Print debug info to help troubleshoot
        print("🧭 Direction Manager updated:")
        print("  - Active: \(isActive)")
        print("  - Bearing: \(waypointBearing)°")
        print("  - Distance: \(distanceToWaypoint)m")
        print("  - Waypoint: \(String(describing: activeWaypoint?.order))")
    }
    
    // Calculate bearing between two coordinates (for use in other views)
    func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let dLon = to.longitude - from.longitude
        
        let y = sin(dLon * .pi / 180) * cos(to.latitude * .pi / 180)
        let x = cos(from.latitude * .pi / 180) * sin(to.latitude * .pi / 180) -
                sin(from.latitude * .pi / 180) * cos(to.latitude * .pi / 180) * cos(dLon * .pi / 180)
        
        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 {
            bearing += 360
        }
        
        return bearing
    }
    
    // Reset all data
    func reset() {
        isActive = false
        waypointBearing = 0.0
        distanceToWaypoint = 0.0
        activeWaypoint = nil
        currentLocation = nil
        
        print("🧭 Direction Manager reset")
    }
}

// MARK: - Preview
#if DEBUG
struct WaypointProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        let plannerManager = WatchPlannerDataManager.shared
        let locationManager = LocationManager()
        let settings = AppSettings()
        let colorManager = ColorManager()
        
        // Add some sample waypoints for preview
        if plannerManager.currentPlan.isEmpty {
            // This will only execute if currentPlan is empty during preview
            _ = [
                WatchPlanPoint(id: UUID(), latitude: 37.7749, longitude: -122.4194, accuracy: 10, order: 0),
                WatchPlanPoint(id: UUID(), latitude: 37.7750, longitude: -122.4195, accuracy: 10, order: 1),
                WatchPlanPoint(id: UUID(), latitude: 37.7751, longitude: -122.4196, accuracy: 10, order: 2)
            ]
        }
        
        return WaypointProgressBarView(
            plannerManager: plannerManager,
            locationManager: locationManager
        )
        .environmentObject(settings)
        .environmentObject(colorManager)
    }
}
#endif
