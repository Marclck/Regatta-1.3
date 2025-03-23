//
//  RaceSessionMapView.swift
//  Regatta
//
//  Created by Chikai Lai on 30/01/2025.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

enum MapStyleConfiguration: Int, CaseIterable, Identifiable {
    case standard
    case hybrid
    case satellite
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .standard: return "Standard"
        case .hybrid: return "Hybrid"
        case .satellite: return "Satellite"
        }
    }
    
    var style: MapStyle {
        switch self {
        case .standard: return .standard()
        case .hybrid: return .hybrid()
        case .satellite: return .imagery()
        }
    }
}

struct RaceSessionMapView: View {
    // Regular stored properties
    private let session: RaceSession
    private let validLocationPoints: [(location: CLLocationCoordinate2D, speed: Double)]
    private let maxSpeed: Double
    private let hasStartLine: Bool
    
    // State properties
    @State private var position: MapCameraPosition
    @State private var mapSelection: MKMapItem?
    @State private var selectedConfiguration: MapStyleConfiguration
    @State private var isInteractionEnabled: Bool = true
    @State private var showDetailView: Bool = false
    
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
        self._selectedConfiguration = State(initialValue: .hybrid)
    }
    
    private var hasLocationData: Bool {
        return !validLocationPoints.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Session info header
            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    Text("\(session.formattedTime()) \(session.timeZoneString())")
                    
                    if session.countdownDuration > 900 {
                        Text("Cruise")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                            .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                            .cornerRadius(8)
                    } else {
                        Text("Countdown: \(session.countdownDuration) min")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                            .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.3))
                            .cornerRadius(8)
                        
                    }
                }
                .font(.system(.headline, weight: .bold))
                
                HStack {
                    Text("Distance: \(formatDistance(raceStats.totalDistance))")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(Color.white)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                    
                    Spacer()
                    Text("Duration: \(session.formattedRaceTime)")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(Color.white)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                }
                .font(.system(.subheadline, weight: .bold))
                .foregroundColor(.secondary)
                

                HStack {
                    if let windSpeed = session.windSpeed,
                       let windDirection = session.windDirection,
                       let windCardinalDirection = session.windCardinalDirection {
                        Text("Wind: \(String(format: "%.1f", windSpeed)) kts, \(String(format: "%.0f", windDirection))° \(windCardinalDirection)")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                            .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.3))
                            .cornerRadius(8)
                    } else {
                        let speedDisplay = session.windSpeed != nil ? String(format: "%.1f", session.windSpeed!) + " kts" : "--"
                        let directionDisplay = session.windDirection != nil ? String(format: "%.0f", session.windDirection!) + "°" : "--"
                        let cardinalDisplay = session.windCardinalDirection ?? "--"
                        
                        Text("Wind: \(speedDisplay) kts, \(directionDisplay)° \(cardinalDisplay)")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                            .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.3))
                            .cornerRadius(8)
                    }


                    Spacer()

                    if let condition = session.weatherCondition, let temperature = session.temperature {
                        HStack {
                            Text("Weather: ")
                            Image(systemName: condition)
                            Text("\(String(format: "%.1f", temperature))°C")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                        .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.3))
                        .cornerRadius(8)
                    } else {
                        let conditionImage = session.weatherCondition != nil ?
                            Image(systemName: session.weatherCondition!) :
                            Image(systemName: "exclamationmark.triangle")
                        
                        let tempDisplay = session.temperature != nil ?
                            "\(String(format: "%.1f", session.temperature!))°C" :
                            "-- °C"
                        
                        HStack {
                            Text("Weather: ")
                            conditionImage
                            Text(tempDisplay)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                        .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                }
                .font(.system(.subheadline, weight: .bold))
                .foregroundColor(.secondary)
                
            }
            .padding(.horizontal)
            
            // Map type selector with solid background
            Picker("Map Style", selection: $selectedConfiguration) {
                ForEach(MapStyleConfiguration.allCases) { config in
                    Text(config.name).tag(config)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(.black))
            
            // Map view with no-data overlay if needed
            ZStack {
                Map(position: $position, interactionModes: [.pan, .zoom], selection: $mapSelection) {
                    
                    // Route with speed colors
                    if validLocationPoints.count > 1 {
                        // Draw polylines between points
                        ForEach(0..<validLocationPoints.count - 1, id: \.self) { index in
                            let start = validLocationPoints[index]
                            let end = validLocationPoints[index + 1]
                            
                            MapPolyline(coordinates: [start.location, end.location])
                                .stroke(colorForSpeed(start.speed), lineWidth: 7)
                        }
                        
                        // Add circle annotations for each point
                        ForEach(1..<validLocationPoints.count - 1, id: \.self) { index in
                            let point = validLocationPoints[index]
                            
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
            }
                
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
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
//                MapPitchToggle()
            }
            .mapStyle(selectedConfiguration.style)
            .allowsHitTesting(isInteractionEnabled)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
/*
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    // Reset the map to the initial region
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
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(12)
            }
 */
            
            // Stats and legend section
            VStack(spacing: 12) {
                // Speed stats
                HStack {
                    Text("Avg Speed: \(String(format: "%.1f", raceStats.avgSpeed ?? 0)) kts")
                    Spacer()
                    Text("Max Speed: \(String(format: "%.1f", raceStats.topSpeed ?? 0)) kts")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                
                // Speed gradient legend
                HStack {
                    Text("0.0 kts")
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
                    Text("\(String(format: "%.1f", raceStats.topSpeed ?? 0)) kts")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Start line coordinates
            if hasStartLine {
                HStack {
                    if session.countdownDuration > 900 {
                        if let left = session.leftPoint {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                Text(String(format: "(%.4f, %.4f)", left.latitude, left.longitude))
                            }
                        }
                        
                        Spacer()
                        
                        if let right = session.rightPoint {
                            HStack(spacing: 4) {
                                Text(String(format: "(%.4f, %.4f)", right.latitude, right.longitude))
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
                            }
                        }
                        
                        Spacer()
                        
                        if let right = session.rightPoint {
                            HStack(spacing: 4) {
                                Text(String(format: "(%.4f, %.4f)", right.latitude, right.longitude))
                                Image(systemName: "square.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
            
            List {
                // Basic session info
                Section(header: Text("Session Info")) {
                    LabeledContent("Date", value: session.formattedStartTime)
                    LabeledContent("Duration", value: session.formattedRaceTime)
                    LabeledContent("Countdown", value: "\(session.countdownDuration) min")
                }
                
                // Weather data
                Section(header: Text("Weather Data")) {
                    if let windSpeed = session.windSpeed {
                        LabeledContent("Wind Speed", value: "\(String(format: "%.1f", windSpeed)) knots")
                    } else {
                        LabeledContent("Wind Speed", value: "Not available")
                    }
                    
                    if let windDirection = session.windDirection {
                        LabeledContent("Wind Direction", value: "\(String(format: "%.0f", windDirection))°")
                    } else {
                        LabeledContent("Wind Direction", value: "Not available")
                    }
                    
                    if let cardinalDirection = session.windCardinalDirection {
                        LabeledContent("Cardinal Direction", value: cardinalDirection)
                    } else {
                        LabeledContent("Cardinal Direction", value: "Not available")
                    }
                    
                    if let temperature = session.temperature {
                        LabeledContent("Temperature", value: "\(String(format: "%.1f", temperature))°C")
                    } else {
                        LabeledContent("Temperature", value: "Not available")
                    }
                    
                    if let condition = session.weatherCondition {
                        LabeledContent("Weather Condition", value: condition)
                    } else {
                        LabeledContent("Weather Condition", value: "Not available")
                    }
                }
                
                // Cruise plan data
                Section(header: Text("Cruise Plan Data")) {
                    if let planActive = session.planActive {
                        LabeledContent("Plan Active", value: planActive ? "Yes" : "No")
                    } else {
                        LabeledContent("Plan Active", value: "Not available")
                    }
                    
                    if let planName = session.activePlanName {
                        LabeledContent("Plan Name", value: planName)
                    } else {
                        LabeledContent("Plan Name", value: "Not available")
                    }
                    
                    if let completed = session.completedWaypointsCount,
                       let total = session.totalWaypointsCount {
                        LabeledContent("Waypoints", value: "\(completed)/\(total)")
                    } else {
                        LabeledContent("Waypoints", value: "Not available")
                    }
                    
                    if let completion = session.planCompletionPercentage {
                        LabeledContent("Completion", value: "\(String(format: "%.1f", completion))%")
                    } else {
                        LabeledContent("Completion", value: "Not available")
                    }
                }
                
                // Detailed waypoint data
                if let waypoints = session.waypoints, !waypoints.isEmpty {
                    Section(header: Text("Waypoints (\(waypoints.count))")) {
                        ForEach(waypoints.sorted(by: { $0.order < $1.order })) { waypoint in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    // Show different icon for active waypoint
                                    if waypoint.isActiveWaypoint == true {
                                        Image(systemName: "location.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: waypoint.completed ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(waypoint.completed ? .green : .gray)
                                    }
                                    
                                    Text("Waypoint \(waypoint.order + 1)")
                                        .font(.headline)
                                    
                                    // Show active badge if this is the active waypoint
                                    if waypoint.isActiveWaypoint == true {
                                        Text("ACTIVE")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text("Coordinates: \(String(format: "%.6f", waypoint.latitude)), \(String(format: "%.6f", waypoint.longitude))")
                                    .font(.caption)
                                
                                // Show progress for active waypoint
                                if let progress = waypoint.progress, progress > 0 {
                                    HStack {
                                        Text("Progress: \(String(format: "%.1f", progress * 100))%")
                                            .font(.caption)
                                        
                                        // Progress bar
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                Rectangle()
                                                    .frame(width: geometry.size.width, height: 6)
                                                    .opacity(0.3)
                                                    .foregroundColor(.gray)
                                                
                                                Rectangle()
                                                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 6)
                                                    .foregroundColor(.blue)
                                            }
                                            .cornerRadius(3)
                                        }
                                        .frame(height: 6)
                                    }
                                }
                                
                                if let reachedAt = waypoint.reachedAt {
                                    Text("Reached at: \(dateFormatter.string(from: reachedAt))")
                                        .font(.caption)
                                }
                                
                                if let distance = waypoint.distanceFromPrevious {
                                    Text("Distance from previous: \(String(format: "%.1f", distance)) meters")
                                        .font(.caption)
                                }
                                
                                if let time = waypoint.timeFromPrevious {
                                    Text("Time from previous: \(formatTimeInterval(time))")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Data points summary
                Section(header: Text("Data Points")) {
                    LabeledContent("Total Data Points", value: "\(session.dataPoints.count)")
                    
                    if !session.dataPoints.isEmpty {
                        LabeledContent("First Point", value: dateFormatter.string(from: session.dataPoints.first!.timestamp))
                        LabeledContent("Last Point", value: dateFormatter.string(from: session.dataPoints.last!.timestamp))
                    }
                }
            }
            .frame(height: 300) // Set an appropriate height


            // Button to navigate to session details view
            Button(action: {
                showDetailView = true
            }) {
                HStack {
                    Text("View Session Details")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .foregroundColor(.primary)
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
        }
        .environment(\.colorScheme, .dark)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }
    
    // Helper for formatting time intervals
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func colorForSpeed(_ speed: Double) -> Color {
        let normalizedSpeed = maxSpeed > 0 ? min(speed / maxSpeed, 1.0) : 0
        
        // Define base colors with opacity 0.8
        let colors: [(threshold: Double, color: Color)] = [
            (0.0, Color.red.opacity(0.5)),
            (0.33, Color.orange.opacity(0.5)),
            (0.66, Color.yellow.opacity(0.5)),
            (1.0, Color.green.opacity(0.5))  // Include 1.0 as the upper bound
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
        )
    )
    
    return ScrollView {
        RaceSessionMapView(session: mockSession)
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

#Preview("Without GPS Data") {
    let mockSession = RaceSession(
        date: Date(),
        countdownDuration: 5,
        raceStartTime: Date(),
        raceDuration: 0,
        dataPoints: []  // Empty data points
    )
    
    return ScrollView {
        RaceSessionMapView(session: mockSession)
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
