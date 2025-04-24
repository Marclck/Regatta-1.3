//
//  VersionHistoryView.swift
//  Regatta
//
//  Created by Chikai Lai on 04/02/2025.
//

import Foundation
import SwiftUI

struct VersionHistoryContent: View {
    var body: some View {
        VStack(spacing: 24) {
            // Version 1.4
            VStack(alignment: .leading, spacing: 16) {
                // Version header
                HStack {
                    Text("Version 1.4")
                        .font(.system(size: 16, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Route Planning and Waypoints")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CruiseR")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
                            
                            FeatureRow(icon: "mappin", text: "Route planning and waypoint tracking - access through compass button")
                            FeatureRow(icon: "gauge.with.needle", text: "Speed Tracking: SOG display with GPS toggle for precise speed monitoring")
                            FeatureRow(icon: "wind", text: "Wind Analysis: Real-time wind speed and directional indicators with compass bearing")
                            FeatureRow(icon: "location.north.line", text: "Course Monitor: Deviation tracking with North reference and 10° indicators")
                            FeatureRow(icon: "thermometer.medium", text: "Weather Station: Integrated weather data and barometric pressure readings")
                            FeatureRow(icon: "point.topleft.down.curvedto.point.bottomright.up", text: "Journey Stats: Distance traveled with continuous tracking")
                        }
                        // ProControl section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ProControl")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
                            
                            FeatureRow(icon: "bolt", text: "QuickStart: start a 5-min countdown immediately upon gun signal")
                            FeatureRow(icon: "bolt.ring.closed", text: "GunSync: countdown rounded up or down to closest minute")
                            FeatureRow(icon: "arrow.counterclockwise", text: "Restart: restart the stopwatch after two taps")
                            FeatureRow(icon: "timelapse", text: "Timelapse: double tap timer to change countdown minutes")
                        }
                        
                        // Dashboard section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dashboard")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.9))
                            
                            FeatureRow(icon: "square.fill.and.line.vertical.and.square.fill", text: "Distance to Startline using dual band GPS")
                            FeatureRow(icon: "dots.and.line.vertical.and.cursorarrow.rectangle", text: "Shift Tracking within 30 degrees")
                            FeatureRow(icon: "gauge.open.with.lines.needle.33percent", text: "Speedometer in knots")
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)

            // Version 1.3
            VStack(alignment: .leading, spacing: 16) {
                HStack {

                    Text("Version 1.3")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Text("Introducing Ultra Features: CruiseR, Dashboard and CruiseR")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            
            // Version 1.2
            VStack(alignment: .leading, spacing: 16) {
                HStack {

                    Text("Version 1.2")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Text("App Launch")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
    }
}

struct VersionHistoryModalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VersionHistoryContent()
            }
            .navigationTitle("Version History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct VersionHistoryView: View {
    let isModal: Bool
    
    var body: some View {
        if isModal {
            VersionHistoryModalView()
        } else {
            ScrollView {
                VersionHistoryContent()
            }
            .navigationTitle("Version History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Extension for MainInfoView to add the version history link
extension MainInfoView {
    private var versionHistoryLink: some View {
        NavigationLink(destination: VersionHistoryView(isModal: false)) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                Text("Version History")
                    .font(.system(.body, design: .monospaced))
            }
            .padding(.vertical, 4)
        }
    }
}
