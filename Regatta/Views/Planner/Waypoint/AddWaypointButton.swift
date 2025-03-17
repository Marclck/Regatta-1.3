//
//  AddWaypointButton.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI

struct AddWaypointButton: View {
    @ObservedObject var planStore: RoutePlanStore
    
    var body: some View {
        if planStore.currentPlan.count < 12 {
            Button(action: {
                planStore.addPoint()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Waypoint")
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    AddWaypointButton(planStore: RoutePlanStore.shared)
        .background(Color.black)
}
