//
//  AltSpeedInfoView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 30/01/2025.
//
// this view is created for timer

import Foundation
import SwiftUI
import CoreLocation
import WatchKit

// ADDITIONS FOR METER VIEW
class AltLastReadingManager: ObservableObject {
    @Published var speed: Double = 0
    @Published var distance: CLLocationDistance = 0
    @Published var course: Double = 0
    @Published var cardinalDirection: String = ""
    @Published var deviation: Double = 0
    @Published var tackCount: Int = 0
    @Published var topSpeed: Double = 0
    @Published var tackAngle: Double = 0
    
    // Add waypoint properties
    @Published var waypointDistance: CLLocationDistance = 0
    @Published var waypointIndex: Int = 0
    
    func saveReading(speed: Double, distance: CLLocationDistance, course: Double, direction: String, deviation: Double, tackCount: Int, topSpeed: Double, tackAngle: Double) {
        self.speed = speed
        self.distance = distance
        self.course = course
        self.cardinalDirection = direction
        self.deviation = deviation
        self.tackCount = tackCount
        self.topSpeed = topSpeed
        self.tackAngle = tackAngle
    }
    
    // Add waypoint info saving
    func saveWaypointInfo(distance: CLLocationDistance, index: Int) {
        self.waypointDistance = distance
        self.waypointIndex = index
    }
    
    func resetDistance() {
        self.distance = 0
    }
}

struct AltCruiseDeviationView: View {
    @EnvironmentObject var colorManager: ColorManager
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
        return ZStack {
            // Background circle
            Circle()
                .fill(Color.white)
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

struct CourseDeviationView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var colorManager = ColorManager()  // Add this

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
                .fill(settings.lightMode ? Color.black : Color.white)
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

struct AltSpeedInfoView: View {
    @State private var showingPlannerSheet: Bool = false
    @ObservedObject var cruisePlanState: WatchCruisePlanState
    @Binding var showingWatchFace: Bool
    @ObservedObject private var waypointDirectionManager = WaypointDirectionManager.shared

    @State private var showGPSAddedMessage = false

    @ObservedObject var locationManager: LocationManager
    // Changed from WatchTimerState to PersistentTimerManager
    @ObservedObject var watchTimerState: WatchTimerState
    @ObservedObject var persistentTimer: PersistentTimerManager
    @ObservedObject var startLineManager: StartLineManager
    @StateObject private var courseTracker = CourseTracker()
    @StateObject private var lastReadingManager = AltLastReadingManager()
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @Binding var isCheckmark: Bool
    
    @State private var isGPSEnabled = true
    @State private var showGPSOnMessage = false
    @State private var isGPSForcedOn = false
    @State private var showGPSOrangeColor = false
    @State private var showGPSOffMessage = false
    
    // STATES FOR METER VIEW
    @State private var flashingTackCount: Bool = false
    @State private var flashingTopSpeed: Bool = false
    @State private var topSpeed: Double = 0
    @State private var showingTackAngle: Bool = false

    
    @Namespace private var animation
    
    // MARK: - Helper Functions
    private func toggleGPS() {
        // Changed condition to use persistentTimer.isTimerRunning
        if persistentTimer.isTimerRunning {
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
    
    // MARK: - METER VIEW Functions and Components
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
                             Color(hex: colorManager.selectedTheme.rawValue) : (settings.lightMode ? Color.black :
                                Color.white)))
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                        .frame(minWidth: 40, minHeight: 26.5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(flashingTackCount ?
                                    Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4) :
                                    (locationManager.isMonitoring ?
                                        Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                                        Color.white.opacity(0.05)))
                        )
                }
                .buttonStyle(.plain)
                
                RulerView(numberOfSegments: 9, width: 25)
                    .offset(x:-2.8, y:-9)
                
                Rectangle()
                    .frame(width: 2, height: 5)
                    .foregroundColor(.red)
                    .offset(x: locationManager.isMonitoring ?
            max(-15, min(15, (-15 + 30 * (courseTracker.tackAngle / 120)))) :
            max(-15, min(15, (-15 + 30 * (lastReadingManager.tackAngle / 120)))),
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
                    .scaleEffect(getTopSpeedText().contains("MAX") ? CGSize(width: 1, height: 1) : CGSize(width: 1, height: 1))
                    .foregroundColor(flashingTopSpeed ?
                                     Color(hex: colorManager.selectedTheme.rawValue) :
                                        (locationManager.isMonitoring ?
                                         Color(hex: colorManager.selectedTheme.rawValue) :
                                            (settings.lightMode ? Color.black :
                                               Color.white)))
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                    .frame(minWidth: 40, minHeight: 26.5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(flashingTopSpeed ?
                                  Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4) :
                                    (locationManager.isMonitoring ?
                                     Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                                        Color.white.opacity(0.05)))
                    )
                
