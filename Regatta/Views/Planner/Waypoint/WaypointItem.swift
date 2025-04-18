//
//  WaypointItem.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct WaypointItem: View {
    @ObservedObject var planStore: RoutePlanStore
    let index: Int
    @Binding var activePinningPoint: UUID?
    
    // Add binding for center coordinate
    @Binding var centerCoordinate: CLLocationCoordinate2D
    
    var body: some View {
        // Safety check to ensure the index is valid
        if index < planStore.currentPlan.count {
            let point = planStore.currentPlan[index]
            
            // Use a more direct binding to avoid potential issues
            let pointBinding = Binding<PlanPoint>(
                get: {
                    // Safety check again in case the array changes during rendering
                    if index < planStore.currentPlan.count {
                        return planStore.currentPlan[index]
                    } else {
                        // Return a default value if the index is out of bounds
                        return PlanPoint(latitude: 0, longitude: 0, order: 0)
                    }
                },
                set: { newValue in
                    // Safety check again
                    if index < planStore.currentPlan.count {
                        planStore.currentPlan[index] = newValue
                    }
                }
            )
            
            LocationPointEditor(
                point: pointBinding,
                index: index,
                onDelete: {
                    // Only allow deletion if it's not the first point and index is valid
                    if index > 0 && index < planStore.currentPlan.count {
                        // Use the safer method that uses the point's ID instead of index
                        let pointToRemove = planStore.currentPlan[index]
                        planStore.removePointById(pointToRemove.id)
                    }
                },
                onStartPinning: {
                    // Safety check to ensure we don't use an out-of-bounds index
                    if index < planStore.currentPlan.count {
                        activePinningPoint = planStore.currentPlan[index].id
                    }
                },
                onStopPinning: {
                    activePinningPoint = nil
                },
                centerCoordinate: $centerCoordinate // Pass the center coordinate binding
            )
            .padding(.horizontal)
            .draggable(point) {
                // Use a container with fixed size to ensure the dragged item looks the same
                LocationPointEditor(
                    point: pointBinding,
                    index: index,
                    onDelete: {},  // Disable buttons during drag preview
                    onStartPinning: {},
                    onStopPinning: {},
                    centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // Dummy binding for preview
                )
                .padding(.horizontal)
                .compositingGroup()  // Ensures the view is rendered as a single unit
                .opacity(0.85)  // Slightly transparent to indicate it's being dragged
            }
            .dropDestination(for: PlanPoint.self) { items, location in
                guard let droppedItem = items.first,
                      let fromIndex = planStore.currentPlan.firstIndex(where: { $0.id == droppedItem.id }),
                      fromIndex != index else {
                    return false
                }
                
                // Perform the reordering
                // Use DispatchQueue.main.async to ensure UI updates correctly
                DispatchQueue.main.async {
                    withAnimation {
                        planStore.reorderPoints(fromIndex: fromIndex, toIndex: index)
                    }
                }
                return true
            }
            // Add this modifier to ensure drag and drop animations work correctly
            .onChange(of: planStore.currentPlan) { _ in
                // Force a refresh when the plan changes
            }
        } else {
            // Fallback view if the index is invalid
            Text("Invalid waypoint index")
                .foregroundColor(.red)
                .padding()
        }
    }
}

#Preview {
    WaypointItem(
        planStore: RoutePlanStore.shared,
        index: 0,
        activePinningPoint: .constant(nil),
        centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // Add dummy center coordinate for preview
    )
    .background(Color.black)
    .previewLayout(.sizeThatFits)
}
