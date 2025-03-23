//
//  SessionDetailTestView.swift
//  Regatta
//
//  Created by Chikai Lai on 22/03/2025.
//

import Foundation
import SwiftUI
import CoreLocation

// Add Identifiable conformance to WaypointRecord
extension WaypointRecord: Identifiable {
    var id: Int { order }
}

struct SessionDetailTestView: View {
    let session: RaceSession
    
    var body: some View {
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
                                Image(systemName: waypoint.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(waypoint.completed ? .green : .gray)
                                Text("Waypoint \(waypoint.order + 1)")
                                    .font(.headline)
                            }
                            
                            Text("Coordinates: \(String(format: "%.6f", waypoint.latitude)), \(String(format: "%.6f", waypoint.longitude))")
                                .font(.caption)
                            
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
        .navigationTitle("Session Details")
    }
    
    // Helper for formatting dates
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
}
