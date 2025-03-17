//
//  WaypointsList.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI

struct WaypointsList: View {
    @ObservedObject var planStore: RoutePlanStore
    @Binding var activePinningPoint: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waypoints")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)

            ForEach(Array(planStore.currentPlan.indices), id: \.self) { index in
                WaypointItem(
                    planStore: planStore,
                    index: index,
                    activePinningPoint: $activePinningPoint
                )
            }
        }
    }
}

#Preview {
    WaypointsList(
        planStore: RoutePlanStore.shared,
        activePinningPoint: .constant(nil)
    )
    .background(Color.black)
}
