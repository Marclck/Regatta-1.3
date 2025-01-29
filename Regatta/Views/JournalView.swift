//
//  JournalView.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation
import SwiftUI
import CoreLocation


struct JournalView: View {
    @StateObject private var sessionStore = iOSSessionStore.shared
    
    private func groupedSessions() -> [String: [RaceSession]] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return Dictionary(grouping: sessionStore.sessions) { session in
            formatter.string(from: session.date)
        }
    }
    
    // Get the most recent start line points
    private var mostRecentStartLine: (left: LocationData?, right: LocationData?) {
        guard let latestSession = sessionStore.sessions.max(by: { $0.date < $1.date }) else {
            return (nil, nil)
        }
        return (latestSession.leftPoint, latestSession.rightPoint)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Start Line Map
                if mostRecentStartLine.left != nil || mostRecentStartLine.right != nil {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Current Race Start Line")
                                                .font(.system(.headline, design: .monospaced))
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                // Trigger session refresh
                                                Task { @MainActor in
                                                    sessionStore.refreshSessions()
                                                }
                                            }) {
                                                Text("Refresh")
                                                    .font(.system(.subheadline, design: .monospaced))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                        
                                        StartLineMapView(
                                            leftPoint: mostRecentStartLine.left,
                                            rightPoint: mostRecentStartLine.right
                                        )
                                        .padding(.top, 4)
                                        
                                        HStack {
                                            // Left coordinate
                                            if let left = mostRecentStartLine.left {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "triangle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 12))
                                                    Text(String(format: "(%.4f, %.4f)", left.latitude, left.longitude))
                                                        .font(.system(size: 12, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Right coordinate
                                            if let right = mostRecentStartLine.right {
                                                HStack(spacing: 4) {
                                                    Text(String(format: "(%.4f, %.4f)", right.latitude, right.longitude))
                                                        .font(.system(size: 12, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                    Image(systemName: "square.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 12))
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                
                // Session List
                Group {
                    if sessionStore.isLoading {
                        ProgressView("Loading sessions...")
                    } else if sessionStore.sessions.isEmpty {
                        VStack {
                            Text("No race sessions recorded yet")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Text("Complete a race to see it here")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    } else {
                        List {
                            ForEach(groupedSessions().keys.sorted(by: >), id: \.self) { date in
                                Section(header: Text(date)) {
                                    ForEach(groupedSessions()[date]!.sorted(by: { $0.date > $1.date }), id: \.date) { session in
                                        SessionRowView(session: session)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Race Journal")
            .refreshable {
                print("📱 JournalView: Pull to refresh triggered")
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        sessionStore.refreshSessions()
                        continuation.resume()
                    }
                }
                print("📱 JournalView: Refresh completed")
            }
        }
        .onAppear {
            print("📱 JournalView: View appeared")
            sessionStore.loadSessions()
        }
    }
}

struct SessionRowView: View {
    let session: RaceSession
    
    private var raceStats: (topSpeed: Double?, avgSpeed: Double?) {
        guard let raceStartTime = session.raceStartTime else {
            return (nil, nil)
        }
        
        // Filter data points during race (after raceStartTime)
        let raceDataPoints = session.dataPoints.filter { $0.timestamp >= raceStartTime }
        
        // Calculate top speed during race
        let topSpeed = raceDataPoints.compactMap { $0.speed }.max()
        
        // Calculate average speed using distance and time
        var avgSpeed: Double? = nil
        if let raceDuration = session.raceDuration,
           raceDuration > 0 {
            // Get sequential location points
            let locations = raceDataPoints.compactMap { point -> CLLocationCoordinate2D? in
                guard let loc = point.location else { return nil }
                return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            }
            
            // Calculate total distance
            var totalDistance: CLLocationDistance = 0
            if locations.count >= 2 {
                for i in 0..<(locations.count - 1) {
                    let loc1 = CLLocation(latitude: locations[i].latitude, longitude: locations[i].longitude)
                    let loc2 = CLLocation(latitude: locations[i + 1].latitude, longitude: locations[i + 1].longitude)
                    totalDistance += loc1.distance(from: loc2)
                }
                // Convert m/s to knots
                avgSpeed = (totalDistance / raceDuration) * 1.94384
            }
        }
        
        return (topSpeed, avgSpeed)
    }
    
    private var maxSpeedDisplay: String {
        raceStats.topSpeed.map { String(format: "Max Speed: %.0f kn", $0) } ?? "Max Speed: N/A"
    }
    
    private var avgSpeedDisplay: String {
        raceStats.avgSpeed.map { String(format: "Avg Speed: %.1f kn", $0) } ?? "Avg Speed: N/A"
    }
    
    private var leftCoordinate: String {
        if let left = session.leftPoint {
            return String(format: "(%.2f,%.2f)", left.latitude, left.longitude)
        }
        return "(--)"
    }
    
    private var rightCoordinate: String {
        if let right = session.rightPoint {
            return String(format: "(%.2f,%.2f)", right.latitude, right.longitude)
        }
        return "(--)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(session.formattedTime()) \(session.timeZoneString())")
                    .font(.system(.headline))
            }
            
            HStack {
                Text("Countdown: \(session.countdownDuration) min")
                Spacer()
                Text("Race: \(session.formattedRaceTime)")
            }
            .font(.system(.subheadline, design: .monospaced))
            .foregroundColor(.secondary)
            
            HStack {
                Text(maxSpeedDisplay)
                Spacer()
                Text(avgSpeedDisplay)
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "triangle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 12))
                Text(leftCoordinate)
                Spacer()
                Text(rightCoordinate)
                Image(systemName: "square.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 12))
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews
#Preview("Journal View - With Sessions") {
    let mockSessions = [
        // Today with data
        RaceSession(
            date: Date(),
            countdownDuration: 5,
            raceStartTime: Date().addingTimeInterval(-300),
            raceDuration: 125.43,
            dataPoints: [
                DataPoint(timestamp: Date(), heartRate: 165, speed: 12.5, location: nil),
                DataPoint(timestamp: Date(), heartRate: 172, speed: 15.2, location: nil)
            ]
        ),
        // Yesterday without data
        RaceSession(
            date: Date().addingTimeInterval(-86400),
            countdownDuration: 5,
            raceStartTime: Date().addingTimeInterval(-86700),
            raceDuration: 145.30,
            dataPoints: []
        )
    ]
    
    return JournalView()
        .previewDisplayName("With Sessions")
        .onAppear {
            SharedDefaults.saveSessionsToContainer(mockSessions)
        }
}

#Preview("Journal View - Empty") {
    JournalView()
        .previewDisplayName("Empty State")
        .onAppear {
            SharedDefaults.saveSessionsToContainer([])
        }
}

#Preview("Session Row") {
    let mockDataPoints = [
        DataPoint(timestamp: Date(), heartRate: 165, speed: 12.5, location: nil),
        DataPoint(timestamp: Date(), heartRate: 172, speed: 15.2, location: nil),
        DataPoint(timestamp: Date(), heartRate: 168, speed: 14.1, location: nil)
    ]
    
    let mockSession = RaceSession(
        date: Date(),
        countdownDuration: 5,
        raceStartTime: Date().addingTimeInterval(-300),
        raceDuration: 125.43,
        dataPoints: mockDataPoints
    )
    
    return List {
        SessionRowView(session: mockSession)
    }
}
