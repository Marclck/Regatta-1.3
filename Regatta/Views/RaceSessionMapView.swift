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
    
    // Computed stats from SessionRowView
    private var raceStats: (topSpeed: Double?, avgSpeed: Double?) {
        guard let raceStartTime = session.raceStartTime else {
            return (nil, nil)
        }
        
        let raceDataPoints = session.dataPoints.filter { $0.timestamp >= raceStartTime }
        let topSpeed = raceDataPoints.compactMap { $0.speed }.max()
        
        var avgSpeed: Double? = nil
        if let raceDuration = session.raceDuration,
           raceDuration > 0 {
            let locations = raceDataPoints.compactMap { point -> CLLocationCoordinate2D? in
                guard let loc = point.location else { return nil }
                return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            }
            
            var totalDistance: CLLocationDistance = 0
            if locations.count >= 2 {
                for i in 0..<(locations.count - 1) {
                    let loc1 = CLLocation(latitude: locations[i].latitude, longitude: locations[i].longitude)
                    let loc2 = CLLocation(latitude: locations[i + 1].latitude, longitude: locations[i + 1].longitude)
                    totalDistance += loc1.distance(from: loc2)
                }
                avgSpeed = (totalDistance / raceDuration) * 1.94384
            }
        }
        
        return (topSpeed, avgSpeed)
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
        } else {
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
                Text("\(session.formattedTime()) \(session.timeZoneString())")
                    .font(.system(.headline))
                
                HStack {
                    Text("Countdown: \(session.countdownDuration) min")
                    Spacer()
                    Text("Race: \(session.formattedRaceTime)")
                }
                .font(.system(.subheadline, design: .monospaced))
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
            .background(Color(.systemBackground))
            
            // Map view with no-data overlay if needed
            ZStack {
                Map(position: $position, interactionModes: [.pan, .zoom], selection: $mapSelection) {
                    // Route with speed colors
                    if validLocationPoints.count > 1 {
                        ForEach(0..<validLocationPoints.count - 1, id: \.self) { index in
                            let start = validLocationPoints[index]
                            let end = validLocationPoints[index + 1]
                            
                            MapPolyline(coordinates: [start.location, end.location])
                                .stroke(colorForSpeed(start.speed), lineWidth: 3)
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
                    
                    MapPolyline(coordinates: [startCoord, endCoord])
                        .stroke(.white, style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: [6, 3]
                        ))
                    
                    Annotation("Start", coordinate: startCoord) {
                        Image(systemName: "triangle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Annotation("End", coordinate: endCoord) {
                        Image(systemName: "square.fill")
                            .foregroundColor(.green)
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
                    Text("Max Speed: \(String(format: "%.1f", raceStats.topSpeed ?? 0)) kts")
                    Spacer()
                    Text("Avg Speed: \(String(format: "%.1f", raceStats.avgSpeed ?? 0)) kts")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                
                // Speed gradient legend
                HStack {
                    Text("0 kts")
                        .font(.caption)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 1.0, blue: 0.0),    // Green
                            Color(red: 1.0, green: 1.0, blue: 0.0),    // Yellow
                            Color(red: 1.0, green: 0.4, blue: 0.0)     // Orange-Red
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .cornerRadius(4)
                    Text("\(Int(maxSpeed)) kts")
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
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
    }
    
    private func colorForSpeed(_ speed: Double) -> Color {
        let normalizedSpeed = maxSpeed > 0 ? min(speed / maxSpeed, 1.0) : 0
        
        switch normalizedSpeed {
        case 0.0..<0.25: return .blue
        case 0.25..<0.5: return .green
        case 0.5..<0.75: return .yellow
        default: return .red
        }
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
}
