//
//  WeatherViews.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 08/02/2025.
//

import Foundation
import SwiftUI
import WeatherKit
import CoreLocation
import CoreMotion

// MARK: - Weather Manager
class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var windSpeed: Double = 0
    @Published var windDirection: Double = 0
    @Published var cardinalDirection: String = "N"
    @Published var currentTemp: Double = 0
    @Published var lowTemp: Double = 0
    @Published var highTemp: Double = 0
    @Published var condition: String = "sun.max.fill" // Default icon
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var nauticalSunrise: Date?
    @Published var nauticalSunset: Date?
    @Published var moonPhase: MoonPhase = .new


    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    
    private weak var lastReadingManager: LastReadingManager?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000 // Update every 1km
        setupLocation()
    }
    
    func setLastReadingManager(_ manager: LastReadingManager) {
        self.lastReadingManager = manager
    }
    
    private func setupLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateWeather(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        self.error = "Location error: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            error = "Location access denied"
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func updateWeather(for location: CLLocation) {
        isLoading = true
        
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Existing weather updates
                    self.windSpeed = weather.currentWeather.wind.speed.converted(to: .knots).value
                    self.windDirection = weather.currentWeather.wind.direction.value
                    self.updateCardinalDirection(self.windDirection)
                    
                    self.currentTemp = weather.currentWeather.temperature.converted(to: .celsius).value
                    self.lowTemp = weather.dailyForecast[0].lowTemperature.converted(to: .celsius).value
                    self.highTemp = weather.dailyForecast[0].highTemperature.converted(to: .celsius).value
                    
                    // Set condition icon based on weather condition and daylight
                    let isDaylight = weather.currentWeather.isDaylight
                    self.condition = self.getConditionIcon(weather.currentWeather.condition, daylight: isDaylight)
                    
                    // Add sun/moon data
                    let dayWeather = weather.dailyForecast[0]
                    self.nauticalSunrise = dayWeather.sun.nauticalDawn
                    self.nauticalSunset = dayWeather.sun.nauticalDusk
                    self.moonPhase = dayWeather.moon.phase
                    
                    // NEW CODE: Update LastReadingManager with weather data if available
                    if let lastReadingManager = self.lastReadingManager {
                        lastReadingManager.updateWeatherData(
                            windSpeed: self.windSpeed,
                            windDirection: self.windDirection,
                            windCardinalDirection: self.cardinalDirection,
                            temperature: self.currentTemp,
                            condition: self.condition
                        )
                        
                        // We don't want to overwrite existing speed, distance, etc.
                        // So we get current values first
                        let currentSpeed = lastReadingManager.speed
                        let currentDistance = lastReadingManager.distance
                        let currentTackCount = lastReadingManager.tackCount
                        let currentTopSpeed = lastReadingManager.topSpeed
                        let currentTackAngle = lastReadingManager.tackAngle
                        
                        // Save with updated weather data (wind direction becomes course)
                        lastReadingManager.saveReading(
                            speed: currentSpeed,
                            distance: currentDistance,
                            course: self.windDirection,
                            direction: self.cardinalDirection,
                            deviation: 0, // No deviation data from weather
                            tackCount: currentTackCount,
                            topSpeed: currentTopSpeed,
                            tackAngle: currentTackAngle
                        )
                        
                        print("🌤️ WeatherManager updating LastReadingManager: windSpeed=\(self.windSpeed), windDirection=\(self.windDirection), temp=\(self.currentTemp)")
                    }
                    
                    self.isLoading = false
                    self.error = nil
                    self.scheduleNextUpdate()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.error = "Weather error: \(error.localizedDescription)"
                    self?.isLoading = false
                }
                print("Error fetching weather: \(error)")
            }
        }
    }
    
    private func getConditionIcon(_ condition: WeatherCondition, daylight: Bool = true) -> String {
        switch condition {
        case .clear:
            return daylight ? "sun.max.fill" : "moon.stars.fill"
        case .cloudy, .mostlyCloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return daylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .rain:
            return "cloud.rain.fill"
        default:
            return daylight ? "sun.max.fill" : "moon.stars.fill"
        }
    }
    
    
    private func scheduleNextUpdate() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { [weak self] _ in
            guard let self = self,
                  let location = self.locationManager.location else { return }
            self.updateWeather(for: location)
        }
    }
    
    private func updateCardinalDirection(_ degrees: Double) {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int(round(degrees.truncatingRemainder(dividingBy: 360) / 45)) % 8
        cardinalDirection = directions[index]
    }
    
    deinit {
        timer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
}
// MARK: - Pressure Manager
class PressureManager: ObservableObject {
    @Published var currentPressure: Double = 0
    @Published var pressureTrend: PressureTrend = .stable
    @Published var isAvailable: Bool = false
    
