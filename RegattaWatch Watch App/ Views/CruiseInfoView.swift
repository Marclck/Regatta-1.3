//
//  CruiseInfoView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 07/02/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import WatchKit

struct CruiseDeviationView: View {
    @EnvironmentObject var settings: AppSettings
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
        let fillColor = settings.lightMode ? Color.black : Color.white
        
        return ZStack {
            // Background circle
            Circle()
                .fill(fillColor)
                .opacity(0.2)
                .frame(width: 10, height: 10)
            
            // Fill rectangle
            Rectangle()
                .fill(fillColor)
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

struct CruiseInfoView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    @ObservedObject var locationManager: LocationManager
    @StateObject private var courseTracker = CourseTracker()
    @StateObject private var lastReadingManager = LastReadingManager()
    @State private var isConfirmingReset: Bool = false
    @State private var resetTimer: Timer?
    @State private var showGPSOffMessage = false
    @State private var showGPSOnMessage = false
    
    @State private var totalDistance: CLLocationDistance = 0
    @State private var lastLocation: CLLocation?
    
    @Namespace private var animation
    
    private func startResetTimer() {
        // Cancel existing timer if any
        resetTimer?.invalidate()
        
        // Create new timer
        resetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                isConfirmingReset = false
            }
        }
    }
    
    private func getDistanceText() -> String {
        if !locationManager.isMonitoring {
            let lastDistance = lastReadingManager.distance
            if lastDistance == 0 {
                return "9"
            }
            
            if lastDistance > 99_000 {  // Over 99km
                return "FAR"
            } else if lastDistance >= 10_000 {  // 10km to 99km
                return String(format: "%.0fk", lastDistance / 1000)
            } else if lastDistance >= 1_000 {  // 1km to 9.9km
                return String(format: "%.1fk", lastDistance / 1000)
            } else {
                return String(format: "%.0f", lastDistance)
            }
        }
        
        if totalDistance == 0 {
            return "-"
        }
        
        if totalDistance > 99_000 {  // Over 99km
            return "FAR"
        } else if totalDistance >= 10_000 {  // 10km to 99km
            return String(format: "%.0fk", totalDistance / 1000)
        } else if totalDistance >= 1_000 {  // 1km to 9.9km
            return String(format: "%.1fk", totalDistance / 1000)
        } else {
            return String(format: "%.0f", totalDistance)
        }
    }
    
    private func updateDistance(newLocation: CLLocation) {
        guard locationManager.isMonitoring else { return }
        
        if let lastLoc = lastLocation {
            let increment = newLocation.distance(from: lastLoc)
            if increment > 0 {  // Only add if we've actually moved
                totalDistance += increment
            }
        }
        
        lastLocation = newLocation
    }
    
    private func resetTracking() {
        totalDistance = 0
        lastLocation = nil
        lastReadingManager.resetDistance()
    }
    
    private func getSpeedText() -> String {
        if !locationManager.isMonitoring {
            let lastSpeed = lastReadingManager.speed
            return lastSpeed <= 0 ? "41" : String(format: "%.1f", lastSpeed)
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
        if !locationManager.isMonitoring {
            // Check if we have default or invalid values
            if lastReadingManager.course <= 0 || lastReadingManager.cardinalDirection.isEmpty {
                return "COURSE"
            }
            return String(format: "%@%.0f°", lastReadingManager.cardinalDirection, lastReadingManager.course)
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
            WKInterfaceDevice.current().play(.click)
            if isConfirmingReset {
                resetTracking()
                isConfirmingReset = false
                resetTimer?.invalidate()
                resetTimer = nil
            } else {
                isConfirmingReset = true
                startResetTimer()
            }
        }) {
            Group {
                if isConfirmingReset {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .heavy))
                        .symbolVariant(.fill)
                        .foregroundColor(.orange)
                } else {
                    Text(getDistanceText())
                        .font(.zenithBeta(size: 20, weight: .medium))
                        .foregroundColor(
                            (showGPSOffMessage || showGPSOnMessage) ?
                                (showGPSOffMessage ? .orange : Color(hex: colorManager.selectedTheme.rawValue)) :
                                (locationManager.isMonitoring ?
                                    Color(hex: colorManager.selectedTheme.rawValue) :
                                    (settings.lightMode ? .black : .white))
                        )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 55)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isConfirmingReset ? Color.orange.opacity(0.2) :
                            (showGPSOffMessage || showGPSOnMessage) ?
                                (showGPSOffMessage ?
                                    Color.orange.opacity(0.4) :
                                    Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4)) :
                                (locationManager.isMonitoring ?
                                    Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                                    (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.05)))
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: showGPSOffMessage)
        .animation(.easeInOut(duration: 0.2), value: showGPSOnMessage)
    }
    
    private var courseDisplay: some View {
        ZStack {
            Text(getCourseText())
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(settings.lightMode ? .black : .white)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .frame(minWidth: 55)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(courseTracker.isLocked ? Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3) : settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.05))
                )
                
            
            CruiseDeviationView(deviation: locationManager.isMonitoring ?
                               courseTracker.currentDeviation : lastReadingManager.deviation)  // Use stored deviation when not monitoring
                .frame(width: 100)
                .transition(.opacity)
        }
    }
    
    private var speedDisplay: some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            if locationManager.isMonitoring {
                // Save current readings before stopping
                if let location = locationManager.lastLocation {
                    lastReadingManager.saveReading(
                        speed: locationManager.speed * 1.94384,
                        distance: totalDistance,
                        course: location.course,
                        direction: getCardinalDirection(location.course),
                        deviation: courseTracker.currentDeviation
                    )
                }
                locationManager.stopUpdatingLocation()
                showGPSOffMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showGPSOffMessage = false
                }
            } else {
                locationManager.startUpdatingLocation()
                showGPSOnMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showGPSOnMessage = false
                }
            }
        }) {
            if showGPSOffMessage {
                VStack(spacing: -2) {
                    Text("GPS")
                    Text("OFF")
                }
                .font(.zenithBeta(size: 14, weight: .medium))
                .scaleEffect(y: 0.9)
                .foregroundColor(.orange)
                .frame(minWidth: 55)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.4))
                )
            } else if showGPSOnMessage {
                VStack(spacing: -2) {
                    Text("GPS")
                    Text("ON")
                }
                .font(.zenithBeta(size: 14, weight: .medium))
                .scaleEffect(y: 0.9)
                .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue))
                .frame(minWidth: 55)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4))
                )
            } else {
                Text(getSpeedText())
                    .font(.zenithBeta(size: 20, weight: .medium))
                    .foregroundColor(locationManager.isMonitoring ?
                        Color(hex: colorManager.selectedTheme.rawValue) :
                        (settings.lightMode ? .black : .white))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .frame(minWidth: 55)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(locationManager.isMonitoring ?
                                Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                                (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.05)))
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: showGPSOffMessage)
        .animation(.easeInOut(duration: 0.2), value: showGPSOnMessage)
        .matchedGeometryEffect(id: "speed", in: animation)
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                distanceButton
                speedDisplay
            }
            if showGPSOffMessage || showGPSOnMessage {
                Spacer().frame(height:5)

            }
            
            courseDisplay
                .offset(y: 40)
        }
        .padding(.horizontal)
        .onChange(of: locationManager.speed) { _, speed in
            JournalManager.shared.addDataPoint(
                heartRate: nil,
                speed: speed * 1.94384,
                location: locationManager.lastLocation
            )
        }
        .onChange(of: locationManager.lastLocation) { _, _ in
            if let location = locationManager.lastLocation {
                if location.course >= 0 {
                    courseTracker.updateCourse(location.course)
                }
                updateDistance(newLocation: location)
            }
        }
        .onDisappear {
            resetTimer?.invalidate()
            resetTimer = nil
            
            if locationManager.isMonitoring {
                if let location = locationManager.lastLocation {
                    lastReadingManager.saveReading(
                        speed: locationManager.speed * 1.94384,
                        distance: totalDistance,
                        course: location.course,
                        direction: getCardinalDirection(location.course),
                        deviation: courseTracker.currentDeviation
                    )
                }
                locationManager.stopUpdatingLocation()
            }
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct PreviewCruiseInfoView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(settings.lightMode ? .white : .black)
                CruiseInfoView(
                    locationManager: locationManager
                )
                .environmentObject(settings)
            }
        }
    }
}

#Preview {
    PreviewCruiseInfoView()
        .frame(width: 180, height: 180)
}
#endif

#if DEBUG
struct PreviewCruiseDeviationView: View {
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        ZStack {
            Color(settings.lightMode ? .white : .black)
            CruiseDeviationView(deviation: -18)
                .environmentObject(settings)
        }
    }
}

#Preview("Deviation -15°") {
    PreviewCruiseDeviationView()
        .frame(width: 180, height: 50)
}
#endif
