//
//  WaypointsList.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import SwiftUI
import CoreLocation

struct WaypointsList: View {
    @ObservedObject var planStore: RoutePlanStore
    @Binding var activePinningPoint: UUID?
    
    // Add binding for center coordinate
    @Binding var centerCoordinate: CLLocationCoordinate2D
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(planStore.currentPlan.indices, id: \.self) { index in
                    WaypointItem(
                        planStore: planStore,
                        index: index,
                        activePinningPoint: $activePinningPoint,
                        centerCoordinate: $centerCoordinate // Pass the center coordinate
                    )
                }
            }
        }
        .padding(.top, 15)
    }
}

#Preview {
    WaypointsList(
        planStore: RoutePlanStore.shared,
        activePinningPoint: .constant(nil),
        centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // Add dummy coordinate for preview
    )
    .background(Color.black)
    .previewLayout(.sizeThatFits)
}