                RulerView(numberOfSegments: 9, width: 25)
                    .offset(x:-2.8, y:-9)
                
                Rectangle()
                    .frame(width: 2, height: 5)
                    .foregroundColor(.red)
                    .offset(x: locationManager.isMonitoring ?
                        (locationManager.speed <= 0 ? -15 :
                         topSpeed <= 0 ? -15 :
                         (-15 + (30 * min(1.94384 * locationManager.speed, topSpeed) / topSpeed))) :
                        (lastReadingManager.speed <= 0 ? -15 :
                         lastReadingManager.topSpeed <= 0 ? -15 :
                         (-15 + (30 * min(lastReadingManager.speed, lastReadingManager.topSpeed) / lastReadingManager.topSpeed))),
                        y:-9)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: locationManager.isMonitoring ? courseTracker.currentDeviation : lastReadingManager.deviation)
            }
        }
    }
    
    // MARK: - View Components
    private var speedButton: some View {
        Button(action: {
            // Only toggle GPS when timer is running
            if persistentTimer.isTimerRunning {
                toggleGPS()
            } else {
                // Show planner sheet when timer is not running
                showingPlannerSheet = true
            }
        }) {
            if !isGPSEnabled && persistentTimer.isTimerRunning {
                // GPS OFF state
                VStack(spacing: -2) {
                    Text("GPS")
                    Text("OFF")
                }
                .font(.zenithBeta(size: 14, weight: .medium))
                .scaleEffect(y:0.9)
                .foregroundColor(showGPSOrangeColor ? .orange : (settings.lightMode ? .black : .white.opacity(0.3)))
                .frame(minWidth: persistentTimer.isTimerRunning ? 55 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(showGPSOrangeColor ?
                            Color.orange.opacity(0.4) :
                            Color.white.opacity(persistentTimer.isTimerRunning ? 0.05 : 0.2))
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
                .frame(minWidth: persistentTimer.isTimerRunning ? 55 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4))
                )

            } else {
                // Speed display when timer running, or "PLAN" when not running
                HStack(spacing: 4) {
                    if persistentTimer.isTimerRunning {
                        Text(getSpeedText())
                        // Changed condition to use persistentTimer.isTimerRunning
                            .font(persistentTimer.isTimerRunning ?
                                .zenithBeta(size: 20, weight: .medium):
                                    .zenithBeta(size: 14, weight: .medium))
                        // Changed condition to use persistentTimer.isTimerRunning
                            .foregroundColor(persistentTimer.isTimerRunning ? (settings.lightMode ? .black : .white) : (settings.lightMode ? .black : .white.opacity(0.5)))

                        if locationManager.isMonitoring {
                            Image(systemName: "location.fill")
                                .font(.zenithBeta(size: 14, weight: .heavy))
                                .foregroundColor(settings.lightMode ? .blue : .blue)
                        }
                    } else {
                        /*
                        Text(getSpeedText())
                        // Changed condition to use persistentTimer.isTimerRunning
                            .font(persistentTimer.isTimerRunning ?
                                .zenithBeta(size: 20, weight: .medium):
                                    .zenithBeta(size: 14, weight: .medium))
                        // Changed condition to use persistentTimer.isTimerRunning
                            .foregroundColor(persistentTimer.isTimerRunning ? (settings.lightMode ? .black : .white) : (settings.lightMode ? .black : .white.opacity(0.5)))
                        */
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.zenithBeta(size: 16, weight: .heavy))
                                .foregroundColor(cruisePlanState.isActive ? .green : .orange)
                                .id(cruisePlanState.isActive) // Force rebuild when this changes
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
                .frame(minWidth: persistentTimer.isTimerRunning ? 55 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(persistentTimer.isTimerRunning ? Color.white.opacity(0.05) : cruisePlanState.isActive ? .green.opacity(0.2) : settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.2))
                )
            }
        }
        .buttonStyle(.plain)
        .disabled(persistentTimer.isTimerRunning && (isGPSForcedOn || !isGPSEnabled && showGPSOrangeColor))
        .animation(.easeInOut(duration: 0.2), value: showGPSOrangeColor)
        .animation(.easeInOut(duration: 0.2), value: showGPSOnMessage)
        .animation(.easeInOut(duration: 0.2), value: waypointDirectionManager.isActive) // Add this animation
        .sheet(isPresented: $showingPlannerSheet, onDismiss: {
            // Only perform the double toggle if the sheet was actually shown
            // (which only happens when timer is not running)
            if !persistentTimer.isTimerRunning {
                // Trigger double toggle of showingWatchFace
                // First toggle
                withAnimation {
                    showingWatchFace.toggle()
                }
                
                // Second toggle with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        showingWatchFace.toggle()
                    }
                    print("!! Double toggle of watchface completed")
                }
            }
        }) {
            NavigationView {
                WatchCruisePlannerView()
                    .navigationTitle("Race Plan")
            }
        }
    }
    
    // Add waypoint distance functions to AltSpeedInfoView
    private func updateWaypointInfo() {
        // Only update if GPS is on and cruise plan is active
        guard locationManager.isMonitoring,
              cruisePlanState.isActive,
              locationManager.isLocationValid,
              let currentLocation = locationManager.lastLocation else {
            return
        }
        
        let activeWaypointManager = ActiveWaypointManager.shared
        
        // Calculate and save distance to waypoint if available
        if let waypointLocation = activeWaypointManager.activeWaypointLocation,
           activeWaypointManager.activeWaypointIndex > 0 {
            let distance = currentLocation.distance(from: waypointLocation)
            
            DispatchQueue.main.async {
                self.lastReadingManager.saveWaypointInfo(
                    distance: distance,
                    index: activeWaypointManager.activeWaypointIndex
                )
            }
        }
        // If no active waypoint but we have segment start points, use the last one
        else if !activeWaypointManager.segmentStartPoints.isEmpty,
                let lastWaypoint = activeWaypointManager.segmentStartPoints.last,
                activeWaypointManager.activeWaypointIndex > 0 {
            
            let lastDistance = currentLocation.distance(from: lastWaypoint)
            
            DispatchQueue.main.async {
                self.lastReadingManager.saveWaypointInfo(
                    distance: lastDistance,
                    index: activeWaypointManager.activeWaypointIndex
                )
            }
        }
    }

    private func getWaypointDistanceText() -> String {
        // If GPS is off, use the last saved value from AltLastReadingManager
        if !locationManager.isMonitoring {
            if lastReadingManager.waypointDistance > 0 {
                return formatDistance(lastReadingManager.waypointDistance)
            }
            return "0.0"
        }
        
        // Get current location - return early if no location
        guard locationManager.isLocationValid,
              let currentLocation = locationManager.lastLocation else {
            return "0.0"
        }
        
        let activeWaypointManager = ActiveWaypointManager.shared
        
        // Get waypoint location
        if let waypointLocation = activeWaypointManager.activeWaypointLocation {
            // Calculate distance to waypoint
            let distance = currentLocation.distance(from: waypointLocation)
            return formatDistance(distance)
        }
        
        // If we get here, we have no active waypoint location
        // Check if we've completed all waypoints of an active cruise plan
        if cruisePlanState.isActive &&
           activeWaypointManager.totalSegments > 0 &&
           !activeWaypointManager.segmentStartPoints.isEmpty {
            
            if let lastWaypoint = activeWaypointManager.segmentStartPoints.last {
                let lastDistance = currentLocation.distance(from: lastWaypoint)
                return formatDistance(lastDistance)
            }
        }
        
        return "0.0"
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
    
    // Helper computed properties for distanceButton
    private var isWaypointMode: Bool {
        watchTimerState.mode == .stopwatch && cruisePlanState.isActive
    }

    private var waypointIndex: Int {
        locationManager.isMonitoring ?
            ActiveWaypointManager.shared.activeWaypointIndex :
            lastReadingManager.waypointIndex
    }

    private var distanceButtonForegroundColor: Color {
        if isWaypointMode {
            if showGPSOrangeColor { return .orange }
            if !isGPSEnabled { return settings.lightMode ? .black : .white.opacity(0.3) }
            return locationManager.isMonitoring ?
                Color(hex: colorManager.selectedTheme.rawValue) :
                (settings.lightMode ? .black : .white)
        } else {
            if isCheckmark { return Color.black }
            if showGPSOrangeColor { return .orange }
            if !isGPSEnabled { return settings.lightMode ? .black : .white.opacity(0.3) }
            return persistentTimer.isTimerRunning ?
                (settings.lightMode ? .black : .white) :
                (settings.lightMode ? .black : .white.opacity(0.3))
        }
    }

    private var distanceButtonBackground: some ShapeStyle {
        if isWaypointMode {
            if showGPSOrangeColor {
                return AnyShapeStyle(Color.orange.opacity(0.4))
            }
            return AnyShapeStyle(locationManager.isMonitoring ?
                Color(hex: colorManager.selectedTheme.rawValue).opacity(0.05) :
                (settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1)))
        } else {
            if isCheckmark {
                return AnyShapeStyle(LinearGradient(
                    colors: [Color.white, Color.white],
                    startPoint: .leading,
                    endPoint: .trailing
                ).opacity(0.5))
            }
            if showGPSOrangeColor {
                return AnyShapeStyle(LinearGradient(
                    colors: [Color.orange, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                ).opacity(0.4))
            }
            return AnyShapeStyle(LinearGradient(
                colors: [
                    startLineManager.leftButtonState == .green ? Color.green : settings.lightMode ? .black : Color.white,
                    startLineManager.rightButtonState == .green ? Color.green : settings.lightMode ? .black : Color.white
                ],
                startPoint: .leading,
                endPoint: .trailing
            ).opacity(persistentTimer.isTimerRunning ? 0.01 : settings.lightMode ? 0.05 : 0.1))
        }
    }

    // Waypoint display view
    private var waypointDisplayView: some View {
        HStack(spacing: 4) {
            
            if persistentTimer.isTimerRunning {
                Text("\(waypointIndex)")
                    .font(.zenithBeta(size: 16, weight: .medium))
                    .foregroundColor(settings.lightMode ? .white : .black)
                    .padding(.horizontal, 2)
                    .frame(height: 16)
                    .frame(minWidth: 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: colorManager.selectedTheme.rawValue))
                    )
                
                Text(getWaypointDistanceText())
                    .font(persistentTimer.isTimerRunning ?
                        .zenithBeta(size: 20, weight: .medium):
                            .zenithBeta(size: 14, weight: .medium))
            } else {
                Text("\(waypointIndex)")
                    .font(persistentTimer.isTimerRunning ?
                        .zenithBeta(size: 20, weight: .medium):
                        .zenithBeta(size: 14, weight: .medium))
            }
        }
    }

    // Original distance display view
    private var originalDistanceDisplayView: some View {
        HStack(spacing: 4) {
            if locationManager.isMonitoring {
                Image(systemName: "flag.fill")
                    .font(.zenithBeta(size: 12, weight: .heavy))
                    .foregroundColor(settings.lightMode ? .orange : .orange)
            }
            
            Text(getDistanceText())
                .font(persistentTimer.isTimerRunning ?
                    .zenithBeta(size: 20, weight: .medium):
                    .zenithBeta(size: 14, weight: .medium))
        }
    }

    // Enhanced distanceButton in AltSpeedInfoView
    private var distanceButton: some View {
        Button(action: {
            if isWaypointMode {
                WKInterfaceDevice.current().play(.click)
            } else {
                isCheckmark.toggle()
                if isCheckmark {
                    forceGPSOn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
                        if isCheckmark && !persistentTimer.isTimerRunning {
                            isCheckmark = false
                            releaseGPSForce()
                            if !isGPSEnabled {
                                locationManager.stopUpdatingLocation()
                            }
                        }
                    }
                } else {
                    releaseGPSForce()
                    if !persistentTimer.isTimerRunning {
                        locationManager.stopUpdatingLocation()
                    }
                }
            }
        }) {
            Group {
                if isWaypointMode {
                    waypointDisplayView
                } else if isCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: persistentTimer.isTimerRunning ? 20 : 14, weight: .bold))
                } else {
                    originalDistanceDisplayView
                }
            }
            .foregroundColor(distanceButtonForegroundColor)
            .padding(.horizontal, 4)
            .padding(.vertical, isCheckmark ? 5.2 : 4)
            .frame(minWidth: persistentTimer.isTimerRunning ? 55 : 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(distanceButtonBackground)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: showGPSOrangeColor)
        .animation(.easeInOut(duration: 0.2), value: watchTimerState.mode)
        .animation(.easeInOut(duration: 0.2), value: cruisePlanState.isActive)
    }
    
    
    
    private func getDistanceText() -> String {
        // Changed condition to use persistentTimer.isTimerRunning
        if !persistentTimer.isTimerRunning {
            return "DtL"
        }
        
        guard locationManager.isLocationValid else {
            return "-"
        }
        
        guard let distance = startLineManager.currentDistance else {
            return "-"
        }
        
        if distance > 99_000 {
            return "FAR"
        } else if distance >= 10_000 {
            return String(format: "%.0fk", distance / 1000)
        } else if distance >= 1_000 {
            return String(format: "%.1fk", distance / 1000)
        } else {
            return String(format: "%.1f", distance)
        }
    }
    
    private func getSpeedText() -> String {
        // Changed condition to use persistentTimer.isTimerRunning
        if !persistentTimer.isTimerRunning {
            return "kn"
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
        // Changed condition to use persistentTimer.isTimerRunning
        if !persistentTimer.isTimerRunning {
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
                // Changed condition to use persistentTimer.isTimerRunning
                .font(.system(size: persistentTimer.isTimerRunning ? 12 : 12, design: .monospaced))
                // Changed condition to use persistentTimer.isTimerRunning
                .foregroundColor(persistentTimer.isTimerRunning ? (settings.lightMode ? Color.black : Color.white) : Color.white.opacity(0.3))
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                // Changed condition to use persistentTimer.isTimerRunning
                .frame(minWidth: persistentTimer.isTimerRunning ? 55 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        // Changed condition to use persistentTimer.isTimerRunning
                        .fill(courseTracker.isLocked ? Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3) : Color.white.opacity(persistentTimer.isTimerRunning ? 0.05 : 0.1))
                )
            
//            if courseTracker.isLocked {
                CourseDeviationView(deviation: courseTracker.currentDeviation)
                    .frame(width: 100)
                    .transition(.opacity)
//            }
        }
        // Changed condition to use persistentTimer.isTimerRunning
        .opacity(persistentTimer.isTimerRunning ? 1 : 0)
    }
    
    private var speedDisplay: some View {
        Text(getSpeedText())
            // Changed condition to use persistentTimer.isTimerRunning
            .font(persistentTimer.isTimerRunning ?
                .zenithBeta(size: 20, weight: .medium):
                    .zenithBeta(size: 14, weight: .medium))
            // Changed condition to use persistentTimer.isTimerRunning
            .foregroundColor(persistentTimer.isTimerRunning ? (settings.lightMode ? Color.black : Color.white) : (settings.lightMode ? Color.orange.opacity(1) : Color.white.opacity(0.5)))
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            // Changed condition to use persistentTimer.isTimerRunning
            .frame(minWidth: persistentTimer.isTimerRunning ? 55 : 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    // Changed condition to use persistentTimer.isTimerRunning
                    .fill(Color.white.opacity(persistentTimer.isTimerRunning ? 0.05 : 0.1))
            )
            .matchedGeometryEffect(id: "speed", in: animation)
    }
    
    private func handleLocationState() {
        // Changed condition to use persistentTimer.isTimerRunning
        if !persistentTimer.isTimerRunning {
            locationManager.stopUpdatingLocation()
            courseTracker.resetLock()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    var body: some View {
        ZStack {
            // Original VStack content
            VStack {
                HStack(alignment: .center, spacing: persistentTimer.isTimerRunning ? 10 : (WKInterfaceDevice.current().screenBounds.height < 224 ? 60 : 70)) {
                    distanceButton
                        .offset(x: persistentTimer.isTimerRunning ? 0 : -5, y: persistentTimer.isTimerRunning ? 0 : -20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: persistentTimer.isTimerRunning)
                    
                    speedButton
                        .offset(x: persistentTimer.isTimerRunning ? 0 : 5, y: persistentTimer.isTimerRunning ? 0 : -20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: persistentTimer.isTimerRunning)
                }
                
                if !isGPSEnabled || showGPSOnMessage {
                    Spacer().frame(height:5)
                }
                
                // Changed condition to use persistentTimer.isTimerRunning
                if persistentTimer.isTimerRunning {
                    courseDisplay
                        .offset(y: 45)
                        .animation(.spring(dampingFraction: 0.8), value: persistentTimer.isTimerRunning)
                }
            }
            
            // Add meterView with animation
            meterView
                .offset(y: -51)
                // Changed condition to use persistentTimer.isTimerRunning
                .opacity(persistentTimer.isTimerRunning ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: persistentTimer.isTimerRunning)
            
            if settings.gpsDebug {
                if showGPSAddedMessage {
                    Text("GPS point added")
                        .font(.zenithBeta(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.3))
                        )
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            
        }
        .padding(.horizontal)
        .onAppear {
            handleLocationState()
        }
        // Changed observer to persistentTimer.isTimerRunning
        .onChange(of: persistentTimer.isTimerRunning) { _, _ in
            handleLocationState()
        }
        .onChange(of: locationManager.speed) { _, speed in
            let speedInKnots = speed * 1.94384
            
            // Update top speed
            if speedInKnots > topSpeed {
                topSpeed = speedInKnots
                flashingTopSpeed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    flashingTopSpeed = false
                }
            }
            
            if settings.gpsDebug {
                withAnimation {
                    showGPSAddedMessage = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showGPSAddedMessage = false
                    }
                }
            }
            
            // Changed condition to use persistentTimer.isTimerRunning
//            if persistentTimer.isTimerRunning && isGPSEnabled {
                JournalManager.shared.addDataPoint(
                    heartRate: nil,
                    speed: speedInKnots,
                    location: locationManager.lastLocation
                )
//            }
            
            // Add data to cruise session if monitoring
//            if locationManager.isMonitoring {
                SessionManager.shared.addDataPointToSession(
                    heartRate: nil,
                    speed: speedInKnots,
                    location: locationManager.lastLocation
                )
//            }
            // Record GPS data through WatchTimerState
            watchTimerState.recordGPSDataPoint(
                heartRate: nil,
                speed: speedInKnots,
                location: locationManager.lastLocation
            )
            print("!Passing GPS data to watchtimerstate")
            
        }
        .onChange(of: locationManager.lastLocation) { _, _ in
            if persistentTimer.isTimerRunning && isGPSEnabled,
               let location = locationManager.lastLocation {
                startLineManager.updateDistance(currentLocation: location)
                if location.course >= 0 {
                    courseTracker.updateCourse(location.course)
                }
                
                // Add waypoint info update for stopwatch with cruise plan
                if watchTimerState.mode == .stopwatch && cruisePlanState.isActive {
                    DispatchQueue.main.async {
                        self.updateWaypointInfo()
                    }
                }
            }
        }
        // Update onDisappear to save waypoint info
        .onDisappear {
            if persistentTimer.isTimerRunning && !isCheckmark {
                locationManager.stopUpdatingLocation()
            }
            
            // Save last readings including waypoint info
            if locationManager.isMonitoring, let location = locationManager.lastLocation {
                lastReadingManager.saveReading(
                    speed: locationManager.speed * 1.94384,
                    distance: 0, // No distance tracking in AltSpeedInfoView
                    course: location.course,
                    direction: getCardinalDirection(location.course),
                    deviation: courseTracker.currentDeviation,
                    tackCount: courseTracker.tackCount,
                    topSpeed: topSpeed,
                    tackAngle: courseTracker.tackAngle
                )
                
                // Update waypoint info one last time if in stopwatch with cruise plan
                if watchTimerState.mode == .stopwatch && cruisePlanState.isActive {
                    DispatchQueue.main.async {
                        self.updateWaypointInfo()
                    }
                }
            }
        }
    }
}

/*
// MARK: - Preview Helpers
#if DEBUG
struct PreviewAltSpeedInfoView: View {
    @StateObject private var locationManager = LocationManager()
    // Changed to use PersistentTimerManager
    @StateObject private var persistentTimer = PersistentTimerManager()
    @StateObject private var startLineManager = StartLineManager()
    @StateObject private var settings = AppSettings()
    @State private var isCheckmark = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                AltSpeedInfoView(
                    locationManager: locationManager,
                    // Changed to use persistentTimer
                    persistentTimer: persistentTimer,
                    startLineManager: startLineManager,
                    isCheckmark: $isCheckmark
                )
                .environmentObject(settings)
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
*/
