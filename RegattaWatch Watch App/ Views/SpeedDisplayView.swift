//
//  SpeedDisplayView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 20/01/2025.
//

import Foundation
import SwiftUI

struct SpeedDisplayView<Manager: LocationManagerProtocol, Timer: WatchTimerStateProtocol>: View {
    @ObservedObject var locationManager: Manager
    @ObservedObject var timerState: Timer
    @State private var rotationDegrees: Double = 0
    
    var body: some View {
        
        let displayText = timerState.isRunning
            ? String(format: "%.0f", locationManager.speed * 1.94384)
            : "kn"
        
        Text(displayText)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    Color.white.opacity(0.80),
                                    .white
                                ]),
                                center: .center,
                                angle: .degrees(rotationDegrees)
                            )
                        )
                )
                .onAppear {
                    withAnimation(
                        .linear(duration: 6)
                        .repeatForever(autoreverses: false)
                    ) {
                        rotationDegrees = 360
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: locationManager.speed)
    }
}

// MARK: - Protocols
protocol LocationManagerProtocol: ObservableObject {
    var speed: Double { get }
}

protocol WatchTimerStateProtocol: ObservableObject {
    var isRunning: Bool { get }
}

extension LocationManager: LocationManagerProtocol {}
extension WatchTimerState: WatchTimerStateProtocol {}

// MARK: - Preview Helpers
#if DEBUG
private class PreviewLocationManager: ObservableObject {
    @Published var speed: Double = 5.7
}

private class PreviewTimerState: ObservableObject {
    @Published var isRunning: Bool = true
}

extension PreviewLocationManager: LocationManagerProtocol {}
extension PreviewTimerState: WatchTimerStateProtocol {}

struct PreviewSpeedDisplayView: View {
    @StateObject private var locationManager = PreviewLocationManager()
    @StateObject private var timerState = PreviewTimerState()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black // Background to make white text visible
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
        .frame(width: 180, height: 180) // Typical watch dimensions
}
#endif
