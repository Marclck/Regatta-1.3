//
//  WatchSessionManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 19/11/2024.
//

import Foundation
import SwiftUI
import WatchKit

class WatchSessionManager: ObservableObject {
    private var session: WKExtendedRuntimeSession?
    
    func startSession() {
        // Start a new session if there isn't one active
        if session == nil || session?.state != .running {
            session = WKExtendedRuntimeSession()
            session?.start()
        }
    }
    
    func invalidateSession() {
        session?.invalidate()
        session = nil
    }
}
