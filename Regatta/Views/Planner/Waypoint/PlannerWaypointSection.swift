//
//  PlannerWaypointSection.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI

struct PlannerWaypointsSection: View {
    @ObservedObject var planStore: RoutePlanStore
    @Binding var activePinningPoint: UUID?
    @Binding var showSaveConfirmation: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Waypoints")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Draggable list of points
            ForEach(Array(planStore.currentPlan.enumerated()), id: \.element.id) { index, _ in
                LocationPointEditor(
                    point: Binding(
                        get: { planStore.currentPlan[index] },
                        set: { planStore.currentPlan[index] = $0 }
                    ),
                    index: index,
                    onDelete: {
                        planStore.removePoint(at: index)
                    },
                    onStartPinning: {
                        activePinningPoint = planStore.currentPlan[index].id
                    },
                    onStopPinning: {
                        activePinningPoint = nil
                    }
                )
                .padding(.horizontal)
                .draggable(planStore.currentPlan[index]) {
                    // Preview for dragging
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(.headline))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color(hex: ColorTheme.ultraBlue.rawValue)))
                        
                        Text("Waypoint \(index + 1)")
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .dropDestination(for: PlanPoint.self) { items, location in
                    guard let droppedItem = items.first,
                          let fromIndex = planStore.currentPlan.firstIndex(where: { $0.id == droppedItem.id }),
                          fromIndex != index else {
                        return false
                    }
                    
                    // Perform the reordering
                    planStore.reorderPoints(fromIndex: fromIndex, toIndex: index)
                    return true
                }
            }
            
            // Add waypoint button (if less than 12 points)
            if planStore.currentPlan.count < 12 {
                Button(action: {
                    planStore.addPoint()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Waypoint")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            
            // Bottom action buttons
            HStack {
                // Clear button
                Button(action: {
                    planStore.resetCurrentPlan()
                }) {
                    Text("Clear")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: ColorTheme.signalOrange.rawValue))
                        .cornerRadius(12)
                }
                
                // Save button
                Button(action: {
                    planStore.savePlan()
                    showSaveConfirmation = true
                    
                    // Hide the confirmation after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSaveConfirmation = false
                    }
                }) {
                    Text(showSaveConfirmation ? "Saved!" : "Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            showSaveConfirmation
                                ? Color.green
                                : (planStore.isPlanSaved ? Color.white : Color.white)
                        )
                        .cornerRadius(12)
                }
                .disabled(planStore.isPlanSaved && !showSaveConfirmation)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .materialBackground()
        .padding(.horizontal)
        .padding(.bottom, 16)
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
