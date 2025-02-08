//
//  AltSpeedInfoView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 30/01/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import WatchKit

struct CourseDeviationView: View {
    let deviation: Double
    let maxDeviation: Double = 30.0
    let stepsPerSide = 3
    
    private func getCircleFill(_ position: Int, isPositive: Bool) -> Double {
        let stepSize = maxDeviation / Double(stepsPerSide)
        let relevantDeviation = isPositive ? deviation : -deviation
        let threshold = Double(position + 1) * stepSize
        let previousThreshold = Double(position) * stepSize
        
        if relevantDeviation <= previousThreshold { return 0.2 }  // Unfilled
        if relevantDeviation >= threshold { return 0.8 }  // Fully filled
        
        // Partially filled
        return 0.1 + (0.4 * (relevantDeviation - previousThreshold) / stepSize)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Negative deviation indicators
            ForEach((0..<stepsPerSide).reversed(), id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .opacity(getCircleFill(index, isPositive: false))
                    .frame(width: 10, height: 10)
            }
            
            // Course display spacer
            Spacer()
                .frame(width: 55)
            
            // Positive deviation indicators
            ForEach(0..<stepsPerSide, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .opacity(getCircleFill(index, isPositive: true))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

struct AltSpeedInfoView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var timerState: WatchTimerState
    @ObservedObject var startLineManager: StartLineManager
    @StateObject private var courseTracker = CourseTracker()
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
        let speedInKnots = locationManager.speed * 1.94384
        return speedInKnots <= 0 ? "-" : String(format: "%.1f", speedInKnots)
    }
    
    private func getCardinalDirection(_ degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int(round(degrees.truncatingRemainder(dividingBy: 360) / 45)) % 8
        return directions[index]
    }
    
    private func getCourseText() -> String {
        if !timerState.isRunning {
            return "°M"
        }
        
        guard locationManager.isLocationValid,
              let location = locationManager.lastLocation,
              location.course >= 0 else {
            return "COURSE"
        }
        
        let cardinal = getCardinalDirection(location.course)
        return String(format: "%@%.0f°", cardinal, location.course)
    }
    
    private var distanceButton: some View {
        Button(action: {
            isCheckmark.toggle()
            if isCheckmark {
                locationManager.startUpdatingLocation()
                // Auto-stop after 120 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
                    if isCheckmark && !timerState.isRunning {  // Added timer check
                        isCheckmark = false
                        locationManager.stopUpdatingLocation()
                    }
                }
            } else {
                if !timerState.isRunning {  // Added timer check
                    locationManager.stopUpdatingLocation()
                }
            }
        }) {
            Group {
                if isCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: timerState.isRunning ? 20 : 14, weight: .bold))
                } else {
                    Text(getDistanceText())
                        .font( timerState.isRunning ?
                            .zenithBeta(size: 20, weight: .medium):
                                .system(size:14, design: .monospaced))
                }
            }
            .foregroundColor(isCheckmark ? Color.black : timerState.isRunning ? Color.white : Color.white.opacity(0.3))
            .padding(.horizontal, 4)
            .padding(.vertical, isCheckmark ? 5.2 : 4)
            .frame(minWidth: timerState.isRunning ? 55 : 36)
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
                            ).opacity(timerState.isRunning ? 0.05 : 0.1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var courseDisplay: some View {
        ZStack {
            Text(getCourseText())
                .font(.system(size: timerState.isRunning ? 12 : 12, design: .monospaced))
                .foregroundColor(timerState.isRunning ? Color.white : Color.white.opacity(0.3))
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .frame(minWidth: timerState.isRunning ? 55 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(timerState.isRunning ? 0.05 : 0.1))
                )
            
//            if courseTracker.isLocked {
                CourseDeviationView(deviation: courseTracker.currentDeviation)
                    .frame(width: 100)
                    .transition(.opacity)
//            }
        }
        .opacity(timerState.isRunning ? 1 : 0)
    }
    
    private var speedDisplay: some View {
        Text(getSpeedText())
            .font( timerState.isRunning ?
                .zenithBeta(size: 20, weight: .medium):
                    .system(size:14, design: .monospaced))
            .foregroundColor(timerState.isRunning ? Color.white : Color.white.opacity(0.3))
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: timerState.isRunning ? 55 : 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(timerState.isRunning ? 0.05 : 0.1))
            )
            .matchedGeometryEffect(id: "speed", in: animation)
    }
    
    private func handleLocationState() {
        if !timerState.isRunning {
            locationManager.stopUpdatingLocation()
            courseTracker.resetLock()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: timerState.isRunning ? 10 : 70) {
                distanceButton
                    .offset(x: timerState.isRunning ? 0 : -5, y: timerState.isRunning ? 0 : -20)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: timerState.isRunning)
                
                speedDisplay
                    .offset(x: timerState.isRunning ? 0 : 5, y: timerState.isRunning ? 0 : -20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: timerState.isRunning)
            }
            
            if timerState.isRunning {
                courseDisplay
                    .offset(y: 40)
                    .animation(.spring(dampingFraction: 0.8), value: timerState.isRunning)
            }
        }
        .padding(.horizontal)
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
                    speed: speed * 1.94384,
                    location: locationManager.lastLocation
                )
            }
        }
        .onChange(of: locationManager.lastLocation) { _, _ in
            if timerState.isRunning, let location = locationManager.lastLocation {
                startLineManager.updateDistance(currentLocation: location)
                if location.course >= 0 {
                    courseTracker.updateCourse(location.course)
                }
            }
        }
        .onDisappear {
            if isCheckmark && !timerState.isRunning {
                locationManager.stopUpdatingLocation()
            }
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct PreviewAltSpeedInfoView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var timerState = WatchTimerState()
    @StateObject private var startLineManager = StartLineManager()
    @State private var isCheckmark = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                AltSpeedInfoView(
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
    PreviewAltSpeedInfoView()
        .frame(width: 180, height: 180)
}
#endif
