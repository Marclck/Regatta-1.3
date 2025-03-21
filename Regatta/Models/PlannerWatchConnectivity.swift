//
//  PlannerWatchConnectivity.swift
//  Regatta
//
//  Created by Chikai Lai on 17/03/2025.
//

import Foundation
import WatchConnectivity

#if os(iOS)
class PlannerWatchConnectivity {
    static let shared = PlannerWatchConnectivity()
    
    private init() {}
    
    // Convert PlanPoint to dictionary for transfer
    private func planPointToDictionary(_ point: PlanPoint) -> [String: Any] {
        var dict: [String: Any] = [
            "id": point.id.uuidString,
            "latitude": point.latitude,
            "longitude": point.longitude,
            "order": point.order
        ]
        
        // Only add accuracy if it's not nil
        if let accuracy = point.accuracy {
            dict["accuracy"] = accuracy
        }
        
        return dict
    }
    
    // Convert array of PlanPoints to array of dictionaries
    private func planPointsToArray(_ points: [PlanPoint]) -> [[String: Any]] {
        return points.map { planPointToDictionary($0) }
    }
    
    // Send current plan to watch
    func sendCurrentPlanToWatch(_ plan: [PlanPoint], planName: String = "Untitled Route") {
        // Filter out empty points (lat & lng both 0)
        let validPoints = plan.filter { !(abs($0.latitude) < 0.0001 && abs($0.longitude) < 0.0001) }
        
        // Only proceed if there are valid points
        guard !validPoints.isEmpty else {
            print("📱 No valid points to send to watch")
            return
        }
        
        // Convert to array of dictionaries
        let pointsArray = planPointsToArray(validPoints)
        
        // Create message
        let message: [String: Any] = [
            "messageType": "current_plan_update",
            "waypoints": pointsArray,
            "planName": planName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Access WatchSessionManager to send the message
        let sessionManager = WatchSessionManager.shared
        
        // Check if watch is reachable
        if sessionManager.isWatchReachable() {
            print("📱 Sending current plan \"\(planName)\" with \(validPoints.count) waypoints to watch")
            
            // Get the session
            let session = WCSession.default
            if session.activationState == .activated {
                if session.isReachable {
                    // Send using message API with reply handler
                    session.sendMessage(message, replyHandler: { reply in
                        print("📱 Plan sent successfully to watch: \(reply)")
                    }, errorHandler: { error in
                        print("📱 Error sending plan to watch: \(error.localizedDescription)")
                        
                        // Fallback to transferUserInfo if direct message fails
                        print("📱 Falling back to transferUserInfo for plan update")
                        session.transferUserInfo(message)
                    })
                } else {
                    // Use transferUserInfo when not reachable
                    print("📱 Watch not reachable, using transferUserInfo for plan update")
                    session.transferUserInfo(message)
                }
            }
        } else {
            print("📱 Watch is not reachable, cannot send plan")
        }
    }
}

// Note: The sendCurrentPlanToWatch() function is defined in RoutePlanStore+WatchExtension.swift
// No need to define it here to avoid duplicate declaration
#endif
