//
//  SubscriptionOverlay.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 14/01/2025.
//

import Foundation
import SwiftUI

struct SubscriptionOverlay: View {
    @State private var showSubscription = false
    
    var body: some View {
        ZStack {
            // Blur effect as full screen background
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .edgesIgnoringSafeArea(.all) // Use this to make it completely full screen
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills the entire screen
            
            VStack(spacing: 12) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                Text("Astrolabe Pro")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Subscribe to access")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("Go to iPhone app")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make the VStack expand to fill available space
        }
//        .ignoresSafeArea() // Apply to the entire ZStack to ensure full screen coverage
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
}
