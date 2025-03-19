//
//  RoutePlanStore+WatchExtension.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/03/2025.
//

import Foundation

#if os(iOS)
// Extension to the RoutePlanStore to update saved/loaded plans to Watch
extension RoutePlanStore {
    // Override the existing savePlan method to also send to watch
    func savePlanWithWatch() {
        // First use the original save functionality
        savePlan()
        
        // Then send to watch
        sendCurrentPlanToWatch()
    }
    
    // Override the loadPlan method to also send to watch
    func loadPlanWithWatch(_ plan: RoutePlan) {
        // First use the original load functionality
        loadPlan(plan)
        
        // Then send to watch
        sendCurrentPlanToWatch()
    }
    
    // Send current plan to watch
    func sendCurrentPlanToWatch() {
        PlannerWatchConnectivity.shared.sendCurrentPlanToWatch(currentPlan)
    }
}
#endif
