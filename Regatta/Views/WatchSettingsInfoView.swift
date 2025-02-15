//
//  WatchSettingsInfoView.swift
//  Regatta
//
//  Created by Chikai Lai on 31/01/2025.
//

import Foundation
import SwiftUI

struct WatchSettingsInfo: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section("Settings") {
                    Text("Settings are available for Pro and Ultra users. \nLong press on watch screen to access settings menu")
                        .font(.system(.body, weight: .bold))
            }
                
                Section("Display Options") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ultra Model")
                        .font(.system(.body, weight: .bold))
                    Text("Optimizes display for Ultra watch size. Turn on if you're using an Ultra, off for other models.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Race Info")
                        .font(.system(.body, weight: .bold))
                    Text("Race info gives you today's date and session number to keep track of your race on race day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed Info")
                        .font(.system(.body, weight: .bold))
                    Text("Displays your speed, distance to line (let you set up start point/line), and course heading. Requires location permission.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Animation & Style") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smooth Second Movement")
                        .font(.system(.body, weight: .bold))
                    Text("Enables fluid second hand motion instead of tick movement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alt Team Name Color")
                        .font(.system(.body, weight: .bold))
                    Text("Changes team name to black instead of the orange for better visibility in some conditions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Light Mode")
                        .font(.system(.body, weight: .bold))
                    Text("Switches display to light background. Best for bright daylight conditions.")
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

#Preview {
    NavigationView {
        WatchSettingsInfo()
    }
}
