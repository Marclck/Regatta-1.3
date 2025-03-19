//
//  WatchPlannerDataManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/03/2025.
//

import Foundation
import SwiftUI
import Combine

#if os(watchOS)
// Data model for waypoints on watchOS
struct WatchPlanPoint: Identifiable, Codable, Equatable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var accuracy: Double?
    var order: Int
    
    // Format coordinates for display
    func formattedCoordinates() -> String {
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
}

class WatchPlannerDataManager: ObservableObject {
    static let shared = WatchPlannerDataManager()
    
    @Published var currentPlan: [WatchPlanPoint] = []
    @Published var lastUpdateTime: Date?
    
    private let planStorageKey = "currentWatchPlan"
    
    init() {
        loadSavedPlan()
        
        // Subscribe to plan updates from iOS
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handlePlanUpdate),
                                              name: Notification.Name("PlanReceivedFromPhone"),
                                              object: nil)
    }
    
    // Handle incoming plan update notification
    @objc private func handlePlanUpdate(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let waypoints = userInfo["waypoints"] as? [[String: Any]] {
            processPlanUpdate(waypoints)
        }
    }
    
    // This method will be called by WatchSessionManager
    func processPlanUpdate(_ waypoints: [[String: Any]]) {
        var newPlan: [WatchPlanPoint] = []
        
        for pointDict in waypoints {
            if let idString = pointDict["id"] as? String,
               let id = UUID(uuidString: idString),
               let latitude = pointDict["latitude"] as? Double,
               let longitude = pointDict["longitude"] as? Double,
               let order = pointDict["order"] as? Int {
                
                let accuracy = pointDict["accuracy"] as? Double
                
                let point = WatchPlanPoint(
                    id: id,
                    latitude: latitude,
                    longitude: longitude,
                    accuracy: accuracy,
                    order: order
                )
                
                newPlan.append(point)
            }
        }
        
        // Sort by order
        newPlan.sort { $0.order < $1.order }
        
        DispatchQueue.main.async {
            self.currentPlan = newPlan
            self.lastUpdateTime = Date()
            self.savePlan()
            
            print("⌚️ Updated current plan with \(newPlan.count) waypoints")
        }
    }
    
    // Save current plan to persistent storage
    private func savePlan() {
        if let encoded = try? JSONEncoder().encode(currentPlan) {
            UserDefaults.standard.set(encoded, forKey: planStorageKey)
        }
    }
    
    // Load saved plan from persistent storage
    private func loadSavedPlan() {
        if let data = UserDefaults.standard.data(forKey: planStorageKey),
           let decoded = try? JSONDecoder().decode([WatchPlanPoint].self, from: data) {
            currentPlan = decoded
        }
    }
    
    // Clear current plan
    func clearPlan() {
        currentPlan = []
        lastUpdateTime = nil
        UserDefaults.standard.removeObject(forKey: planStorageKey)
    }
}
#endif
