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
    
    private func getRectWidth(_ position: Int, isPositive: Bool) -> Double {
        // Return 0 if this side shouldn't be filled
        if (isPositive && deviation < 0) || (!isPositive && deviation > 0) {
            return 0
        }
        
        let stepSize = maxDeviation / Double(stepsPerSide)
        let relevantDeviation = abs(deviation)
        let startThreshold = Double(position) * stepSize
        let endThreshold = Double(position + 1) * stepSize
        
        if relevantDeviation <= startThreshold { return 0 }  // Not reached this circle yet
        if relevantDeviation >= endThreshold { return 10 }   // Fully filled this circle
        
        // Partially filling this circle
        return 10 * (relevantDeviation - startThreshold) / stepSize
    }
    
    private func getCircleContent(position: Int, isPositive: Bool) -> some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white)
                .opacity(0.2)
                .frame(width: 10, height: 10)
            
            // Fill rectangle
            Rectangle()
                .fill(Color.white)
                .opacity(0.8)
                .frame(width: getRectWidth(position, isPositive: isPositive), height: 10)
                .frame(width: 10, alignment: isPositive ? .leading : .trailing)
                .clipShape(Circle())
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Negative deviation indicators
            ForEach((0..<stepsPerSide).reversed(), id: \.self) { index in
                getCircleContent(position: index, isPositive: false)
            }
            
            // Course display spacer
            Spacer()
                .frame(width: 55)
            
            // Positive deviation indicators
            ForEach(0..<stepsPerSide, id: \.self) { index in
                getCircleContent(position: index, isPositive: true)
            }
        }
        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: deviation)
    }
}

struct AltSpeedInfoView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var timerState: WatchTimerState
    @ObservedObject var startLineManager: StartLineManager
    @StateObject private var courseTracker = CourseTracker()
    @EnvironmentObject var colorManager: ColorManager
    @Binding var isCheckmark: Bool
    
    @State private var isGPSEnabled = true
    @State private var showGPSOnMessage = false
    @State private var isGPSForcedOn = false // True when distance button forces GPS on
    @State private var showGPSOrangeColor = false
    @State private var showGPSOffMessage = false  // Added this state

    @Namespace private var animation
    
    // MARK: - Helper Functions
    private func toggleGPS() {
        if !isGPSForcedOn {
            isGPSEnabled.toggle()
            WKInterfaceDevice.current().play(.click)
            
            if isGPSEnabled {
                locationManager.startUpdatingLocation()
                showGPSOnMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showGPSOnMessage = false
                }
            } else {
                locationManager.stopUpdatingLocation()
                showGPSOrangeColor = true
                showGPSOffMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showGPSOrangeColor = false
                }
            }
        }
    }
    
    private func forceGPSOn() {
        if showGPSOrangeColor {
            showGPSOrangeColor = false
        }
        isGPSEnabled = true
        isGPSForcedOn = true
        showGPSOffMessage = false
        locationManager.startUpdatingLocation()
        WKInterfaceDevice.current().play(.click)
    }
    
    private func releaseGPSForce() {
        isGPSForcedOn = false
        // Don't change GPS state here - it should return to its previous state
    }
    
    // MARK: - View Components
    private var speedButton: some View {
        Button(action: {
            if timerState.isRunning {
                toggleGPS()
            }
        }) {
            if !isGPSEnabled {
                // GPS OFF state
                VStack(spacing: -2) {
                    Text("GPS")
                    Text("OFF")
                }
                .font(.zenithBeta(size: 14, weight: .medium))
                .scaleEffect(y:0.9)
                .foregroundColor(showGPSOrangeColor ? .orange : .white.opacity(0.3))
                .frame(minWidth: timerState.isRunning ? 55 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(showGPSOrangeColor ?
                            Color.orange.opacity(0.4) :
                            Color.white.opacity(timerState.isRunning ? 0.05 : 0.2))
                )
                
            } else if showGPSOnMessage {
                
                // Temporary GPS ON message
                VStack(spacing: -2) {
                    Text("GPS")
                    Text("ON")
                }
                .font(.zenithBeta(size: 14, weight: .medium))
                .scaleEffect(y:0.9)
                .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue))
                .frame(minWidth: timerState.isRunning ? 55 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4))
                )

            } else {
                // Speed display
                Text(getSpeedText())
                    .font(timerState.isRunning ?
                        .zenithBeta(size: 20, weight: .medium):
                            .zenithBeta(size: 14, weight: .medium))
                    .foregroundColor(timerState.isRunning ? .white : .white.opacity(0.5))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .frame(minWidth: timerState.isRunning ? 55 : 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(timerState.isRunning ? 0.05 : 0.2))
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!timerState.isRunning || isGPSForcedOn)
        .animation(.easeInOut(duration: 0.2), value: showGPSOrangeColor)
        .animation(.easeInOut(duration: 0.2), value: showGPSOnMessage)
    }
    
    private var distanceButton: some View {
        Button(action: {
            isCheckmark.toggle()
            if isCheckmark {
                forceGPSOn()
                // Auto-stop after 120 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
                    if isCheckmark && !timerState.isRunning {
                        isCheckmark = false
                        releaseGPSForce()
                        if !isGPSEnabled {
                            locationManager.stopUpdatingLocation()
                        }
                    }
                }
            } else {
                releaseGPSForce()
                if !timerState.isRunning {
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
                        .font(timerState.isRunning ?
                            .zenithBeta(size: 20, weight: .medium):
                                .zenithBeta(size: 14, weight: .medium))
                }
            }
            .foregroundColor(isCheckmark ? Color.black :
                            showGPSOrangeColor ? .orange :
                            !isGPSEnabled ? .white.opacity(0.3) :
                            (timerState.isRunning ? .white : .white.opacity(0.3)))
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
                            showGPSOrangeColor ?
                            LinearGradient(
                                colors: [Color.orange, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ).opacity(0.4) :
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
        .animation(.easeInOut(duration: 0.2), value: showGPSOrangeColor)
    }
    
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
                        .fill(courseTracker.isLocked ? Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3) : Color.white.opacity(timerState.isRunning ? 0.05 : 0.1))
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
                    .zenithBeta(size: 14, weight: .medium))
            .foregroundColor(timerState.isRunning ? Color.white : Color.white.opacity(0.5))
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
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: timerState.isRunning)
                
                speedButton
                    .offset(x: timerState.isRunning ? 0 : 5, y: timerState.isRunning ? 0 : -20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: timerState.isRunning)
            }
            
            if !isGPSEnabled || showGPSOnMessage {
                Spacer().frame(height:5)
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
            if timerState.isRunning && isGPSEnabled {
                JournalManager.shared.addDataPoint(
                    heartRate: nil,
                    speed: speed * 1.94384,
                    location: locationManager.lastLocation
                )
            }
        }
        .onChange(of: locationManager.lastLocation) { _, _ in
            if timerState.isRunning && isGPSEnabled,
               let location = locationManager.lastLocation {
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

// MARK: - Preview
#if DEBUG
struct PreviewCourseDeviationView: View {
    var body: some View {
        ZStack {
            Color.black
            CourseDeviationView(deviation: -15)
        }
    }
}

#Preview("Deviation -15°") {
    PreviewCourseDeviationView()
        .frame(width: 180, height: 50)
}
#endif
