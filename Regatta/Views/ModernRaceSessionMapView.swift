//
//  ModernRaceSessionMapView.swift
//  Regatta
//
//  Created by Chikai Lai on 27/03/2025.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

struct ModernRaceSessionMapView: View {
    // Regular stored properties
    private let session: RaceSession
    private let validLocationPoints: [(location: CLLocationCoordinate2D, speed: Double)]
    private let maxSpeed: Double
    private let hasStartLine: Bool
    
    // State properties
    @State private var position: MapCameraPosition
    @State private var mapSelection: MKMapItem?
    @State private var selectedMapStyle: MapStyleConfiguration = .hybrid
    @State private var isInteractionEnabled: Bool = true
    @State private var showDetailView: Bool = false
    @State private var showMapStyleControls: Bool = false
    @State private var showFullScreenMap: Bool = false
    @State private var showWaypointAnnotations: Bool = false // New state for waypoint toggle
    @Environment(\.dismiss) private var dismiss
    
    @State private var filteredLocationPoints: [(location: CLLocationCoordinate2D, speed: Double)] = []
    @State private var currentZoomLevel: Double? = nil
    private let maxDisplayPoints = 500
    @State private var previousPositionState: MapCameraPosition?
    @State private var zoomLevelState: Double = 1.0
    
    // Computed stats from SessionRowView
    private var raceStats: (topSpeed: Double?, avgSpeed: Double?, totalDistance: CLLocationDistance?) {
        guard let raceStartTime = session.raceStartTime else {
            return (nil, nil, nil)
        }
        
        let raceDataPoints = session.dataPoints.filter { $0.timestamp >= raceStartTime }
        let topSpeed = raceDataPoints.compactMap { $0.speed }.max()
        
        var avgSpeed: Double? = nil
        var totalDistance: CLLocationDistance? = nil
        
        if let raceDuration = session.raceDuration,
           raceDuration > 0 {
            let locations = raceDataPoints.compactMap { point -> CLLocationCoordinate2D? in
                guard let loc = point.location else { return nil }
                return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            }
            
            if locations.count >= 2 {
                var distanceSum: CLLocationDistance = 0
                for i in 0..<(locations.count - 1) {
                    let loc1 = CLLocation(latitude: locations[i].latitude, longitude: locations[i].longitude)
                    let loc2 = CLLocation(latitude: locations[i + 1].latitude, longitude: locations[i + 1].longitude)
                    distanceSum += loc1.distance(from: loc2)
                }
                totalDistance = distanceSum
                avgSpeed = (distanceSum / raceDuration) * 1.94384 // Convert m/s to knots
            }
        }
        
        return (topSpeed, avgSpeed, totalDistance)
    }
    
    // Helper function to format distance with appropriate unit
    private func formatDistance(_ distance: CLLocationDistance?) -> String {
        guard let distance = distance else {
            return "0.0 m"
        }
        
        if distance >= 1000 {
            // Display in kilometers if 1km or more
            return String(format: "%.2f km", distance / 1000)
        } else {
            // Display in meters if less than 1km
            return String(format: "%.0f m", distance)
        }
    }
    
    // Add these functions to the ModernRaceSessionMapView struct

    // Filter location points to limit display to ~500 points max while preserving shape
    private func filterLocationPoints(
        points: [(location: CLLocationCoordinate2D, speed: Double)],
        maxPointCount: Int = 500,
        currentZoomLevel: Double? = nil
    ) -> [(location: CLLocationCoordinate2D, speed: Double)] {
        guard points.count > maxPointCount else {
            // No filtering needed if under the limit
            return points
        }
        
        // Calculate base epsilon (tolerance) based on total points
        let baseEpsilon = calculateBaseEpsilon(for: points)
        
        // Adjust epsilon based on zoom level if provided
        let epsilon: Double
        if let zoomLevel = currentZoomLevel {
            // Reduce epsilon (more detail) when zoomed in
            epsilon = baseEpsilon / max(1.0, zoomLevel / 3.0)
        } else {
            epsilon = baseEpsilon
        }
        
        // Apply Ramer-Douglas-Peucker algorithm
        let simplified = applyRamerDouglasPeucker(
            points: points,
            epsilon: epsilon,
            start: 0,
            end: points.count - 1
        )
        
        // If still too many points after simplification, use adaptive sampling
        if simplified.count > maxPointCount {
            return adaptiveSampling(points: simplified, maxCount: maxPointCount)
        }
        
        return simplified
    }

