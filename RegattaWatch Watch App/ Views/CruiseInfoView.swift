//
//  CruiseInfoView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 07/02/2025.
//
// this view is created for CruiseR

import Foundation
import SwiftUI
import CoreLocation
import WatchKit

struct CruiseDeviationView: View {
    @StateObject private var colorManager = ColorManager()  // Add this
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
                .fill(Color(hex: colorManager.selectedTheme.rawValue))
                .opacity(1)
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
    @State private var flashingTackCount: Bool = false
    @State private var flashingTopSpeed: Bool = false
    @State private var topSpeed: Double = 0
    @State private var showingTackAngle: Bool = false

    @State private var totalDistance: CLLocationDistance = 0
    @State private var lastLocation: CLLocation?
    @EnvironmentObject var cruisePlanState: WatchCruisePlanState

    @Namespace private var animation
    
    private func formatTackCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.0fk", Double(count) / 1000)
        }
        return "\(count)"
    }
    
    private func getTackText() -> String {
        if showingTackAngle {
            // Show tack angle
            if !locationManager.isMonitoring {
                let lastTackAngle = lastReadingManager.tackAngle
                if lastTackAngle == 0 {
                    return "TACK"
                }
                return String(format: "%.0f°", lastTackAngle)
            }
            
            let currentTackAngle = courseTracker.tackAngle
            if currentTackAngle == 0 {
                return "TACK"
            }
            return String(format: "%.0f°", currentTackAngle)
        } else {
            // Original tack count display logic
            if !locationManager.isMonitoring {
                let lastTackCount = lastReadingManager.tackCount
                if lastTackCount == 0 {
                    return "TACK"
                }
                if lastTackCount >= 1000 {
                    return String(format: "%.0fk", Double(lastTackCount) / 1000)
                }
                return String(format: "%d", lastTackCount)
            }
            
            let currentTackCount = courseTracker.tackCount
            if currentTackCount == 0 {
                return "TACK"
            }
            if currentTackCount >= 1000 {
                return String(format: "%.0fk", Double(currentTackCount) / 1000)
            }
            return String(format: "%d", currentTackCount)
        }
    }

    private func getTopSpeedText() -> String {
        if !locationManager.isMonitoring {
            let lastTopSpeed = lastReadingManager.topSpeed
            if lastTopSpeed == 0 {
                return "MAX"
            }
            return String(format: "%.1f", lastTopSpeed)
        }
        
        if topSpeed == 0 {
            return "MAX"
        }
        return String(format: "%.1f", topSpeed)
    }

    private var meterView: some View {
        HStack(alignment: .center, spacing: 80) {
            // Tack Count Display
            ZStack {
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    withAnimation {
                        showingTackAngle.toggle()
                    }
                }) {
                    Text(getTackText())
                        .font(getTackText().contains("TACK") ? .zenithBeta(size: 12, weight: .medium) : .zenithBeta(size: 13, weight: .medium))
                        .multilineTextAlignment(.center)
                        .offset(y:2)
                        .lineSpacing(-2)
                        .scaleEffect(getTackText().contains("TACK") ? CGSize(width: 1, height: 1) : CGSize(width: 1, height: 1))
                        .foregroundColor(flashingTackCount ?
                            Color(hex: colorManager.selectedTheme.rawValue) :
                            (locationManager.isMonitoring ?
                                Color(hex: colorManager.selectedTheme.rawValue) :
                                (settings.lightMode ? .black : .white)))
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                        .frame(minWidth: 40, minHeight: 26.5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(flashingTackCount ?
                                    Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4) :
                                    (locationManager.isMonitoring ?
                                        Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                                        (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1))))
                        )
                }
                .buttonStyle(.plain)
                
                Rectangle()
                    .frame(width: 10, height: 5)
                    .foregroundColor(.red.opacity(settings.lightMode ? 0.3 : 0.5))
                    .offset(x: 11, y: -9)
                
                RulerView(numberOfSegments: 9, width: 25)
                    .offset(x:-2.8, y:-9)
                
                Rectangle()
                    .frame(width: 2, height: 5)
                    .foregroundColor(.red)
                    .offset(x: locationManager.isMonitoring ?
            max(-15, min(15, (-15 + 30 * (courseTracker.tackAngle / 180)))) :
            max(-15, min(15, (-15 + 30 * (lastReadingManager.tackAngle / 180)))),
            y: -9)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: locationManager.isMonitoring ? courseTracker.currentDeviation : lastReadingManager.deviation)
            }

            // Top Speed Display
            ZStack {
                Text(getTopSpeedText())
                    .font(getTopSpeedText().contains("MAX") ? .zenithBeta(size: 12, weight: .medium) : .zenithBeta(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .offset(y:2)
                    .lineSpacing(-2)
                    .scaleEffect(getTackText().contains("MAX") ? CGSize(width: 1, height: 1) : CGSize(width: 1, height: 1))
                    .foregroundColor(flashingTopSpeed ?
                                     Color(hex: colorManager.selectedTheme.rawValue) :
                                        (locationManager.isMonitoring ?
                                         Color(hex: colorManager.selectedTheme.rawValue) :
                                            (settings.lightMode ? .black : .white)))
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                    .frame(minWidth: 40, minHeight: 26.5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(flashingTopSpeed ?
                                  Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4) :
                                    (locationManager.isMonitoring ?
                                     Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                                        (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1))))
                    )
                
                let topSpeed = locationManager.isMonitoring ? topSpeed : lastReadingManager.topSpeed
                let maxSpeed = settings.maxBoatSpeed
                let isMaxGreaterThanTop = maxSpeed > topSpeed

                // Calculate X based on the condition
                let x = isMaxGreaterThanTop ?
                    (topSpeed / maxSpeed) :
                    ((topSpeed - maxSpeed) / topSpeed)

                // Calculate width and offset
                let width = 30 * x
                let xOffset = isMaxGreaterThanTop ?
                    (-15 + (width / 2)) :
                    (15 - (width / 2))

                Rectangle()
                    .frame(width: width, height: 5)
                    .foregroundColor(isMaxGreaterThanTop ?
                        Color(hex: colorManager.selectedTheme.rawValue) :
                        .red)
                    .opacity(settings.lightMode ? 0.3 : 0.5)
                    .offset(x: xOffset, y: -9)
                
                RulerView(numberOfSegments: 9, width: 25)
                    .offset(x:-2.8, y:-9)
                
                Rectangle()
                    .frame(width: 2, height: 5)
                    .foregroundColor(.red)
                    .offset(x: locationManager.isMonitoring ?
                            (locationManager.speed <= 0 ? -15 :
                             (topSpeed <= 0 ? -15 :
                              (-15 + (30 * min(1.94384 * locationManager.speed,
                                               max(topSpeed, settings.maxBoatSpeed)) /
                                      (topSpeed < settings.maxBoatSpeed ? settings.maxBoatSpeed : topSpeed))))) :
                            (lastReadingManager.speed <= 0 ? -15 :
                             (lastReadingManager.topSpeed <= 0 ? -15 :
                              (-15 + (30 * min(lastReadingManager.speed,
                                               max(lastReadingManager.topSpeed, settings.maxBoatSpeed)) /
                                      (lastReadingManager.topSpeed < settings.maxBoatSpeed ? settings.maxBoatSpeed : lastReadingManager.topSpeed))))),
                            y:-9)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: locationManager.isMonitoring ? courseTracker.currentDeviation : lastReadingManager.deviation)

            }
                
        }
    }
    

    
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
                return "0.0"
            }
            
            if lastDistance > 200_000 {  // Over 200km
                return "FAR"
            } else if lastDistance >= 10_000 {  // 10km to 200km
                return String(format: "%.0fk", lastDistance / 1000)
            } else if lastDistance >= 1_000 {  // 1km to 9.9km
                return String(format: "%.1fk", lastDistance / 1000)
            } else {
                return String(format: "%.0f", lastDistance)
            }
        }
        
        if totalDistance == 0 {
            return "0.0"
        }
        
        if totalDistance > 200_000 {  // Over 200km
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
    
    // New function to calculate and format the distance to active waypoint
    private func getWaypointDistanceText() -> String {
        let activeWaypointManager = ActiveWaypointManager.shared
        
        // Get current location
        guard let currentLocation = locationManager.isMonitoring ?
                                    locationManager.lastLocation :
                                    lastLocation else {
            return "0.0"
        }
        
        // Get waypoint location
        guard let waypointLocation = activeWaypointManager.activeWaypointLocation else {
            // If no active waypoint but cruise plan is active, check if we've completed all waypoints
            if cruisePlanState.isActive && activeWaypointManager.totalSegments > 0 {
                // All waypoints completed - try to get distance to last waypoint
                if activeWaypointManager.segmentStartPoints.count > 0,
                   let lastWaypoint = activeWaypointManager.segmentStartPoints.last {
                    let lastDistance = currentLocation.distance(from: lastWaypoint)
                    return formatDistance(lastDistance)
                }
            }
            return "0.0"
        }
        
        // Calculate distance to waypoint
        let distance = currentLocation.distance(from: waypointLocation)
        return formatDistance(distance)
    }

    // Helper function to format distance consistently
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance == 0 {
            return "0.0"
        }
        
        if distance > 200_000 {  // Over 200km
            return "FAR"
        } else if distance >= 10_000 {  // 10km to 200km
            return String(format: "%.0fk", distance / 1000)
        } else if distance >= 1_000 {  // 1km to 9.9km
            return String(format: "%.1fk", distance / 1000)
        } else {
            return String(format: "%.0f", distance)
        }
    }
    
    private func resetTracking() {
        // Reset with current GPS monitoring state
        lastReadingManager.resetDistance(isMonitoring: locationManager.isMonitoring)
        
        // Original reset code
        totalDistance = 0
        lastLocation = nil
        topSpeed = 0
        courseTracker.resetTackCount()
    }
    
    private func getSpeedText() -> String {
        if !locationManager.isMonitoring {
            let lastSpeed = lastReadingManager.speed
            return lastSpeed <= 0 ? "0.0" : String(format: "%.1f", lastSpeed)
        }
        
        let speedInKnots = locationManager.speed * 1.94384
        return speedInKnots <= 0 ? "0.0" : String(format: "%.1f", speedInKnots)
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
                    HStack(spacing: 4) {
                        // Waypoint index indicator (only shown when cruise plan is active)
                        if cruisePlanState.isActive {
                            Text("\(ActiveWaypointManager.shared.activeWaypointIndex)")
                                .font(.zenithBeta(size: 16, weight: .medium))
                                .foregroundColor(settings.lightMode ? .white : .black)
                                .padding(.horizontal, 2)
                                .frame(height: 16)
                                .frame(minWidth: 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: colorManager.selectedTheme.rawValue))
                                )
                        }
                        
                        // Main distance text
                        Text(cruisePlanState.isActive ? getWaypointDistanceText() : getDistanceText())
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
                                    (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1)))
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
                        .fill(courseTracker.isLocked ? Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3) : settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
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
            // Inside the speedDisplay button action, where GPS is turned OFF:
            if locationManager.isMonitoring {
                // Save current readings before stopping
                if let location = locationManager.lastLocation {
                    lastReadingManager.saveReading(
                        speed: locationManager.speed * 1.94384,
                        distance: totalDistance,
                        course: location.course,
                        direction: getCardinalDirection(location.course),
                        deviation: courseTracker.currentDeviation,
                        tackCount: courseTracker.tackCount,
                        topSpeed: topSpeed,
                        tackAngle: courseTracker.tackAngle
                    )
                }
                
                // End cruise session when GPS is turned off
                lastReadingManager.endCruiseSession()
                
                locationManager.stopUpdatingLocation()
                showGPSOffMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showGPSOffMessage = false
                }
            } else {
                locationManager.startUpdatingLocation()
                
                // Notify LastReadingManager of GPS status change
                lastReadingManager.handleGPSStatusChange(isMonitoring: true)
                
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
                HStack(spacing: 4) {
                    Text(getSpeedText())
                        .font(.zenithBeta(size: 20, weight: .medium))
                        .foregroundColor(locationManager.isMonitoring ?
                                         Color(hex: colorManager.selectedTheme.rawValue) :
                                            (settings.lightMode ? .black : .white))

                    
                    Image(systemName: locationManager.isMonitoring ? "pause" : "play.fill")                        .font(.zenithBeta(size: 12, weight: .medium))
                        .foregroundColor(settings.lightMode ? .white : .black)
                        .padding(.horizontal, 2)
                        .frame(height: 16)
                        .frame(minWidth: 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: colorManager.selectedTheme.rawValue))
                        )
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .frame(minWidth: 55)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(locationManager.isMonitoring ?
                              Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                                (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1)))
                )
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: showGPSOffMessage)
        .animation(.easeInOut(duration: 0.2), value: showGPSOnMessage)
        .matchedGeometryEffect(id: "speed", in: animation)
    }
    
    var body: some View {
        
        ZStack {
            
            meterView
                .offset(y: -51)
            
            VStack {
                
                HStack(alignment: .center, spacing: 10) {
                    distanceButton
                    speedDisplay
                }
                
                if showGPSOffMessage || showGPSOnMessage {
                    Spacer().frame(height: 5)
                }
                
                courseDisplay
                    .offset(y: 40)
            }
        }
        .padding(.horizontal)
        .onChange(of: locationManager.speed) { _, speed in
            let speedInKnots = speed * 1.94384
            // Update top speed if accuracy is good enough
            if locationManager.lastLocation?.horizontalAccuracy ?? 100 <= 10.0 {
                if speedInKnots > topSpeed {
                    topSpeed = speedInKnots
                    flashingTopSpeed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        flashingTopSpeed = false
                    }
                }
            }
            
            JournalManager.shared.addDataPoint(
                heartRate: nil,
                speed: speedInKnots,
                location: locationManager.lastLocation
            )
        }
        .onChange(of: locationManager.lastLocation) { _, _ in
            if let location = locationManager.lastLocation {
                if location.course >= 0 {
                    courseTracker.updateCourse(location.course)
                }
                updateDistance(newLocation: location)
                
                // Add data to cruise session if monitoring
                if locationManager.isMonitoring {
                    let speedInKnots = locationManager.speed * 1.94384
                    lastReadingManager.addLocationToSession(
                        speed: speedInKnots,
                        location: location
                    )
                }
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
                        deviation: courseTracker.currentDeviation,
                        tackCount: courseTracker.tackCount,
                        topSpeed: topSpeed,
                        tackAngle: courseTracker.tackAngle
                    )
                }
                
                // End cruise session when view disappears with GPS on
                lastReadingManager.endCruiseSession()
                
                locationManager.stopUpdatingLocation()
            }
        }
    }
}

#if DEBUG
struct PreviewCruiseInfoView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var settings = AppSettings()
    @StateObject private var colorManager = ColorManager()
    
    init() {
        // Set up some preview values
        let previewSettings = AppSettings()
        previewSettings.maxBoatSpeed = 35.0  // Set a preview value for maxBoatSpeed
        previewSettings.teamName = "ULTRA"
        previewSettings.showRaceInfo = true
        
        // Use these preview settings
        _settings = StateObject(wrappedValue: previewSettings)
        
        // Set up some preview location data
        let previewLocationManager = LocationManager()
        // You could set some mock values here if needed
        _locationManager = StateObject(wrappedValue: previewLocationManager)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(settings.lightMode ? .white : .black)
                CruiseInfoView(
                    locationManager: locationManager
                )
                .environmentObject(settings)
                .environmentObject(colorManager)
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
