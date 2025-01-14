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
                
                if !iapManager.canAccessPremiumFeatures() {
                    SubscriptionOverlay()
                }
            }
            .environmentObject(iapManager)
        }
    }
}
