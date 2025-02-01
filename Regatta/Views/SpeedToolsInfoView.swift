//
//  SpeedToolsInfoView.swift
//  Regatta
//
//  Created by Chikai Lai on 31/01/2025.
//

import Foundation
import SwiftUI

struct SpeedToolInfo: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            
            Section("Speed Display") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GPS Speed")
                        .font(.system(.body, weight: .bold))
                    Text("Shows real-time GPS speed in knots (kn)\n• 1 knot = 1.15078 mph\n• 1 knot = 0.514444 m/s\n• '-' shown when speed < 0.5 m/s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Common Conversions")
                        .font(.system(.body, weight: .bold))
                    Text("5 kn ≈ 5.75 mph (2.57 m/s)\n10 kn ≈ 11.51 mph (5.14 m/s)\n15 kn ≈ 17.26 mph (7.72 m/s)\n20 kn ≈ 23.02 mph (10.29 m/s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accuracy")
                        .font(.system(.body, weight: .bold))
                    Text("• Updates every 1-2 seconds\n• Requires good GPS signal\n• Most accurate in open water\n• Smoothed to reduce fluctuations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Start Line Tools") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distance to Line (DtL)")
                        .font(.system(.body, weight: .bold))
                    Text("• Shows distance to start line or point\n• Press DtL to activate GPS mode (shows ✓)\n• Green button = point stored\n• Red button = tap to delete\n• Auto deletes after 24h")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setting Line Points")
                        .font(.system(.body, weight: .bold))
                    Text("1. Press Pin mark (▲) to turn green when you (watch) are next to it\n2. Press Committee Boat (■) to turn green when you (watch) are next to Committee Boat\n3. Line appears when both set when the start line is fully set\n4. Single point shows direct distance\n5. Press twice (red and then white) to remove stored GPS locations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distance Display")
                        .font(.system(.body, weight: .bold))
                    Text("• '-' = weak GPS signal\n• Meters when <999m\n• Kilometers when >999m\n• 'FAR' when >99km\n• 'DtL' when timer stopped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Course Tools") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Course Display")
                        .font(.system(.body, weight: .bold))
                    Text("Shows real-time magnetic heading with cardinal direction (N, NE, E, etc). Updates continuously as you change direction.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Course Reference")
                        .font(.system(.body, weight: .bold))
                    Text("System tracks optimal course in background, monitoring deviations without affecting heading display.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Deviation Indicators")
                        .font(.system(.body, weight: .bold))
                    Text("• Three dots each side (±30° total)\n• Each dot = 10° deviation\n• Left = port deviation\n• Right = starboard deviation\n• Dots fill gradually with deviation\n• Resets reference at ±30°")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            /*
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            */
        }
    }
}
