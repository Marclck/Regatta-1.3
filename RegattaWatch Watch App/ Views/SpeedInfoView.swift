//
//  SpeedInfoView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 29/01/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import WatchKit

struct SpeedInfoView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var timerState: WatchTimerState
    @ObservedObject var startLineManager: StartLineManager
    @Binding var isCheckmark: Bool
    
    @Namespace private var animation
    
    private func getDistanceText() -> String {
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
    
    private func getSpeedText() -> String {
        if !timerState.isRunning {
            return "kn"
        }
        return String(format: "%.0f", locationManager.speed * 1.94384)
    }
    
    private var distanceButton: some View {
        Button(action: {
            isCheckmark.toggle()
            WKInterfaceDevice.current().play(.click)
            
            if isCheckmark {
                locationManager.startUpdatingLocation()
                // Set timer to turn off after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
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
                    Text(getDistanceText())
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
        .matchedGeometryEffect(id: "distance", in: animation)
    }
    
    @ViewBuilder
    private var compactView: some View {
        HStack {
            distanceButton
                .padding(.top, -10)
                .offset(x: -5, y: -10)
            
            Spacer().frame(width: 70)
            
            // Speed Display
            Text(getSpeedText())
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(timerState.isRunning ? Color.white : Color.white.opacity(0.3))
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .frame(minWidth: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(timerState.isRunning ? 0.5 : 0.1))
                )
                .matchedGeometryEffect(id: "speed", in: animation)
                .padding(.top, -10)
                .offset(x: 5, y: -10)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var expandedView: some View {
        HStack(alignment: .center) {
            // Distance Display
            Text(getDistanceText())
                .font(.zenithBeta(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(minWidth: 55, maxWidth: 55, minHeight: 10, maxHeight: 10)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                )
                .matchedGeometryEffect(id: "distance", in: animation)
            
            Spacer().frame(width: 10)
            
            // Speed Display
            Text(getSpeedText())
                .font(.zenithBeta(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(minWidth: 55, maxWidth: 55, minHeight: 10, maxHeight: 10)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                )
                .matchedGeometryEffect(id: "speed", in: animation)
        }
    }
    
    private func handleLocationState() {
        if !timerState.isRunning {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    var body: some View {
        Group {
            if timerState.isRunning {
                expandedView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
            } else {
                compactView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .onAppear {
            handleLocationState()
        }
        .onChange(of: timerState.isRunning) { _, _ in
            handleLocationState()
        }
        .onChange(of: locationManager.speed) { _, speed in
            if timerState.isRunning {
                JournalManager.shared.addDataPoint(
                    heartRate: nil,
                    speed: speed * 1.94384,  // Convert m/s to knots
                    location: locationManager.lastLocation
                )
            }
        }
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
struct PreviewSpeedInfoView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var timerState = WatchTimerState()
    @StateObject private var startLineManager = StartLineManager()
    @State private var isCheckmark = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                SpeedInfoView(
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
    PreviewSpeedInfoView()
        .frame(width: 180, height: 180)
}
#endif
