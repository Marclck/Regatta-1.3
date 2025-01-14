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
            // Blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
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
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
}
