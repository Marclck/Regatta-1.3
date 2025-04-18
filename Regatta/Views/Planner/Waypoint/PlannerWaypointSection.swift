//
//  PlannerWaypointSection.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import SwiftUI
import CoreLocation

struct PlannerWaypointsSection: View {
    @ObservedObject var planStore: RoutePlanStore
    @Binding var activePinningPoint: UUID?
    @Binding var showSaveConfirmation: Bool
    
    // Add binding for center coordinate
    @Binding var centerCoordinate: CLLocationCoordinate2D
    
    var body: some View {
        VStack(spacing: 12) {
            // Waypoints list - pass the center coordinate binding
            WaypointsList(
                planStore: planStore,
                activePinningPoint: $activePinningPoint,
                centerCoordinate: $centerCoordinate // Pass the binding
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
        showSaveConfirmation: .constant(false),
        centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // Add dummy coordinate for preview
    )
    .background(Color.black)
}