    // Calculate a base epsilon value for the Ramer-Douglas-Peucker algorithm
    private func calculateBaseEpsilon(for points: [(location: CLLocationCoordinate2D, speed: Double)]) -> Double {
        // Find the bounding box of all points
        let coordinates = points.map { $0.location }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        // Calculate diagonal distance of bounding box (rough approximation)
        let diagonalLat = maxLat - minLat
        let diagonalLon = maxLon - minLon
        let diagonalDistance = sqrt(diagonalLat * diagonalLat + diagonalLon * diagonalLon)
        
        // Base epsilon on a fraction of the diagonal
        // The larger the epsilon, the more aggressive the simplification
        let fractionOfDiagonal = 0.001 // Adjust based on testing
        let baseEpsilon = diagonalDistance * fractionOfDiagonal
        
        // Scale based on point count - more points need more aggressive filtering
        let pointCountFactor = Double(points.count) / 1000.0
        return baseEpsilon * max(1.0, pointCountFactor)
    }

    // Ramer-Douglas-Peucker algorithm for polyline simplification
    private func applyRamerDouglasPeucker(
        points: [(location: CLLocationCoordinate2D, speed: Double)],
        epsilon: Double,
        start: Int,
        end: Int
    ) -> [(location: CLLocationCoordinate2D, speed: Double)] {
        guard end > start + 1 else {
            // Base case: cannot simplify further
            return Array(points[start...end])
        }
        
        // Find the point with the maximum distance from line segment
        var maxDistance = 0.0
        var maxIndex = start
        
        let startPoint = points[start].location
        let endPoint = points[end].location
        
        for i in start + 1..<end {
            let distance = perpendicularDistance(
                point: points[i].location,
                lineStart: startPoint,
                lineEnd: endPoint
            )
            
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        // If max distance is greater than epsilon, recursively simplify both segments
        if maxDistance > epsilon {
            let firstSegment = applyRamerDouglasPeucker(
                points: points,
                epsilon: epsilon,
                start: start,
                end: maxIndex
            )
            
            let secondSegment = applyRamerDouglasPeucker(
                points: points,
                epsilon: epsilon,
                start: maxIndex,
                end: end
            )
            
            // Combine results (excluding duplicate point)
            return firstSegment.dropLast() + secondSegment
        } else {
            // All points in this segment are within epsilon distance, so just keep endpoints
            return [points[start], points[end]]
        }
    }

    // Calculate perpendicular distance from a point to a line segment
    private func perpendicularDistance(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> Double {
        let x = point.longitude
        let y = point.latitude
        let x1 = lineStart.longitude
        let y1 = lineStart.latitude
        let x2 = lineEnd.longitude
        let y2 = lineEnd.latitude
        
        // Line equation: (y2-y1)x + (x1-x2)y + (x2y1-x1y2) = 0
        let a = y2 - y1
        let b = x1 - x2
        let c = x2 * y1 - x1 * y2
        
        // Distance formula: |ax + by + c| / sqrt(a² + b²)
        let numerator = abs(a * x + b * y + c)
        let denominator = sqrt(a * a + b * b)
        
        if denominator == 0 {
            // Points are coincident
            return 0
        }
        
        return numerator / denominator
    }

    // Adaptive sampling to further reduce points if needed
    private func adaptiveSampling(
        points: [(location: CLLocationCoordinate2D, speed: Double)],
        maxCount: Int
    ) -> [(location: CLLocationCoordinate2D, speed: Double)] {
        guard points.count > maxCount else {
            return points
        }
        
        // Step 1: Always keep first and last points
        let result = [points.first!] + adaptivelySelectPoints(points: points.dropFirst().dropLast(), maxCount: maxCount - 2) + [points.last!]
        
        return result
    }

    // Helper to select important points based on speed changes and direction changes
    private func adaptivelySelectPoints(
        points: [(location: CLLocationCoordinate2D, speed: Double)],
        maxCount: Int
    ) -> [(location: CLLocationCoordinate2D, speed: Double)] {
        let pointsArray = Array(points)
        guard pointsArray.count > maxCount else {
            return pointsArray
        }
        
        // Calculate importance score for each point based on:
        // 1. Speed changes (more significant changes are more important)
        // 2. Direction changes (more significant turns are more important)
        var importanceScores: [(index: Int, score: Double)] = []
        
        // We'll skip first and last since they're always included
        for i in 1..<pointsArray.count - 1 {
            let prevPoint = pointsArray[i-1]
            let point = pointsArray[i]
            let nextPoint = pointsArray[i+1]
            
            // Speed change importance
            let speedChangeScore = abs(point.speed - prevPoint.speed) + abs(nextPoint.speed - point.speed)
            
            // Direction change importance (angle between segments)
            let directionChangeScore = calculateDirectionChange(
                p1: prevPoint.location,
                p2: point.location,
                p3: nextPoint.location
            )
            
            // Combined score (weight can be adjusted based on what's more important)
            let score = speedChangeScore * 0.3 + directionChangeScore * 0.7
            
            importanceScores.append((index: i, score: score))
        }
        
        // Sort points by importance (higher score is more important)
        let sortedByImportance = importanceScores.sorted { $0.score > $1.score }
        
        // Take the most important points up to maxCount
        let selectedIndices = sortedByImportance.prefix(maxCount).map { $0.index }.sorted()
        
        // Return selected points
        return selectedIndices.map { pointsArray[$0] }
    }

    // Calculate the angle change at a point (used for direction change importance)
    private func calculateDirectionChange(
        p1: CLLocationCoordinate2D,
        p2: CLLocationCoordinate2D,
        p3: CLLocationCoordinate2D
    ) -> Double {
        // Convert to Cartesian-like coordinates for simplicity
        // (this is an approximation, not geodesic calculation)
        let x1 = p1.longitude
        let y1 = p1.latitude
        let x2 = p2.longitude
        let y2 = p2.latitude
        let x3 = p3.longitude
        let y3 = p3.latitude
        
        // Calculate vectors
        let v1x = x2 - x1
        let v1y = y2 - y1
        let v2x = x3 - x2
        let v2y = y3 - y2
        
        // Calculate magnitudes
        let v1Mag = sqrt(v1x * v1x + v1y * v1y)
        let v2Mag = sqrt(v2x * v2x + v2y * v2y)
        
        // Prevent division by zero
        if v1Mag == 0 || v2Mag == 0 {
            return 0
        }
        
        // Dot product
        let dotProduct = v1x * v2x + v1y * v2y
        
        // Cosine of angle
        let cosAngle = dotProduct / (v1Mag * v2Mag)
        
        // Clamp value to valid range for acos
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        // Convert to angle in radians, then to degrees
        let angleInRadians = acos(clampedCosAngle)
        let angleInDegrees = angleInRadians * 180.0 / .pi
        
        // Return angle change - more change means more importance
        return angleInDegrees
    }

    // Helper method to estimate zoom level from MapCameraPosition
    private func estimateZoomLevel(from cameraPosition: MapCameraPosition) -> Double? {
        // Just return the current zoom level - we'll update it elsewhere
        return zoomLevelState
    }
    
    private func updateFilteredPoints() {
        // Get current zoom level
        let zoom = currentZoomLevel ?? 1.0
        
        // Adjust point count based on zoom level
        let zoomAdjustedPointCount = min(maxDisplayPoints, Int(Double(maxDisplayPoints) * zoom))
        
        if validLocationPoints.count > zoomAdjustedPointCount {
            filteredLocationPoints = filterLocationPoints(
                points: validLocationPoints,
                maxPointCount: zoomAdjustedPointCount,
                currentZoomLevel: zoom
            )
        } else {
            filteredLocationPoints = validLocationPoints
        }
    }
    
    private func resetMapToShowEntireRoute() {
        if !validLocationPoints.isEmpty {
            let coordinates = validLocationPoints.map { $0.location }
            let minLat = coordinates.map { $0.latitude }.min() ?? 0
            let maxLat = coordinates.map { $0.latitude }.max() ?? 0
            let minLon = coordinates.map { $0.longitude }.min() ?? 0
            let maxLon = coordinates.map { $0.longitude }.max() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.5,
                longitudeDelta: (maxLon - minLon) * 1.5
            )
            
            // Set the position
            position = .region(MKCoordinateRegion(center: center, span: span))
            
            // Update filtered points after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateFilteredPoints()
            }
        }
    }
    
