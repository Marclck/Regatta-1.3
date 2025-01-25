//
//  SpeedDisplayView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 20/01/2025.
//

import Foundation
import SwiftUI

struct SpeedDisplayView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var timerState: WatchTimerState
    
    private func handleLocationState() {
        if !timerState.isRunning {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    var body: some View {
        let displayText = timerState.isRunning
            ? String(format: "%.0f", locationManager.speed * 1.94384)
            : "kn"
        
        Text(displayText)
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(timerState.isRunning ? Color.white : Color.white.opacity(0.3))
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 30) // Ensures minimum width of 40 points
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(timerState.isRunning ? Color.white.opacity(0.5) : Color.white.opacity(0.1))
            )
            .onAppear {
                handleLocationState()
            }
            .onChange(of: timerState.isRunning) { _, _ in
                handleLocationState()
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct PreviewSpeedDisplayView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var timerState = WatchTimerState()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                SpeedDisplayView(
                    locationManager: locationManager,
                    timerState: timerState
                )
            }
        }
    }
}

#Preview {
    PreviewSpeedDisplayView()
        .frame(width: 180, height: 180)
}
#endif
