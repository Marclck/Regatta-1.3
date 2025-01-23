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
    private var isInitialized = false
    
    override init() {
        super.init()
        // Only configure the location manager, don't start anything
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 1
        locationManager.allowsBackgroundLocationUpdates = true
        
        #if os(iOS)
        locationManager.showsBackgroundLocationIndicator = true
        #endif
    }
    
    func requestLocationPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            print("Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        // Initialize permissions only on first start
        if !isInitialized {
            isInitialized = true
            if locationManager.authorizationStatus == .notDetermined {
                requestLocationPermission()
                return // Wait for authorization callback before starting
            }
        }
        
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            print("Starting location updates...")
            locationManager.startUpdatingLocation()
            
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                if let lastSpeed = self?.lastSpeed {
                    self?.speed = lastSpeed
                }
            }
        }
    }
    
    func stopUpdatingLocation() {
        print("Stopping location updates...")
        locationManager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
        isLocationValid = false
        speed = 0
        lastSpeed = 0
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        lastLocation = location
        isLocationValid = true
        
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
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                // Only start updates if this was triggered by our initial request
                if !self.isInitialized {
                    self.startUpdatingLocation()
                }
            } else if status == .denied || status == .restricted {
                self.stopUpdatingLocation()
                self.speed = 0
            }
        }
    }
}