    init(session: RaceSession) {
        self.session = session
        self.validLocationPoints = session.dataPoints.compactMap { point -> (location: CLLocationCoordinate2D, speed: Double)? in
            guard let location = point.location else { return nil }
            return (
                CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                point.speed ?? 0
            )
        }
        self.maxSpeed = session.dataPoints.compactMap { $0.speed }.max() ?? 0
        self.hasStartLine = session.leftPoint != nil && session.rightPoint != nil
        
        // Initialize filtered points with up to maxDisplayPoints
        let initialFiltered = self.validLocationPoints.count > self.maxDisplayPoints ?
            Array(self.validLocationPoints.prefix(self.maxDisplayPoints)) :
            self.validLocationPoints
        self._filteredLocationPoints = State(initialValue: initialFiltered)
        
        let initialRegion: MKCoordinateRegion
        if !self.validLocationPoints.isEmpty {
            // Case 1: We have valid location points - use them to define the region
            let coordinates = self.validLocationPoints.map { $0.location }
            let minLat = coordinates.map { $0.latitude }.min() ?? 0
            let maxLat = coordinates.map { $0.latitude }.max() ?? 0
            let minLon = coordinates.map { $0.longitude }.min() ?? 0
            let maxLon = coordinates.map { $0.longitude }.max() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.5,
                longitudeDelta: (maxLon - minLon) * 1.5
            )
            
            initialRegion = MKCoordinateRegion(center: center, span: span)
        } else if let leftPoint = session.leftPoint {
            // Case 2: No valid location points but we have a left point
            let center = CLLocationCoordinate2D(
                latitude: leftPoint.latitude,
                longitude: leftPoint.longitude
            )
            initialRegion = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        } else if let rightPoint = session.rightPoint {
            // Case 3: No valid location points, no left point, but we have a right point
            let center = CLLocationCoordinate2D(
                latitude: rightPoint.latitude,
                longitude: rightPoint.longitude
            )
            initialRegion = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        } else {
            // Case 4: No valid location points, no left or right points
            // Default to San Francisco Bay Area if no location data
            initialRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        self._position = State(initialValue: .region(initialRegion))
        self._mapSelection = State(initialValue: nil)
    }
    
