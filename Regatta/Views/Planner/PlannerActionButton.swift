//
//  PlannerActionButton.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI

struct PlannerActionButtons: View {
    @ObservedObject var planStore: RoutePlanStore
    @Binding var showSaveConfirmation: Bool
    
    var body: some View {
        HStack {
            // Clear button
            Button(action: {
                planStore.resetCurrentPlan()
            }) {
                Text("Clear")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                    .background(Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.3))
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
                            ? Color.green.opacity(0.3)
                        : (planStore.isPlanSaved ? Color.white.opacity(0.3) : Color.white.opacity(0.3))
                    )
                    .cornerRadius(12)
            }
            .disabled(planStore.isPlanSaved && !showSaveConfirmation)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}

#Preview {
    PlannerActionButtons(
        planStore: RoutePlanStore.shared,
        showSaveConfirmation: .constant(false)
    )
    .background(Color.black)
}
