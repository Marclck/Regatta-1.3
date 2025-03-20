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
    @ObservedObject var activeWaypointManager = ActiveWaypointManager.shared
    @ObservedObject var cruisePlanState = WatchCruisePlanState.shared
    @State private var scrollTarget: Int? = nil
    
    var body: some View {
        ScrollViewReader { scrollView in
            List {
                if plannerManager.currentPlan.isEmpty {
                    Text("No waypoints available \nLoad waypoints on iPhone")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(plannerManager.currentPlan) { waypoint in
                        WaypointRow(
                            waypoint: waypoint,
                            isActive: cruisePlanState.isActive &&
                                     activeWaypointManager.activeWaypoint?.id == waypoint.id
                        )
                        .id(waypoint.order)
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
            .onChange(of: activeWaypointManager.activeWaypoint?.order) { _, newActiveOrder in
                if cruisePlanState.isActive, let newOrder = newActiveOrder {
                    // Set scroll target to active waypoint
                    scrollTarget = newOrder
                    
                    // Scroll to active waypoint with animation
                    withAnimation {
                        scrollView.scrollTo(newOrder, anchor: .center)
                    }
                }
            }
            .onChange(of: cruisePlanState.isActive) { _, isActive in
                if isActive, let activeOrder = activeWaypointManager.activeWaypoint?.order {
                    // When cruise plan becomes active, scroll to active waypoint
                    withAnimation {
                        scrollView.scrollTo(activeOrder, anchor: .center)
                    }
                }
            }
        }
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
    let isActive: Bool
    @EnvironmentObject var colorManager: ColorManager
    
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
                    .foregroundColor(isActive ? .green : .blue)
                Text(waypoint.formattedCoordinates())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
        .padding(isActive ? 6 : 0)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isActive ? Color.green : Color.clear,
                    lineWidth: isActive ? 2 : 0,
                    antialiased: true
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? Color.green.opacity(0.2) : Color.clear)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

struct WatchPlannerView_Previews: PreviewProvider {
    static var previews: some View {
        WatchPlannerView()
            .environmentObject(ColorManager())
    }
}
#endif