    private var hasLocationData: Bool {
        return !validLocationPoints.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen map
            Map(position: $position, interactionModes: showFullScreenMap ? [.pan, .zoom] : [], selection: $mapSelection) {
                
                // Route with speed colors - UPDATED to use filteredLocationPoints
                if filteredLocationPoints.count > 1 {
                    // Draw polylines between points
                    ForEach(0..<filteredLocationPoints.count - 1, id: \.self) { index in
                        let start = filteredLocationPoints[index]
                        let end = filteredLocationPoints[index + 1]
                        
                        MapPolyline(coordinates: [start.location, end.location])
                            .stroke(colorForSpeed(start.speed), lineWidth: 7)
                    }
                    
                    // Add circle annotations for each point
                    ForEach(1..<filteredLocationPoints.count - 1, id: \.self) { index in
                        let point = filteredLocationPoints[index]
                        
                        Annotation("", coordinate: point.location) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(colorForSpeed(point.speed).opacity(0.7))
                                .font(.system(size: 7)) // Size of the circle
                        }
                    }
                }
                                
                // Start line
                if hasStartLine,
                   let leftPoint = session.leftPoint,
                   let rightPoint = session.rightPoint {
                    let startCoord = CLLocationCoordinate2D(
                        latitude: leftPoint.latitude,
                        longitude: leftPoint.longitude
                    )
                    let endCoord = CLLocationCoordinate2D(
                        latitude: rightPoint.latitude,
                        longitude: rightPoint.longitude
                    )
                    
                    if session.countdownDuration < 900 {
                        MapPolyline(coordinates: [startCoord, endCoord])
                            .stroke(.white, style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round,
                                dash: [6, 3]
                            ))
                    }
                    
                    Annotation("Start", coordinate: startCoord) {
                        if session.countdownDuration > 900 {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "triangle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Annotation("End", coordinate: endCoord) {
                        if session.countdownDuration > 900 {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "square.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Waypoint annotations
                if showWaypointAnnotations, let waypoints = session.waypoints, !waypoints.isEmpty {
                    ForEach(waypoints.sorted(by: { $0.order < $1.order })) { waypoint in
                        let waypointCoord = CLLocationCoordinate2D(
                            latitude: waypoint.latitude,
                            longitude: waypoint.longitude
                        )
                        
                        Annotation("WP \(waypoint.order + 1)", coordinate: waypointCoord) {
                            ZStack {
                                Circle()
                                    .fill(waypoint.completed ? Color.green.opacity(0.7) :
                                         (waypoint.isActiveWaypoint == true ? Color(hex: ColorTheme.ultraBlue.rawValue) : Color.gray.opacity(0.7)))
                                    .frame(width: 28, height: 28)
                                
                                Text("\(waypoint.order + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .mapStyle(selectedMapStyle.style)
            .ignoresSafeArea(edges: showFullScreenMap ? .all : [])
            .frame(height: showFullScreenMap ? nil : 300)
            .onChange(of: position) { oldValue, newValue in
                // Update zoom level when position changes
                if previousPositionState != newValue {
                    zoomLevelState = min(10.0, zoomLevelState * 1.1)
                    previousPositionState = newValue
                }
                
                // Update current zoom level
                currentZoomLevel = zoomLevelState
                
                // Update filtered points based on new zoom level
                updateFilteredPoints()
            }
            .onAppear {
                // Initialize filtered points with proper algorithm
                updateFilteredPoints()
            }
            .onTapGesture {
                withAnimation(.easeInOut) {
                    let wasFullScreen = showFullScreenMap
                    showFullScreenMap.toggle()
                    
                    // If transitioning from full screen to normal mode, reset the map view
                    if wasFullScreen {
                        resetMapToShowEntireRoute()
                    }
                }
            }
            /*
            .overlay(alignment: .topLeading) {
                Button(action: {
                    if showFullScreenMap {
                        withAnimation {
                            showFullScreenMap = false
                            
                            // Reset map to show the entire GPS route
                            if !validLocationPoints.isEmpty {
                                let coordinates = validLocationPoints.map { $0.location }
                                let minLat = coordinates.map { $0.latitude }.min() ?? 0
                                let maxLat = coordinates.map { $0.latitude }.max() ?? 0
                                let minLon = coordinates.map { $0.longitude }.min() ?? 0
                                let maxLon = coordinates.map { $0.longitude }.max() ?? 0
                                
                                let center = CLLocationCoordinate2D(
                                    latitude: (minLat + maxLat) / 2,
                                    longitude: (minLon + maxLon) / 2
                                )
                                
                                let span = MKCoordinateSpan(
                                    latitudeDelta: (maxLat - minLat) * 1.5,
                                    longitudeDelta: (maxLon - minLon) * 1.5
                                )
                                
                                position = .region(MKCoordinateRegion(center: center, span: span))
                            }
                        }
                    } else {
                        dismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: showFullScreenMap ? "chevron.down" : "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .padding(.top, showFullScreenMap ? 50 : 16)
                .padding(.leading, 16)
            } */
            .overlay(alignment: .topTrailing) {
                if showFullScreenMap {
                    Button(action: {
                        // Toggle between standard and satellite map styles
                        selectedMapStyle = selectedMapStyle == .standard ? .satellite : .standard
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: selectedMapStyle == .standard ? "globe" : "map")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 16)
                }
            }
            .overlay(alignment: .top) {
                if showMapStyleControls && showFullScreenMap {
                    HStack {
                        ForEach(MapStyleConfiguration.allCases) { style in
                            Button(action: {
                                selectedMapStyle = style
                                withAnimation {
                                    showMapStyleControls = false
                                }
                            }) {
                                Text(style.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedMapStyle == style ? Color.white : Color.black.opacity(0.6))
                                    .foregroundColor(selectedMapStyle == style ? .black : .white)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(20)
                    .padding(.top, 100)
                }
            }
/*
            .mapControls {
                if showFullScreenMap {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
            }
*/
            
            // No GPS Data overlay
            if !hasLocationData {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .cornerRadius(12)
                        .frame(width: 200, height: 80)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("GPS Data Not Available")
                            .font(.system(.headline))
                            .foregroundColor(.white)
                    }
                }
                .zIndex(1)
            }
            
            // Info Section (visible when not in full screen mode)
            if !showFullScreenMap {
                VStack {
                    Spacer(minLength: 300) // Space for the map
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Title and Date Section
                            VStack(alignment: .leading, spacing: 4) {
                                // Session type
                                Text(session.countdownDuration > 900 ? "Cruise" : "Countdown: \(session.countdownDuration) min")
                                    .font(.system(size: 28, weight: .bold))
                                    .padding(.top, 16)
                                
                                // Date and time
                                HStack {
                                    Text("\(session.formattedTime()) \(session.timeZoneString())")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    // Weather indicators
                                    /*
                                    if let condition = session.weatherCondition, let temperature = session.temperature {
                                        HStack(spacing: 8) {
                                            Image(systemName: condition)
                                                .foregroundColor(.white)
                                            Text("\(String(format: "%.0f", temperature))°")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(16)
                                    }
                                    */
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Divider
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .padding(.vertical, 8)
                            
                            // Stats in two columns
                            VStack(spacing: 24) {
                                // First row: Duration and Distance
                                HStack(alignment: .top) {
                                    // Left column - Duration
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Time")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Text(session.formattedRaceTime)
                                            .font(.system(size: 34, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Right column - Distance
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Distance")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Text(formatDistance(raceStats.totalDistance))
                                            .font(.system(size: 34, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                // Second row: Avg Speed and Max Speed
                                HStack(alignment: .top) {
                                    // Left column - Avg Speed
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Avg Speed")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                                            Text(String(format: "%.1f", raceStats.avgSpeed ?? 0))
                                                .font(.system(size: 34, weight: .bold))
                                            
                                            Text("kn")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Right column - Max Speed
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Max Speed")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                                            Text(String(format: "%.1f", raceStats.topSpeed ?? 0))
                                                .font(.system(size: 34, weight: .bold))
                                            
                                            Text("kn")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                // Third row: Wind and Weather
                                HStack(alignment: .top) {
                                    // Left column - Wind info
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Wind")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        if let windSpeed = session.windSpeed,
                                           let windDirection = session.windDirection,
                                           let windCardinalDirection = session.windCardinalDirection {
                                            
                                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                                Text(String(format: "%.1f", windSpeed))
                                                    .font(.system(size: 28, weight: .bold))
                                                
                                                Text("kn")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Text("\(String(format: "%.0f", windDirection))° \(windCardinalDirection)")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                                        } else {
                                            Text("Not available")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Right column - Weather info
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Weather")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        if let condition = session.weatherCondition, let temperature = session.temperature {
                                            HStack(spacing: 8) {
                                                Image(systemName: condition)
                                                    .font(.system(size: 24))
                                                    .foregroundColor(Color.white)
                                                
                                                Text("\(String(format: "%.1f", temperature))")
                                                    .font(.system(size: 28, weight: .bold))
                                                
                                                Text("°C")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.gray)
                                            }
                                        } else {
                                            Text("Not available")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Speed gradient legend
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Speed Tracking")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Text("0.0 kn")
                                        .font(.caption)
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.4, blue: 0.0),    // Orange-Red
                                            Color(red: 1.0, green: 1.0, blue: 0.0),    // Yellow
                                            Color(red: 0.0, green: 1.0, blue: 0.0)     // Green
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                    Text("\(String(format: "%.1f", raceStats.topSpeed ?? 0)) kn")
                                        .font(.caption)
                                }
                            }
                            .padding(16)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            // Start line coordinates if available
                            if hasStartLine {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(session.countdownDuration > 900 ? "Start and Finish" : "Start Line")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        if session.countdownDuration > 900 {
                                            if let left = session.leftPoint {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 12))
                                                    Text(String(format: "(%.4f, %.4f)", left.latitude, left.longitude))
                                                        .font(.system(size: 12, design: .monospaced))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if let right = session.rightPoint {
                                                HStack(spacing: 4) {
                                                    Text(String(format: "(%.4f, %.4f)", right.latitude, right.longitude))
                                                        .font(.system(size: 12, design: .monospaced))
                                                    Image(systemName: "circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 12))
                                                }
                                            }
                                        } else {
                                            if let left = session.leftPoint {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "triangle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 12))
                                                    Text(String(format: "(%.4f, %.4f)", left.latitude, left.longitude))
                                                        .font(.system(size: 12, design: .monospaced))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if let right = session.rightPoint {
                                                HStack(spacing: 4) {
                                                    Text(String(format: "(%.4f, %.4f)", right.latitude, right.longitude))
                                                        .font(.system(size: 12, design: .monospaced))
                                                    Image(systemName: "square.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 12))
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                            
                            // Cruise plan data
                            if let planActive = session.planActive, planActive == true {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Cruise Plan")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        // Waypoint display toggle button
                                        Button(action: {
                                            withAnimation {
                                                showWaypointAnnotations.toggle()
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: showWaypointAnnotations ? "mappin.circle.fill" : "mappin.circle")
                                                    .font(.system(size: 14))
                                                Text("Show Waypoints")
                                                    .font(.system(size: 12))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(showWaypointAnnotations ?
                                                      Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.3) :
                                                      Color.gray.opacity(0.3))
                                            .foregroundColor(showWaypointAnnotations ?
                                                           Color(hex: ColorTheme.ultraBlue.rawValue) :
                                                           Color.white)
                                            .cornerRadius(12)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        // Plan name
                                        if let planName = session.activePlanName {
                                            HStack {
                                                Text("Plan:")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                                Text(planName)
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                        }
                                        
                                        // Waypoints count
                                        if let completed = session.completedWaypointsCount,
                                           let total = session.totalWaypointsCount {
                                            HStack {
                                                Text("Waypoints:")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                                Text("\(completed)/\(total)")
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                        }
                                        
                                        // Completion percentage
                                        if let completion = session.planCompletionPercentage {
                                            HStack {
                                                Text("Completion:")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                                Text("\(String(format: "%.1f", completion))%")
                                                    .font(.system(size: 16, weight: .semibold))
                                                
                                                // Progress bar
                                                GeometryReader { geometry in
                                                    ZStack(alignment: .leading) {
                                                        Rectangle()
                                                            .frame(width: geometry.size.width, height: 6)
                                                            .opacity(0.3)
                                                            .foregroundColor(.gray)
                                                        
                                                        Rectangle()
                                                            .frame(width: min(CGFloat(completion / 100) * geometry.size.width, geometry.size.width), height: 6)
                                                            .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                                                    }
                                                    .cornerRadius(3)
                                                }
                                                .frame(height: 6)
                                                .padding(.leading, 8)
                                            }
                                        }
                                    }
                                    
                                    // Detailed waypoint list if available
                                    if let waypoints = session.waypoints, !waypoints.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Waypoints")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray)
                                                .padding(.top, 4)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 12) {
                                                    ForEach(waypoints.sorted(by: { $0.order < $1.order })) { waypoint in
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            HStack(alignment: .center, spacing: 4) {
                                                                // Different icon for active/completed waypoints
                                                                if waypoint.isActiveWaypoint == true {
                                                                    Image(systemName: "location.circle.fill")
                                                                        .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                                                                        .font(.system(size: 14))
                                                                } else {
                                                                    Image(systemName: waypoint.completed ? "checkmark.circle.fill" : "circle")
                                                                        .foregroundColor(waypoint.completed ? .green : .gray)
                                                                        .font(.system(size: 14))
                                                                }
                                                                
                                                                Text("WP \(waypoint.order + 1)")
                                                                    .font(.system(size: 14, weight: .semibold))
                                                                
                                                                // Active badge
                                                                if waypoint.isActiveWaypoint == true {
                                                                    Text("ACTIVE")
                                                                        .font(.system(size: 9))
                                                                        .padding(.horizontal, 4)
                                                                        .padding(.vertical, 1)
                                                                        .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.2))
                                                                        .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                                                                        .cornerRadius(2)
                                                                }
                                                            }
                                                            
                                                            Text(String(format: "(%.4f, %.4f)", waypoint.latitude, waypoint.longitude))
                                                                .font(.system(size: 9, design: .monospaced))
                                                                .foregroundColor(.gray)
                                                            
                                                            // Show progress for active waypoint
                                                            /*
                                                            if let progress = waypoint.progress, progress > 0 {
                                                                HStack {
                                                                    Text("\(String(format: "%.0f", progress * 100))%")
                                                                        .font(.system(size: 9))
                                                                        .foregroundColor(.gray)
                                                                    
                                                                    // Mini progress bar
                                                                    ZStack(alignment: .leading) {
                                                                        Rectangle()
                                                                            .frame(width: 40, height: 4)
                                                                            .opacity(0.3)
                                                                            .foregroundColor(.gray)
                                                                        
                                                                        Rectangle()
                                                                            .frame(width: min(CGFloat(progress) * 40, 40), height: 4)
                                                                            .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                                                                    }
                                                                    .cornerRadius(2)
                                                                }
                                                            }
                                                            */
                                                            
                                                            /*
                                                            if let reachedAt = waypoint.reachedAt {
                                                                Text(dateFormatter.string(from: reachedAt))
                                                                    .font(.system(size: 9))
                                                                    .foregroundColor(.gray)
                                                            }
                                                            */
                                                        }
                                                        .padding(8)
                                                        .background(Color.black.opacity(0.3))
                                                        .cornerRadius(8)
                                                        .frame(width: 140)
                                                    }
                                                }
                                                .padding(.vertical, 4)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                            
                            /*
                            // View Session Details button
                            Button(action: {
                                showDetailView = true
                            }) {
                                Text("View Session Details")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: ColorTheme.ultraBlue.rawValue))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 24)
                            }
                            .sheet(isPresented: $showDetailView) {
                                NavigationView {
                                    SessionDetailTestView(session: session)
                                        .toolbar {
                                            ToolbarItem(placement: .topBarTrailing) {
                                                Button(action: {
                                                    showDetailView = false
                                                }) {
                                                    HStack {
                                                        Text("Close")
                                                            .font(.system(.subheadline))
                                                    }
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 8)
                                                    .background(Color.white.opacity(0.3))
                                                    .cornerRadius(18)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 18)
                                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                                    )
                                                }
                                            }
                                        }
                                }
                            }
                            */ //button closure
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }
    
    private func colorForSpeed(_ speed: Double) -> Color {
        let normalizedSpeed = maxSpeed > 0 ? min(speed / maxSpeed, 1.0) : 0
        
        // Define base colors with opacity 0.8
        let colors: [(threshold: Double, color: Color)] = [
            (0.0, Color.red.opacity(0.8)),
            (0.33, Color.orange.opacity(0.8)),
            (0.66, Color.yellow.opacity(0.8)),
            (1.0, Color.green.opacity(0.8))  // Include 1.0 as the upper bound
        ]
        
        // Find the two colors to interpolate between
        for i in 1..<colors.count {
            if normalizedSpeed < colors[i].threshold {
                let lowerBound = colors[i-1]
                let upperBound = colors[i]
                
                // Calculate how far between these two thresholds we are (0-1)
                let range = upperBound.threshold - lowerBound.threshold
                let adjustedSpeed = (normalizedSpeed - lowerBound.threshold) / range
                
                // Interpolate RGB components
                let lowerComponents = UIColor(lowerBound.color).cgColor.components ?? [0, 0, 0, 0]
                let upperComponents = UIColor(upperBound.color).cgColor.components ?? [0, 0, 0, 0]
                
                // For RGB colors, components are [red, green, blue, alpha]
                let r = lowerComponents[0] + (upperComponents[0] - lowerComponents[0]) * adjustedSpeed
                let g = lowerComponents[1] + (upperComponents[1] - lowerComponents[1]) * adjustedSpeed
                let b = lowerComponents[2] + (upperComponents[2] - lowerComponents[2]) * adjustedSpeed
                
                // Always use 0.8 for alpha as requested
                return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: 0.8)
            }
        }
        
        // Fallback (should not happen with our threshold setup)
        return Color.red.opacity(0.8)
    }
}

#Preview("With GPS Data") {
    // Generate a more realistic race path with varying speeds
    let baseLatitude = 37.7749
    let baseLongitude = -122.4194
    let startTime = Date()
    var dataPoints: [DataPoint] = []
    
    // Create a zigzag pattern with varying speeds
    for i in 0..<50 {
        let timeOffset = Double(i) * 10  // 10 seconds between points
        let latOffset = sin(Double(i) * 0.2) * 0.002  // Create zigzag
        let lonOffset = Double(i) * 0.0003  // General direction
        
        // Vary speed based on position in route
        let baseSpeed = 12.0  // Base speed in knots
        let speedVariation = sin(Double(i) * 0.5) * 5.0  // Speed variation
        let speed = baseSpeed + speedVariation
        
        dataPoints.append(
            DataPoint(
                timestamp: startTime.addingTimeInterval(timeOffset),
                heartRate: nil,
                speed: speed,
                location: LocationData(
                    latitude: baseLatitude + latOffset,
                    longitude: baseLongitude + lonOffset,
                    accuracy: 10
                )
            )
        )
    }
    
    let mockSession = RaceSession(
        date: Date(),
        countdownDuration: 5,
        raceStartTime: startTime,
        raceDuration: 500,
        dataPoints: dataPoints,
        leftPoint: LocationData(
            latitude: baseLatitude,
            longitude: baseLongitude,
            accuracy: 10
        ),
        rightPoint: LocationData(
            latitude: baseLatitude + 0.0005,
            longitude: baseLongitude,
            accuracy: 10
        ),
        windSpeed: 15.5,
        windDirection: 225.0,
        windCardinalDirection: "SW",
        temperature: 22.5,
        weatherCondition: "cloud.sun.fill"
    )
    
    return ModernRaceSessionMapView(session: mockSession)
}

#Preview("Without GPS Data") {
    let mockSession = RaceSession(
        date: Date(),
        countdownDuration: 900, // Set to 900+ for "Cruise" mode
        raceStartTime: Date(),
        raceDuration: 0,
        dataPoints: [],  // Empty data points
        windSpeed: 12.3,
        windDirection: 180.0,
        windCardinalDirection: "S",
        temperature: 18.5,
        weatherCondition: "cloud.rain.fill"
    )
    
    return ModernRaceSessionMapView(session: mockSession)
}
