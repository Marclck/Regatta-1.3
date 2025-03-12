//
//  JournalView.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation
import SwiftUI
import CoreLocation

// Extension for ultraThinMaterial style
extension View {
    func materialBackground() -> some View {
        self.background(.ultraThinMaterial)
            .cornerRadius(12)
            .environment(\.colorScheme, .dark)

    }
}

struct JournalView: View {
    @StateObject private var sessionStore = iOSSessionStore.shared
    @ObservedObject private var colorManager = ColorManager()

    
    // Modified to use Date objects as keys for proper sorting
    private func groupedSessions() -> [(date: Date, dateString: String, sessions: [RaceSession])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        // Group sessions by calendar day
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessionStore.sessions) { session in
            calendar.startOfDay(for: session.date)
        }
        
        // Convert to sorted array of (date, dateString, sessions)
        return grouped.map { (date, sessions) in
            (date: date, dateString: formatter.string(from: date), sessions: sessions)
        }.sorted { $0.date > $1.date }
    }
    
    // Get the most recent start line points
    private var mostRecentStartLine: (left: LocationData?, right: LocationData?) {
        guard let latestSession = sessionStore.sessions
            .filter({ $0.countdownDuration < 900 })
            .max(by: { $0.date < $1.date }) else {
                return (nil, nil)
        }
        return (latestSession.leftPoint, latestSession.rightPoint)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background - IMPORTANT: This must be the first element in the ZStack
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: colorManager.selectedTheme.rawValue), location: 0.0),
                        .init(color: Color.black, location: 0.3),
                        .init(color: Color.black, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Start Line Map
                    if mostRecentStartLine.left != nil || mostRecentStartLine.right != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Current Start Line")
                                    .font(.system(.headline))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    // Trigger session refresh
                                    Task { @MainActor in
                                        sessionStore.refreshSessions()
                                    }
                                }) {
                                    Text("Refresh")
                                        .font(.system(.subheadline))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .foregroundColor(.white)
                                        .background(Color.white.opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            StartLineMapView(
                                leftPoint: mostRecentStartLine.left,
                                rightPoint: mostRecentStartLine.right
                            )
                            .padding(.top, 4)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            HStack {
                                // Left coordinate
                                if let left = mostRecentStartLine.left {
                                    HStack(spacing: 4) {
                                        Image(systemName: "triangle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 12))
                                        Text(String(format: "(%.4f, %.4f)", left.latitude, left.longitude))
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                
                                Spacer()
                                
                                // Right coordinate
                                if let right = mostRecentStartLine.right {
                                    HStack(spacing: 4) {
                                        Text(String(format: "(%.4f, %.4f)", right.latitude, right.longitude))
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                        Image(systemName: "square.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        .materialBackground()
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    // Session List
                    Group {
                        if sessionStore.isLoading {
                            VStack {
                                ProgressView()
                                Text("Loading sessions...")
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 50)
                        } else if sessionStore.sessions.isEmpty {
                            VStack {
                                Text("No race sessions recorded yet")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Text("Complete a race to see it here")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 4)
                            }
                            .padding(.top, 50)
                        } else {
                            // Display recent sessions
                            List {
                                // Use the sorted array of date groups
                                ForEach(groupedSessions(), id: \.date) { group in
                                    Section(header:
                                        Text(group.dateString)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    ) {
                                        ForEach(group.sessions.sorted(by: { $0.date > $1.date }), id: \.date) { session in
                                            SessionRowView(session: session)
                                                .listRowBackground(
                                                    Color.clear
                                                        .background(.ultraThinMaterial)
                                                        .environment(\.colorScheme, .dark)

                                                )
                                        }
                                    }
                                    .listSectionSeparator(.hidden)
                                }
                            }
                            .listStyle(InsetGroupedListStyle())
                            .scrollContentBackground(.hidden) // Hide default list background
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Journal")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }
            .navigationBarTitleDisplayMode(.inline) // Changed to inline to avoid conflict
            .toolbarBackground(.hidden, for: .navigationBar)
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
        .withArchiveSupport(sessionStore: sessionStore)
    }
}

struct SessionRowView: View {
    let session: RaceSession
    @State private var showMapView = false
    
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
        Button(action: {
            showMapView = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(session.formattedTime()) \(session.timeZoneString())")
                        .font(.system(.headline))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "map")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                
                HStack {
                    if session.countdownDuration > 900 {
                        Text("Cruise")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                            .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.3))
                            .cornerRadius(8)
                    } else {
                        Text("Countdown: \(session.countdownDuration) min")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                            .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.3))
                            .cornerRadius(8)
                    }
                    Spacer()
                    Text("Duration: \(session.formattedRaceTime)")
                        .foregroundColor(.white.opacity(0.8))
                }
                .font(.system(.subheadline, weight: .bold))
                
                HStack {
                    Text(avgSpeedDisplay)
                    Spacer()
                    Text(maxSpeedDisplay)
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    if session.countdownDuration < 31 {
                        Image(systemName: "triangle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text(leftCoordinate)
                        Spacer()
                        Text(rightCoordinate)
                        Image(systemName: "square.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text(leftCoordinate)
                        Spacer()
                        Text(rightCoordinate)
                        Image(systemName: "circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .sheet(isPresented: $showMapView) {
            NavigationView {
                ScrollView {
                    RaceSessionMapView(session: session)
                        .padding(.vertical)
                }
                .navigationTitle("Session Data")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showMapView = false
                        }
                    }
                }
                .background(Color.black)
            }
            .environment(\.colorScheme, .dark)
        }
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
    
    return ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: ColorTheme.ultraBlue.rawValue), Color.black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        List {
            SessionRowView(session: mockSession)
                .listRowBackground(Color.clear.background(.ultraThinMaterial))
                .environment(\.colorScheme, .dark)

        }
        .scrollContentBackground(.hidden)
    }
}
