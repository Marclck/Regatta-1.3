//
//  WatchPlannerView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 18/03/2025.
//

import Foundation
import SwiftUI

#if os(watchOS)
struct WatchPlannerView: View {
    @ObservedObject var plannerManager = WatchPlannerDataManager.shared
    
    var body: some View {
        List {
            if plannerManager.currentPlan.isEmpty {
                Text("No waypoints available \nLoad waypoints on iPhone")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(plannerManager.currentPlan) { waypoint in
                    WaypointRow(waypoint: waypoint)
                }
            }
            
            if let lastUpdate = plannerManager.lastUpdateTime {
                HStack {
                    Spacer()
                    Text("Last updated: \(timeAgoString(from: lastUpdate))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(CarouselListStyle())
        .navigationTitle("Race Plan")
    }
    
    // Helper function to display time ago
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "just now"
        }
    }
}

struct WaypointRow: View {
    let waypoint: WatchPlanPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Waypoint \(waypoint.order + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.blue)
                Text(waypoint.formattedCoordinates())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
}

struct WatchPlannerView_Previews: PreviewProvider {
    static var previews: some View {
        WatchPlannerView()
    }
}
#endif