    private var historicalReadings: [(pressure: Double, timestamp: Date)] = []
    private var altimeter = CMAltimeter()
    private var timer: Timer?
    private let maxReadings = 6  // Keep last 6 readings (1 hour of data)
    private let trendThreshold = 1.0  // 1 hPa threshold for trend
    private let updateInterval: TimeInterval = 600  // 10 minutes
    
    enum PressureTrend {
        case rising, falling, stable
    }
    
    init() {
        setupAltimeter()
    }
    
    private func setupAltimeter() {
        isAvailable = CMAltimeter.isRelativeAltitudeAvailable()
        
        if isAvailable {
            startUpdates()
        }
    }
    
    func startUpdates() {
        guard isAvailable else { return }
        
        // Schedule regular updates
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.requestPressureUpdate()
        }
        
        // Request initial update immediately
        requestPressureUpdate()
    }
    
    private func requestPressureUpdate() {
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self = self,
                  let data = data else {
                if let error = error {
                    print("Pressure update error: \(error.localizedDescription)")
                }
                return
            }
            
            // Convert kPa to hPa (multiply by 10)
            let pressureHPa = data.pressure.doubleValue * 10
            
            // Add new reading
            let now = Date()
            self.addReading(pressure: pressureHPa, timestamp: now)
            
            // Stop updates until next scheduled time
            self.altimeter.stopRelativeAltitudeUpdates()
        }
    }
    
    private func addReading(pressure: Double, timestamp: Date) {
        // Remove readings older than 1 hour
        historicalReadings = historicalReadings.filter {
            timestamp.timeIntervalSince($0.timestamp) <= 3600
        }
        
        // Add new reading
        historicalReadings.append((pressure: pressure, timestamp: timestamp))
        
        // Keep only last 6 readings
        if historicalReadings.count > maxReadings {
            historicalReadings.removeFirst()
        }
        
        // Update current pressure and trend
        currentPressure = pressure
        updateTrend()
    }
    
    private func updateTrend() {
        guard let oldestReading = historicalReadings.first else {
            pressureTrend = .stable
            return
        }
        
        // Check if there's a gap longer than update interval + 1 minute tolerance
        let maxGap = updateInterval + 60
        if Date().timeIntervalSince(oldestReading.timestamp) > maxGap {
            // Clear history if there's a significant gap
            historicalReadings.removeAll()
            historicalReadings.append((pressure: currentPressure, timestamp: Date()))
            pressureTrend = .stable
            return
        }
        
        let change = currentPressure - oldestReading.pressure
        if abs(change) <= trendThreshold {
            pressureTrend = .stable
        } else {
            pressureTrend = change > 0 ? .rising : .falling
        }
    }
    
    deinit {
        timer?.invalidate()
        altimeter.stopRelativeAltitudeUpdates()
    }
}

// MARK: - Compass Manager
class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    @Published var cardinalDirection: String = "N"
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        setupCompass()
    }
    
    func setupCompass() {
        // Request location authorization as it's required for heading updates
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 1  // Update if heading changes by 1 degree
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.magneticHeading
        self.heading = heading
        updateCardinalDirection(heading)
    }
    
    private func updateCardinalDirection(_ heading: Double) {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int(round(heading.truncatingRemainder(dividingBy: 360) / 45)) % 8
        cardinalDirection = directions[index]
    }
    
    func startUpdates() {
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdates() {
        locationManager.stopUpdatingHeading()
    }
    
    deinit {
        locationManager.stopUpdatingHeading()
    }
}

