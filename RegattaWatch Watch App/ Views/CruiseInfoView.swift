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
                    .fill(settings.lightMode ? Color.black : Color.white)
                    .opacity(getCircleFill(index, isPositive: false))
                    .frame(width: 10, height: 10)
            }
            
            // Course display spacer
            Spacer()
                .frame(width: 55)
            
            // Positive deviation indicators
            ForEach(0..<stepsPerSide, id: \.self) { index in
                Circle()
                    .fill(settings.lightMode ? Color.black : Color.white)
                    .opacity(getCircleFill(index, isPositive: true))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

struct CruiseInfoView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    @ObservedObject var locationManager: LocationManager
    @StateObject private var courseTracker = CourseTracker()
    @StateObject private var lastReadingManager = LastReadingManager()
    @State private var isConfirmingReset: Bool = false

    @State private var totalDistance: CLLocationDistance = 0
    @State private var lastLocation: CLLocation?
    
    @Namespace private var animation
    
    private func getDistanceText() -> String {
        if !locationManager.isMonitoring {
            let lastDistance = lastReadingManager.distance
            if lastDistance == 0 {
                return "-"
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
            return lastSpeed <= 0 ? "-" : String(format: "%.1f", lastSpeed)
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
                // Check if we have default values indicating no stored reading
                if lastReadingManager.course == 0 && lastReadingManager.cardinalDirection == "N" {
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
            } else {
                isConfirmingReset = true
                // Add haptic feedback
//                WKInterfaceDevice.current().play(.notification)
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
                        .foregroundColor(locationManager.isMonitoring ?
                                         Color(hex: colorManager.selectedTheme.rawValue) : (settings.lightMode ? .black : .white))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 55)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isConfirmingReset ?
                          Color.orange.opacity(0.2) :
                          (locationManager.isMonitoring ?
                           Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                           (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.05))))
            )
        }
        .buttonStyle(.plain)
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
                        .fill(settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.05))
                )
            
            CruiseDeviationView(deviation: courseTracker.currentDeviation)
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
                        direction: getCardinalDirection(location.course)
                    )
                }
                locationManager.stopUpdatingLocation()
            } else {
                locationManager.startUpdatingLocation()
            }
        }) {
            Text(getSpeedText())
                .font(.zenithBeta(size: 20, weight: .medium))
                .foregroundColor(locationManager.isMonitoring ?
                                 Color(hex: colorManager.selectedTheme.rawValue) : (settings.lightMode ? .black : .white))
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
        .buttonStyle(.plain)
        .matchedGeometryEffect(id: "speed", in: animation)
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                distanceButton
                speedDisplay
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
            if locationManager.isMonitoring {
                if let location = locationManager.lastLocation {
                    lastReadingManager.saveReading(
                        speed: locationManager.speed * 1.94384,
                        distance: totalDistance,
                        course: location.course,
                        direction: getCardinalDirection(location.course)
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
