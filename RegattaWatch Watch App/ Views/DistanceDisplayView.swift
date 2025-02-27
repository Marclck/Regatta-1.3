//
//  DistanceDisplayView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 26/01/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import WatchKit

struct DistanceDisplayView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var timerState: WatchTimerState
    @ObservedObject var startLineManager: StartLineManager
    @Binding var isCheckmark: Bool
    
    func getDisplayText() -> String {
        if !timerState.isRunning {
            return "DtL"
        }
        
        guard locationManager.isLocationValid else {
            return "-"
        }
        
        guard let distance = startLineManager.currentDistance else {
            return "-"
        }
        
        if distance > 99_000 {  // Over 99km
            return "FAR"
        } else if distance >= 10_000 {  // 10km to 99km
            return String(format: "%.0fk", distance / 1000)
        } else if distance >= 1_000 {  // 1km to 9.9km
            return String(format: "%.1fk", distance / 1000)
        } else {
            return String(format: "%.0f", distance)
        }
    }
    
    var body: some View {
        Button(action: {
            isCheckmark.toggle()
            WKInterfaceDevice.current().play(.click)
            
            if isCheckmark {
                locationManager.startUpdatingLocation()
                // Set timer to turn off after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if isCheckmark { // Check if still in checkmark state
                        isCheckmark = false
                        locationManager.stopUpdatingLocation()
                        WKInterfaceDevice.current().play(.click)
                    }
                }
            } else {
                locationManager.stopUpdatingLocation()
            }
        }) {
            Group {
                if isCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                } else {
                    Text(getDisplayText())
                        .font(.system(size: 14, design: .monospaced))
                }
            }
            .foregroundColor(isCheckmark ? Color.black : timerState.isRunning ? Color.white : Color.white.opacity(0.3))
                .padding(.horizontal, 4)
                .padding(.vertical, isCheckmark ? 5.2 : 4)
                .frame(minWidth: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isCheckmark ?
                            LinearGradient(
                                colors: [Color.white, Color.white],
                                startPoint: .leading,
                                endPoint: .trailing
                            ).opacity(0.5) :
                            LinearGradient(
                                colors: [
                                    startLineManager.leftButtonState == .green ? Color.green : Color.white,
                                    startLineManager.rightButtonState == .green ? Color.green : Color.white
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ).opacity(timerState.isRunning ? 0.5 : 0.1)
                        )
                )
        }
        .buttonStyle(.plain)
        .onChange(of: locationManager.lastLocation) { _ in
            if timerState.isRunning, let location = locationManager.lastLocation {
                startLineManager.updateDistance(currentLocation: location)
            }
        }
        .onDisappear {
            if isCheckmark {
                locationManager.stopUpdatingLocation()
            }
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct PreviewDistanceDisplayView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var timerState = WatchTimerState()
    @StateObject private var startLineManager = StartLineManager()
    @State private var isCheckmark = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                DistanceDisplayView(
                    locationManager: locationManager,
                    timerState: timerState,
                    startLineManager: startLineManager,
                    isCheckmark: $isCheckmark
                )
            }
        }
    }
}

#Preview {
    PreviewDistanceDisplayView()
        .frame(width: 180, height: 180)
}
#endif