// MARK: - Wind Speed View
struct WindSpeedView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var compassManager = CompassManager()
    @ObservedObject var courseTracker: CourseTracker  // Use existing CourseTracker
    @ObservedObject var lastReadingManager: LastReadingManager  // Use existing LastReadingManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var showingTWA: Bool = false
    
    private func getWindPosition(windDirection: Double, deviceHeading: Double) -> CGPoint {
        let angleInDegrees = 270 - deviceHeading + windDirection
        let angle = angleInDegrees * .pi / 180
        
        let x = 20 * cos(angle)
        let y = 20 * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateTWA() -> Double {
        // Use current locked course if available, otherwise use last reading
        let courseDegrees = courseTracker.isLocked ?
            (courseTracker.lockedCourse ?? lastReadingManager.course) :
            lastReadingManager.course
            
        // Calculate the absolute angle between course and wind direction
        let diff = abs(angleDifference(courseDegrees, weatherManager.windDirection))
        // Normalize to 0-180 range
        return min(diff, 360 - diff)
    }
    
    private func angleDifference(_ angle1: Double, _ angle2: Double) -> Double {
        let diff = (angle1 - angle2).truncatingRemainder(dividingBy: 360)
        if diff > 180 {
            return diff - 360
        } else if diff < -180 {
            return diff + 360
        }
        return diff
    }
    
    var body: some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            withAnimation(.easeInOut(duration: 0.2)) {
                showingTWA.toggle()
            }
        }) {
            ZStack {
                if !showingTWA {
                    Circle()
                        .fill(settings.lightMode ? Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3) : Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3))
                        .frame(width: 50, height: 50)
                } else {
                    Circle()
                        .fill(settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                }
                
                if !isLuminanceReduced {
                    // Wind direction indicator
                    let position = getWindPosition(windDirection: weatherManager.windDirection,
                                                deviceHeading: compassManager.heading)
                    
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(x: position.x, y: position.y)
                        .animation(.linear(duration: 0.1), value: weatherManager.windDirection)
                        .animation(.linear(duration: 0.1), value: compassManager.heading)
                }
                
                if showingTWA {
                    // TWA Display
                    VStack(spacing: 0) {
                        Image(systemName: "sailboat.fill")
                            .font(.system(size: 8, weight: .heavy))
                            .symbolVariant(.fill)
                            .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.5))
                            .offset(y: 1)
                            .scaleEffect(x: 0.8, y:0.8)
                        
                        Text(String(format: "%.0f", calculateTWA()))
                            .font(.zenithBeta(size: 22, weight: .medium))
                            .foregroundColor(settings.lightMode ? .black : .white)
                            .offset(y: -3)
                        
                        Text("TWA")
                            .font(.zenithBeta(size: 10, weight: .medium))
                            .foregroundColor(settings.lightMode ? .black : .white)
                            .opacity(courseTracker.isLocked ? 1.0 : 0.5) // Dim when using last reading
                            .offset(y: -6.5)
                    }
                } else {
                    // Wind Speed Display
                    VStack(spacing: 0) {
                        Image(systemName: "wind")
                            .font(.system(size: 8, weight: .heavy))
                            .symbolVariant(.fill)
                            .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.5))
                            .offset(y: 1)
                        
                        Text(String(format: "%.0f", weatherManager.windSpeed))
                            .font(.zenithBeta(size: 22, weight: .medium))
                            .foregroundColor(settings.lightMode ? .black : .white)
                            .offset(y: -1)
                        
                        Text(weatherManager.cardinalDirection)
                            .font(.zenithBeta(size: 10, weight: .medium))
                            .foregroundColor(settings.lightMode ? .black : .white)
                            .offset(y: -4.5)
                    }
                }
            }
            .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            compassManager.startUpdates()
            weatherManager.setLastReadingManager(lastReadingManager)
        }
        .onDisappear {
            compassManager.stopUpdates()
        }
    }
}

