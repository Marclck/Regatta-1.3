//
//  LocationManager.swift
//  Regatta
//
//  Created by Chikai Lai on 20/01/2025.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private var locationManager = CLLocationManager()
    private var updateTimer: Timer?
    
    @Published var speed: Double = 0.0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var locationError: Error?
    @Published var isLocationValid: Bool = false
    
    private var lastSpeed: Double = 0.0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 3
        locationManager.allowsBackgroundLocationUpdates = true
        
        #if os(iOS)
        locationManager.showsBackgroundLocationIndicator = true
        #endif
        
        // Check current authorization status
        checkLocationAuthorization()
        
        // Set up timer for speed updates (2-second intervals)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            if let lastSpeed = self?.lastSpeed {
                self?.speed = lastSpeed
            }
        }
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .notDetermined:
            requestLocationPermission()
        case .denied, .restricted:
            isLocationValid = false
            speed = 0
        @unknown default:
            break
        }
    }
    
    func requestLocationPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            print("Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            print("Starting location updates...")
            locationManager.startUpdatingLocation()
        } else {
            print("Cannot start location updates - no authorization")
            requestLocationPermission()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLocationValid = false
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update last location
        lastLocation = location
        isLocationValid = true
        
        // Update speed (convert from m/s to knots if needed)
        lastSpeed = location.speed >= 0 ? location.speed : 0
        print("Location update received. Speed: \(lastSpeed)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        isLocationValid = false
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            print("Location authorization status changed: \(status)")
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.stopUpdatingLocation()
                self.speed = 0
            case .notDetermined:
                self.requestLocationPermission()
            @unknown default:
                break
            }
        }
    }
}
