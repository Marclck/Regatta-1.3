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
   private var isActive = false
   
   @Published var speed: Double = 0.0
   @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
   @Published var lastLocation: CLLocation?
   @Published var locationError: Error?
   @Published var isLocationValid: Bool = false
   var isMonitoring: Bool { isLocationValid }
   
   private var lastSpeed: Double = 0.0
   private var isInitialized = false
   
   override init() {
       super.init()
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
       if !isInitialized {
           isInitialized = true
           if locationManager.authorizationStatus == .notDetermined {
               requestLocationPermission()
               return
           }
       }
       
       if locationManager.authorizationStatus == .authorizedWhenInUse ||
          locationManager.authorizationStatus == .authorizedAlways {
           isActive = true
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
       isActive = false
       locationManager.stopUpdatingLocation()
       updateTimer?.invalidate()
       updateTimer = nil
       isLocationValid = false
       speed = 0
       lastSpeed = 0
   }
}

extension LocationManager: CLLocationManagerDelegate {
   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       guard isActive, let location = locations.last else { return }
       
       // Update last location regardless of speed for pin placement
       lastLocation = location
       
       // Check accuracy for valid state
       isLocationValid = location.horizontalAccuracy <= 10  // More stringent accuracy requirement
       
       // Update speed only if moving
       if location.speed >= 0.5 {  // Still filter speed updates
           lastSpeed = location.speed
           print("Location update received. Speed: \(lastSpeed) m/s, Accuracy: \(location.horizontalAccuracy)m")
       } else {
           lastSpeed = 0
           speed = 0
       }
   }
   
   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
       guard isActive else { return }
       
       locationError = error
       isLocationValid = false
       print("Location error: \(error.localizedDescription)")
   }
   
   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       DispatchQueue.main.async {
           print("Location authorization status changed: \(status)")
           self.authorizationStatus = status
           
           if status == .denied || status == .restricted {
               self.stopUpdatingLocation()
               self.speed = 0
           }
       }
   }
}