// MARK: - Compass View
struct CompassView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    @StateObject private var compassManager = CompassManager()
    @StateObject private var weatherManager = WeatherManager()
    @State private var showingSunMoon: Bool = false
    @State private var showingPlannerSheet: Bool = false  // New state for showing planner sheet
    @ObservedObject var cruisePlanState: WatchCruisePlanState

    // Use the shared direction manager to access waypoint data
    @ObservedObject private var waypointDirectionManager = WaypointDirectionManager.shared

    private func getNorthPosition(heading: Double, isReduced: Bool) -> CGPoint {
        if isReduced {
            return CGPoint(x: 0, y: 0)
        } else {
            let angleInDegrees = 270 - heading
            let angle = angleInDegrees * .pi / 180
            
            let x = 20 * cos(angle)
            let y = 20 * sin(angle)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    // Calculate the waypoint position using the bearing from the direction manager
    private func getWaypointPosition(heading: Double, isReduced: Bool) -> CGPoint {
        if isReduced {
            return CGPoint(x: 0, y: 0)
        } else {
            // Get bearing from the direction manager
            let waypointBearing = waypointDirectionManager.waypointBearing
            
            // Adjust for compass heading
            let angleInDegrees = 270 - heading + waypointBearing
            let angle = angleInDegrees * .pi / 180
            
            let x = 20 * cos(angle)
            let y = 20 * sin(angle)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    var body: some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            withAnimation(.easeInOut(duration: 0.2)) {
                showingPlannerSheet = true  // Show the planner sheet instead of toggling sunMoon
            }
        }) {
            ZStack {
                // Standard Compass View
                ZStack {
                    // Background circle
                    Circle()
                        .fill(settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if !isLuminanceReduced {
                        // Normal mode: show heading and cardinal direction
                        VStack(spacing: 0) {
                            Text(String(format: "%.0f", compassManager.heading))
                                .font(.zenithBeta(size: 22, weight: .medium))
                                .foregroundColor(settings.lightMode ? .black : .white)
                                .offset(y: 3.5)
                            
                            Text(compassManager.cardinalDirection)
                                .font(.zenithBeta(size: 10, weight: .medium))
                                .foregroundColor(settings.lightMode ? .black : .white)
                                .offset(y: 0)
                        }
                        .animation(nil, value: isLuminanceReduced) // Prevent text animation
                    }
                    
                    // Waypoint indicator circle (below north indicator)
                    if waypointDirectionManager.isActive {
                        let waypointPosition = getWaypointPosition(heading: compassManager.heading, isReduced: isLuminanceReduced)
                        Circle()
                            .fill(Color(hex: colorManager.selectedTheme.rawValue))
                            .frame(width: isLuminanceReduced ? 15 : 5, height: isLuminanceReduced ? 15 : 5)
                            .offset(
                                x: waypointPosition.x,
                                y: waypointPosition.y
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLuminanceReduced)
                            .animation(.linear(duration: 0.1), value: compassManager.heading)
                            .animation(.linear(duration: 0.1), value: waypointDirectionManager.waypointBearing)
                            .zIndex(0)  // Ensure it's below north indicator
                    }
                    
                    if cruisePlanState.isActive && !waypointDirectionManager.isActive {
                        let position = getNorthPosition(heading: compassManager.heading, isReduced: isLuminanceReduced)
                        Circle()
                            .fill(Color(hex: colorManager.selectedTheme.rawValue))
                            .frame(width: isLuminanceReduced ? 15 : 7, height: isLuminanceReduced ? 15 : 7)
                            .offset(
                                x: position.x,
                                y: position.y
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLuminanceReduced)
                            .animation(.linear(duration: 0.1), value: compassManager.heading)
                    }
                    
                    // Animated red circle for north
                    let position = getNorthPosition(heading: compassManager.heading, isReduced: isLuminanceReduced)
                    Circle()
                        .fill(Color.red)
                        .frame(width: isLuminanceReduced ? 10 : 5, height: isLuminanceReduced ? 10 : 5)
                        .offset(
                            x: position.x,
                            y: position.y
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLuminanceReduced)
                        .animation(.linear(duration: 0.1), value: compassManager.heading)
                        .zIndex(1)  // Ensure it's above waypoint indicator
                }
            }
            .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            compassManager.startUpdates()
            
            // Debug output for waypoint direction
            print("💠 CompassView appeared: Waypoint direction active=\(waypointDirectionManager.isActive)")
        }
        .onDisappear {
            compassManager.stopUpdates()
        }
        .sheet(isPresented: $showingPlannerSheet) {
            // Present the WatchPlannerView as a sheet
            NavigationView {
                WatchCruisePlannerView()
                    .navigationTitle("Race Plan")
            }
        }
        // Add onChange handler to monitor waypoint direction changes
        .onChange(of: waypointDirectionManager.isActive) { _, newIsActive in
            print("💠 Waypoint direction active changed: \(newIsActive)")
        }
        .onChange(of: waypointDirectionManager.waypointBearing) { _, newBearing in
            print("💠 Waypoint bearing changed: \(newBearing)°")
        }
    }
}

// MARK: - Barometer View
struct BarometerView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var pressureManager = PressureManager()
    @StateObject private var weatherManager = WeatherManager()
    @EnvironmentObject var colorManager: ColorManager
    @State private var showingPressure: Bool = false
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    
    private var fillPercentage: CGFloat {
        guard weatherManager.highTemp > weatherManager.lowTemp else { return 0 }
        let percentage = (weatherManager.currentTemp - weatherManager.lowTemp) /
                        (weatherManager.highTemp - weatherManager.lowTemp)
        return min(max(percentage, 0), 1) // Clamp between 0 and 1
    }
    
    var body: some View {
        ZStack {
            if !showingPressure {
                Circle()
                    .fill(settings.lightMode ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
            }
                
            if !showingPressure {
                // Temperature Fill Layer
                ZStack {
                    
                    Rectangle() //match background
                        .fill(settings.lightMode ? .white : .black)
                        .frame(width: 50, height: isLuminanceReduced ? 0 : 50 * fillPercentage, alignment: .bottom)
                        .frame(width: 50, height: 50, alignment: .bottom)
                        .clipShape(Circle())
                        .animation(.spring(response: 1.8, dampingFraction: 0.8), value: fillPercentage)
                        .animation(.spring(response: 1.8, dampingFraction: 0.8), value: isLuminanceReduced)
                    
                    Rectangle()
                        .fill(settings.lightMode ? Color(hex: colorManager.selectedTheme.rawValue) : Color(hex: colorManager.selectedTheme.rawValue).opacity(0.6))
                        .frame(width: 50, height: isLuminanceReduced ? 0 : 50 * fillPercentage, alignment: .bottom)
                        .frame(width: 50, height: 50, alignment: .bottom)
                        .clipShape(Circle())
                        .animation(.spring(response: 1.8, dampingFraction: 0.8), value: fillPercentage)
                        .animation(.spring(response: 1.8, dampingFraction: 0.8), value: isLuminanceReduced)
                }
            }
            
            if showingPressure /*&& pressureManager.isAvailable*/ {
                // Pressure Display
                SunMoonView()
/*
                VStack(spacing: 0) {
                    Text(trendSymbol)
                        .font(.system(size: 10))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y:-2)
                    
                    Text(String(format: "%.0f", pressureManager.currentPressure))
                        .font(.zenithBeta(size: 18, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y:-2)
                    
                    Text("hPa")
                        .font(.zenithBeta(size: 10, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y:-4)
                }
                */
            } else {
                // Temperature Display
                VStack(spacing: 0) {
                    Image(systemName: weatherManager.condition)
                        .font(.system(size: 8, weight: .heavy))
                        .symbolVariant(.fill)
                        .foregroundColor(settings.lightMode ? .black.opacity(0.4) : .white.opacity(0.4))
                        .offset(y:1)
                    
                    Text(String(format: "%.0f", weatherManager.currentTemp))
                        .font(.zenithBeta(size: 22, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y:-2)
                    
                    Text(String(format: "%.0f-%.0f", weatherManager.lowTemp, weatherManager.highTemp))
                        .font(.zenithBeta(size: 9, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y:-5.5)
                }
            }
        }
        .onTapGesture {
//            if pressureManager.isAvailable {
                WKInterfaceDevice.current().play(.click)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingPressure.toggle()
//                }
            }
        }
    }
    
    var trendSymbol: String {
        switch pressureManager.pressureTrend {
        case .rising: return "▲"
        case .falling: return "▼"
        case .stable: return "~"
        }
    }
}

/*
//# MARK: - Preview
struct WeatherViews_Previews: PreviewProvider {
    static var settings = AppSettings()
    static var colorManager = ColorManager()
    static var courseTracker = CourseTracker()
    static var lastReadingManager = LastReadingManager()
    @ObservedObject var cruisePlanState: WatchCruisePlanState

    
    static var previews: some View {
        HStack(spacing: 10) {
            WindSpeedView(
                courseTracker: courseTracker,
                lastReadingManager: lastReadingManager
            )
            CompassView(cruisePlanState: cruisePlanState)
            BarometerView()
        }
        .environmentObject(settings)
        .environmentObject(colorManager)
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black)
    }
}
*/
