//
//  RegattaWatchApp.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 16/11/2024.
//

import SwiftUI

@main
struct WatchRegattaApp: App {
    
    init() {
        // Set up notification handling
        WatchNotificationManager.shared.setupDelegate()
        
        // Initialize but don't start session yet - let it happen after proper initialization
        print("⌚️ App: Initializing ExtendedSessionManager")
        _ = ExtendedSessionManager.shared
        
        // Start session with a slight delay to ensure proper initialization
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            print("⌚️ App: Starting initial extended runtime session")
//            ExtendedSessionManager.shared.startSession()
//        }
    }
  
    @StateObject private var colorManager = ColorManager()
    @StateObject private var settings = AppSettings()
    @StateObject private var iapManager = IAPManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(colorManager)
                    .environmentObject(settings)
            }
            .environmentObject(iapManager)
        }
    }
}
