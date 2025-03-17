//
//  PlannerWaypointSection.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import SwiftUI

struct PlannerWaypointsSection: View {
    @ObservedObject var planStore: RoutePlanStore
    @Binding var activePinningPoint: UUID?
    @Binding var showSaveConfirmation: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Waypoints list
            WaypointsList(
                planStore: planStore,
                activePinningPoint: $activePinningPoint
            )
            
            // Add waypoint button
            AddWaypointButton(planStore: planStore)
            
            // Bottom action buttons
            PlannerActionButtons(
                planStore: planStore,
                showSaveConfirmation: $showSaveConfirmation
            )
        }
        .materialBackground()
        .padding(.horizontal)
        .padding(.vertical, 16)
    }
}

#Preview {
    PlannerWaypointsSection(
        planStore: RoutePlanStore.shared,
        activePinningPoint: .constant(nil),
        showSaveConfirmation: .constant(false)
    )
    .background(Color.black)
}
