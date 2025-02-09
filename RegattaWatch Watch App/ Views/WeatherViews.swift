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
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000 // Update every 1km
        setupLocation()
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
                    self.windSpeed = weather.currentWeather.wind.speed.converted(to: .knots).value
                    self.windDirection = weather.currentWeather.wind.direction.value
                    self.updateCardinalDirection(self.windDirection)
                    self.isLoading = false
                    self.error = nil
                    
                    // Schedule next update
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
    @Published var currentPressure: Double = 1013.25  // Standard atmospheric pressure
    @Published var pressureTrend: PressureTrend = .stable
    private var historicalReadings: [(pressure: Double, timestamp: Date)] = []
    private var timer: Timer?
    
    enum PressureTrend {
        case rising, falling, stable
    }
    
    init() {
        startUpdates()
    }
    
    func startUpdates() {
        updatePressure()
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.updatePressure()
        }
    }
    
    private func updatePressure() {
        // In a real implementation, we would get this from the device
        // For now, simulate with realistic values
        let altimeter = CMAltimeter()
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
                guard let data = data, let self = self else { return }
                let pressure = data.pressure.doubleValue * 10  // Convert to hPa
                self.historicalReadings.append((pressure, Date()))
                self.currentPressure = pressure
                self.updateTrend()
            }
        }
    }
    
    private func updateTrend() {
        // Keep only last 3 hours of readings
        let threeHoursAgo = Date().addingTimeInterval(-3 * 60 * 60)
        historicalReadings = historicalReadings.filter { $0.timestamp > threeHoursAgo }
        
        guard let oldestReading = historicalReadings.first?.pressure,
              let latestReading = historicalReadings.last?.pressure else {
            pressureTrend = .stable
            return
        }
        
        let change = latestReading - oldestReading
        if change > 2 {
            pressureTrend = .rising
        } else if change < -2 {
            pressureTrend = .falling
        } else {
            pressureTrend = .stable
        }
    }
    
    deinit {
        timer?.invalidate()
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
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.1))
                .frame(width: 50, height: 50)
            
            VStack(spacing: 0) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 10, weight: .heavy))
                    .symbolVariant(.fill)
                    .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4))
                
                Text(String(format: "%.0f", $weatherManager.windSpeed.wrappedValue))
                    .font(.zenithBeta(size: 22, weight: .medium))
                    .foregroundColor(settings.lightMode ? .black : .white)
                    .offset(y:-2)
                
                Text($weatherManager.cardinalDirection.wrappedValue)
                    .font(.zenithBeta(size: 10, weight: .medium))
                    .foregroundColor(settings.lightMode ? .black : .white)
                    .offset(y:-5)
            }
        }
    }
}

// MARK: - Compass View
struct CompassView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var settings: AppSettings
    @StateObject private var compassManager = CompassManager()
    
    private func getNorthPosition(heading: Double) -> CGPoint {
        let angleInDegrees = 270 - heading
        let angle = angleInDegrees * .pi / 180
        
        let x = 20 * cos(angle)
        let y = 20 * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 50, height: 50)
            
            if isLuminanceReduced {
                // Centered red dot when in low luminance mode
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            } else {
                // Normal mode: show heading and rotating north indicator
                VStack(spacing: 0) {
                    Text(String(format: "%.0f", compassManager.heading))
                        .font(.zenithBeta(size: 22, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y: 3)
                    
                    Text(compassManager.cardinalDirection)
                        .font(.zenithBeta(size: 10, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y: 0)
                }
                
                // North indicator
                let position = getNorthPosition(heading: compassManager.heading)
                Circle()
                    .fill(Color.red)
                    .frame(width: 5, height: 5)
                    .offset(x: position.x, y: position.y)
            }
        }
        .clipShape(Circle())
        .onAppear {
            compassManager.startUpdates()
        }
        .onDisappear {
            compassManager.stopUpdates()
        }
    }
}

// MARK: - Barometer View
struct BarometerView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var pressureManager = PressureManager()
    
    var trendSymbol: String {
        switch pressureManager.pressureTrend {
        case .rising:
            return "▲"
        case .falling:
            return "▼"
        case .stable:
            return "~"
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 50, height: 50)
            
            VStack(spacing: 0) {
                Text(trendSymbol)
                    .font(.system(size: 10))
                    .foregroundColor(settings.lightMode ? .black : .white)
                
                Text(String(format: "%.0f", pressureManager.currentPressure))
                    .font(.zenithBeta(size: 16, weight: .medium))
                    .foregroundColor(settings.lightMode ? .black : .white)
                
                Text("hPa")
                    .font(.zenithBeta(size: 10, weight: .medium))
                    .foregroundColor(settings.lightMode ? .black.opacity(0.5) : .white.opacity(0.5))
                    .offset(y:-3)

            }
        }
    }
}

// MARK: - Preview
struct WeatherViews_Previews: PreviewProvider {
    static var settings = AppSettings()
    static var colorManager = ColorManager()
    
    static var previews: some View {
        HStack(spacing: 10) {
            WindSpeedView()
            CompassView()
            BarometerView()
        }
        .environmentObject(settings)
        .environmentObject(colorManager)
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black)
    }
}
