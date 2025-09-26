//
//  JournalView.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation
import SwiftUI
import CoreLocation

// Extension for ultraThinMaterial style remains unchanged
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
    @State private var transferStatus: String? = nil
    @State private var showTransferMessage = false
    
    // Add these state variables to control the detail view presentation
    @State private var selectedSession: RaceSession? = nil
    @State private var showFullScreenMapView = false
    
    // Add state variable for limited session display
    @State private var showAllSessions = false
    @State private var initialSessionCount = 10
    
    // Existing code for groupedSessions()
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
    
    // Add new method to get limited sessions
    private func limitedSessions() -> [(date: Date, dateString: String, sessions: [RaceSession])] {
        if showAllSessions {
            return groupedSessions()
        } else {
            // Get all sessions in a flat array, sorted by date (newest first)
            let allSortedSessions = sessionStore.sessions.sorted { $0.date > $1.date }
            
            // Take only the most recent 'initialSessionCount' sessions
            let limitedSessions = Array(allSortedSessions.prefix(initialSessionCount))
            
            // Regroup these limited sessions
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            let grouped = Dictionary(grouping: limitedSessions) { session in
                calendar.startOfDay(for: session.date)
            }
            
            return grouped.map { (date, sessions) in
                (date: date, dateString: formatter.string(from: date), sessions: sessions)
            }.sorted { $0.date > $1.date }
        }
    }
    
    // Your existing code for mostRecentStartLine
    private var mostRecentStartLine: (left: LocationData?, right: LocationData?) {
        guard let latestSession = sessionStore.sessions
            .filter({ $0.countdownDuration < 900 })
            .max(by: { $0.date < $1.date }) else {
                return (nil, nil)
        }
        return (latestSession.leftPoint, latestSession.rightPoint)
    }
    
    // Your existing code for hasValidStartLineData
    private var hasValidStartLineData: Bool {
        return mostRecentStartLine.left != nil || mostRecentStartLine.right != nil
    }
    
    // Your existing code for setupTransferNotifications
    private func setupTransferNotifications() {
        let notificationCenter = NotificationCenter.default
        let token = notificationCenter.addObserver(
            forName: Notification.Name("WatchTransferAttempt"),
            object: nil,
            queue: .main
        ) { notification in
            if let message = notification.userInfo?["message"] as? String {
                transferStatus = message
                showTransferMessage = true
                
                // Auto-hide after a few seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showTransferMessage = false
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main content with NavigationView
            NavigationView {
                ZStack {
                    // Gradient background
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
                        // Start Line Map section (your existing code)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Current Start Line")
                                    .font(.system(.headline))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            // Show map regardless of data availability
                            StartLineMapView(
                                leftPoint: mostRecentStartLine.left,
                                rightPoint: mostRecentStartLine.right
                            )
                            .padding(.top, 4)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .overlay(
                                // Show placeholder message when no data is available
                                Group {
                                    if !hasValidStartLineData {
                                        ZStack {
                                            Color.black.opacity(0.6)
                                                .cornerRadius(12)
                                            
                                            VStack(spacing: 8) {
                                                Image(systemName: "mappin.slash")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Text("No start line data available")
                                                    .font(.system(.subheadline))
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.center)
                                                
                                                Text("Complete a race with start line markers")
                                                    .font(.system(.caption))
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .multilineTextAlignment(.center)
                                            }
                                            .padding()
                                        }
                                    }
                                }
                                .padding(.horizontal),
                                alignment: .center
                            )
                            
                            // Show coordinates based on your existing logic
                            if hasValidStartLineData {
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
                            } else {
                                // Your existing code for when no coordinates are available
                                HStack {
                                    // Placeholder text for left coordinate
                                    HStack(spacing: 4) {
                                        Image(systemName: "triangle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 12))
                                        Text("(--, --)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    // Placeholder text for right coordinate
                                    HStack(spacing: 4) {
                                        Text("(--, --)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                        Image(systemName: "square.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 12))
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                        .materialBackground()
                        .padding(.horizontal,16)
                        .padding(.vertical, 8)
                        
                        // Sessions list section (modified to handle taps)
                        Group {
                            if sessionStore.isLoading {
                                // Loading view (your existing code)
                                VStack {
                                    ProgressView()
                                    Text("Loading sessions...")
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 50)
                            } else if sessionStore.sessions.isEmpty {
                                // Empty state view (your existing code)
                                VStack {
                                    Text("No race sessions recorded yet")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                    
                                    if !sessionStore.isWatchAvailable {
                                        HStack {
                                            Image(systemName: "applewatch.slash")
                                                .foregroundColor(.red)
                                            Text("Watch not connected")
                                                .foregroundColor(.red)
                                        }
                                        .padding(.top, 12)
                                        
                                        Text("Please open the Watch app")
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.top, 4)
                                    } else {
                                        Text("Complete a race to see it here")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.top, 4)
                                    }
                                }
                                .padding(.top, 50)
                            } else {
                                // Sessions list with tap handler and 'Load more' button
                                ZStack {
                                    List {
                                        ForEach(limitedSessions(), id: \.date) { group in
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
                                                        .contentShape(Rectangle())
                                                        .onTapGesture {
                                                            print("Session row tapped")
                                                            selectedSession = session
                                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                                showFullScreenMapView = true
                                                            }
                                                        }
                                                }
                                            }
                                            .listSectionSeparator(.hidden)
                                        }
                                        
                                        // Add empty section at the bottom to create space for the button
                                        if !showAllSessions && sessionStore.sessions.count > initialSessionCount {
                                            Section {
                                                // Empty row for spacing
                                                Color.clear
                                                    .frame(height: 10)
                                                    .listRowBackground(Color.clear)
                                            }
                                            .listSectionSeparator(.hidden)
                                        }
                                    }
                                    .listStyle(InsetGroupedListStyle())
                                    .scrollContentBackground(.hidden)
                                    
                                    // "Load more" button at the bottom of the list
                                    if !showAllSessions && sessionStore.sessions.count > initialSessionCount {
                                        VStack {
                                            Button(action: {
                                                withAnimation {
                                                    showAllSessions = true
                                                }
                                            }) {
                                                Text("Load more sessions")
                                                    .font(.system(.subheadline, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    /*.background(
                                                        Color(hex: colorManager.selectedTheme.rawValue)
                                                    )*/
                                                /*
                                                    .cornerRadius(20)
                                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                                */
                                            }
                                            .buttonStyle(.glass)
                                            .padding(.bottom, 20)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .toolbar {
                    // Your existing toolbar content
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Journal")
                            .foregroundColor(.white)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .fixedSize()
                    }
                    .sharedBackgroundVisibility(.hidden)
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        // Your existing refresh button
                        Button(action: {
                            // Refresh action code
                            transferStatus = "Requesting sessions from Watch..."
                            showTransferMessage = true
                            
                            sessionStore.updateWatchAvailability()
                            WatchSessionManager.shared.requestForceTransfer()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                sessionStore.refreshSessions()
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                if !sessionStore.isWatchAvailable || self.transferStatus == "Requesting sessions from Watch..." {
                                    WatchSessionManager.shared.resetTransferState()
                                    self.transferStatus = "Reset connection - please try again"
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            self.showTransferMessage = false
                                        }
                                    }
                                }
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    if self.transferStatus == "Requesting sessions from Watch..." {
                                        self.showTransferMessage = false
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                if !sessionStore.isWatchAvailable {
                                    Image(systemName: "applewatch.slash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 12))
                                    
                                    Text("Connect Watch")
                                        .font(.system(.subheadline))
                                } else {
                                    Image(systemName: "applewatch")
                                        .foregroundColor(.green)
                                        .font(.system(size: 12))
                                    
                                    Text("Update")
                                        .font(.system(.subheadline))
                                }
                            }
                            .padding(.horizontal, 0)
                            .padding(.vertical, 0)
                            .foregroundColor(.white)
                            //.background(Color.white.opacity(0.3))
                            //.cornerRadius(18)
                            /*
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            */
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .refreshable {
                    // Your existing refreshable code
                    print("📱 JournalView: Pull to refresh triggered")
                    sessionStore.updateWatchAvailability()
                    await withCheckedContinuation { continuation in
                        Task { @MainActor in
                            if !sessionStore.isWatchAvailable {
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                            }
                            sessionStore.refreshSessions()
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            continuation.resume()
                        }
                    }
                    print("📱 JournalView: Refresh completed")
                    
                    // Reset to initial state on refresh
                    showAllSessions = false
                }
            }
            
            // IMPORTANT: Full screen map overlay - completely covers everything when active
            if showFullScreenMapView, let session = selectedSession {
                Color.black
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                ModernRaceSessionMapView(session: session)
                    .ignoresSafeArea()
                    .transition(.move(edge: .bottom))
                    .overlay(alignment: .topLeading) {
                        // Custom back button to exit the map view
                        Button(action: {
                            print("Back button tapped")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showFullScreenMapView = false
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .padding(.leading, 16)
                    }
                    .zIndex(100) // Ensure this is above everything else
            }
            
            // Transfer message toast (if you have it)
            if showTransferMessage, let status = transferStatus {
                VStack {
                    Spacer()
                    Text(status)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom))
                .zIndex(200) // Above everything else
            }
        }
        .onAppear {
            print("📱 JournalView: View appeared")
            sessionStore.loadSessions()
            setupTransferNotifications()
            
            // Reset to initial state when view appears
            showAllSessions = false
        }
        .withArchiveSupport(sessionStore: sessionStore)
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
