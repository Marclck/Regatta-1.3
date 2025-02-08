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
    @ObservedObject var locationManager: LocationManager
    @StateObject private var courseTracker = CourseTracker()
    
    // State variables for distance tracking
    @State private var isTracking = true
    @State private var totalDistance: CLLocationDistance = 0
    @State private var lastLocation: CLLocation?
    
    @Namespace private var animation
    
    private func getDistanceText() -> String {
        if !isTracking {
            return ""  // Empty string since we'll use Image instead
        }
        
        if totalDistance == 0 {
            return "-"
        }
        
        let distance = totalDistance
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
    
    private func updateDistance(newLocation: CLLocation) {
        guard isTracking else { return }
        
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
        isTracking = true
    }
    
    private func getSpeedText() -> String {
        let speedInKnots = locationManager.speed * 1.94384
        return speedInKnots <= 0 ? "-" : String(format: "%.1f", speedInKnots)
    }
    
    private func getCardinalDirection(_ degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int(round(degrees.truncatingRemainder(dividingBy: 360) / 45)) % 8
        return directions[index]
    }
    
    private func getCourseText() -> String {
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
            if isTracking {
                isTracking = false
            } else {
                resetTracking()
            }
        }) {
            Group {
                if !isTracking {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24, weight: .heavy))
                        .symbolVariant(.fill)
                        .foregroundColor(.orange)
                } else {
                    Text(getDistanceText())
                        .font(.zenithBeta(size: 24, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 55)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.05))
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
        Text(getSpeedText())
            .font(.zenithBeta(size: 24, weight: .medium))
            .foregroundColor(settings.lightMode ? .black : .white)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 55)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.05))
            )
            .matchedGeometryEffect(id: "speed", in: animation)
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                distanceButton
                    .offset(y: 0)
                speedDisplay
                    .offset(y: 0)
            }
            
            courseDisplay
                .offset(y: 40)
        }
        .padding(.horizontal)
        .onAppear {
            locationManager.startUpdatingLocation()
            resetTracking()
        }
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
            locationManager.stopUpdatingLocation()
            isTracking = false
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
