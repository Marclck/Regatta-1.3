//
//  CruiseRInfoView.swift
//  Regatta
//
//  Created by Chikai Lai on 14/02/2025.
//

import Foundation
import SwiftUI

struct CruiseRInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            
            Section(" ") {
                
                HStack(spacing: 8) {
                    Text("CruiseR")
                        .font(.system(.title, weight: .bold))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    
                        Text("ULTRA")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                            .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                            .cornerRadius(4)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sailing and environment information display designed for casual cruising. \nLong press on Watch App Screen to access menu.")
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))

                    Image("CruiseR")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                    
                }
            }
            
            // Interface Preview Image
            Section {
                Image("Onboarding-cruiser")  // Replace with your actual image asset name
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
            }
            
            Section("Speed Controls") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed Display")
                        .font(.system(.body, weight: .bold))
                    Text("GPS-based speed reading in knots (41 kn shown)\n• Tap to toggle GPS on/off\n• High precision dual-band GPS on Ultra")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distance Tracking")
                        .font(.system(.body, weight: .bold))
                    Text("Shows distance travelled during session (9)\n• Resets when GPS restarted\n• Helps track cruising progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Time Management") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timer Integration")
                        .font(.system(.body, weight: .bold))
                    Text("Quick access to race timer\n• One-tap return to timer\n• Maintains countdown in background")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Display")
                        .font(.system(.body, weight: .bold))
                    Text("Current time with interactive features (22:30)\n• Tap to enter time display mode\n• Large, clear digital format\n• Quick time reference during cruising")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Navigation Tools") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Course Tracking")
                        .font(.system(.body, weight: .bold))
                    Text("Dynamic course deviation display\n• Three dots each side show ±30° range\n• Each dot represents 10° deviation\n• Visual guide for optimal course\n• Auto-locks when steady course detected (2 sec)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wind Information")
                        .font(.system(.body, weight: .bold))
                    Text("Comprehensive wind data (19 SW)\n• Wind speed in knots\n• Cardinal direction indication\n• Dot marker shows actual wind direction\n• Updates every 10 min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weather Metrics")
                        .font(.system(.body, weight: .bold))
                    Text("Environmental conditions (13)\n• Temperature range display\n• Barometric pressure readings\n• Tap to switch between metrics\n• Helps anticipate weather changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compass")
                        .font(.system(.body, weight: .bold))
                    Text("Built-in digital compass (N)\n• True north reference\n• Updates continuously\n• Assists with navigation\n• Cross-references with course tracking")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text("CruiseR")
                        .font(.system(.title, weight: .bold))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    
                    Text("ULTRA")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.2))
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                        .cornerRadius(4)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CruiseRInfoView()
    }
}
