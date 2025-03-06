//
//  HapticManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 21/11/2024.
//

import Foundation
import SwiftUI
import WatchKit

class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    func playConfirmFeedback() {
        // Success haptic for confirm
        WKInterfaceDevice.current().play(.success)
    }
    
    func playCancelFeedback() {
        // Heavy haptic for cancel
        WKInterfaceDevice.current().play(.retry)
    }
    
    func playFailureFeedback() {
        // Heavy haptic for cancel
        WKInterfaceDevice.current().play(.failure)
    }
}
