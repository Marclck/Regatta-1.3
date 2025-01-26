//
//  StartLineManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 26/01/2025.
//

import Foundation
import CoreLocation

class StartLineManager: ObservableObject {
    private let defaults = UserDefaults.standard
    private let updateTimer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()
    private let farUpdateTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    @Published var leftPoint: LocationPoint?
    @Published var rightPoint: LocationPoint?
    @Published var currentDistance: Double?
    @Published var leftButtonState: ButtonState = .white
    @Published var rightButtonState: ButtonState = .white
    
    struct LocationPoint: Codable {
            let coordinate: CLLocationCoordinate2D
            let timestamp: Date
            
            enum CodingKeys: String, CodingKey {
                case latitude = "lat"
                case longitude = "lon"
                case timestamp
            }
            
            init(location: CLLocation) {
                self.coordinate = location.coordinate
                self.timestamp = location.timestamp
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(coordinate.latitude, forKey: .latitude)
                try container.encode(coordinate.longitude, forKey: .longitude)
                try container.encode(timestamp, forKey: .timestamp)
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let lat = try container.decode(Double.self, forKey: .latitude)
                let lon = try container.decode(Double.self, forKey: .longitude)
                let timestamp = try container.decode(Date.self, forKey: .timestamp)
                
                self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                self.timestamp = timestamp
            }
        }
    
    enum ButtonState {
        case white
        case green
        case red
        case disabled
    }
    
    init() {
        loadStoredLocations()
        setupPeriodicCleanup()
    }
    
    private func loadStoredLocations() {
        if let leftData = defaults.data(forKey: "leftPoint"),
           let rightData = defaults.data(forKey: "rightPoint") {
            do {
                let leftPoint = try JSONDecoder().decode(LocationPoint.self, from: leftData)
                let rightPoint = try JSONDecoder().decode(LocationPoint.self, from: rightData)
                
                // Check if points are older than 24 hours
                let dayAgo = Date().addingTimeInterval(-86400)
                if leftPoint.timestamp > dayAgo {
                    self.leftPoint = leftPoint
                    leftButtonState = .green
                }
                if rightPoint.timestamp > dayAgo {
                    self.rightPoint = rightPoint
                    rightButtonState = .green
                }
            } catch {
                print("Error loading stored locations: \(error)")
            }
        }
    }
    
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.cleanupOldLocations()
        }
    }
    
    private func cleanupOldLocations() {
        let dayAgo = Date().addingTimeInterval(-86400)
        
        if let leftPoint = leftPoint, leftPoint.timestamp < dayAgo {
            self.leftPoint = nil
            leftButtonState = .white
            defaults.removeObject(forKey: "leftPoint")
        }
        
        if let rightPoint = rightPoint, rightPoint.timestamp < dayAgo {
            self.rightPoint = nil
            rightButtonState = .white
            defaults.removeObject(forKey: "rightPoint")
        }
    }
    
    func handleLeftButtonPress(currentLocation: CLLocation?) {
            print("📌 Left button pressed. Current state: \(leftButtonState)")
            print("📍 Location available: \(currentLocation != nil)")
            if let location = currentLocation {
                print("📍 Location accuracy: \(location.horizontalAccuracy)m")
            }
            
            switch leftButtonState {
            case .white:
                if let location = currentLocation {
                    if location.horizontalAccuracy <= 20.0 {  // Changed to 10 meters
                        print("✅ Storing left point")
                        storeLeftPoint(location)
                        leftButtonState = .green
                    } else {
                        print("❌ Location accuracy insufficient: \(location.horizontalAccuracy)m")
                    }
                } else {
                    print("❌ No location available")
                }
            case .green:
                print("🔄 Changing left button to red")
                leftButtonState = .red
            case .red:
                print("🗑️ Clearing left point")
                leftPoint = nil
                defaults.removeObject(forKey: "leftPoint")
                leftButtonState = .white
            case .disabled:
                print("⚠️ Button disabled")
                break
            }
        }
        
        func handleRightButtonPress(currentLocation: CLLocation?) {
            print("📌 Right button pressed. Current state: \(rightButtonState)")
            print("📍 Location available: \(currentLocation != nil)")
            if let location = currentLocation {
                print("📍 Location accuracy: \(location.horizontalAccuracy)m")
            }
            
            switch rightButtonState {
            case .white:
                if let location = currentLocation {
                    if location.horizontalAccuracy <= 20.0 {  // Changed to 10 meters
                        print("✅ Storing right point")
                        storeRightPoint(location)
                        rightButtonState = .green
                    } else {
                        print("❌ Location accuracy insufficient: \(location.horizontalAccuracy)m")
                    }
                } else {
                    print("❌ No location available")
                }
            case .green:
                print("🔄 Changing right button to red")
                rightButtonState = .red
            case .red:
                print("🗑️ Clearing right point")
                rightPoint = nil
                defaults.removeObject(forKey: "rightPoint")
                rightButtonState = .white
            case .disabled:
                print("⚠️ Button disabled")
                break
            }
        }
    
    private func storeLeftPoint(_ location: CLLocation) {
        print("💾 Storing left point at: \(location.coordinate)")
        let point = LocationPoint(location: location)
        leftPoint = point
        if let encoded = try? JSONEncoder().encode(point) {
            defaults.set(encoded, forKey: "leftPoint")
            print("✅ Left point stored successfully")
        } else {
            print("❌ Failed to encode left point")
        }
    }

    private func storeRightPoint(_ location: CLLocation) {
        print("💾 Storing right point at: \(location.coordinate)")
        let point = LocationPoint(location: location)
        rightPoint = point
        if let encoded = try? JSONEncoder().encode(point) {
            defaults.set(encoded, forKey: "rightPoint")
            print("✅ Right point stored successfully")
        } else {
            print("❌ Failed to encode right point")
        }
    }
    
    func updateDistance(currentLocation: CLLocation) {
            print("🔄 Starting distance calculation...")
            print("📍 Current location: \(currentLocation.coordinate)")
            print("📏 Current accuracy: \(currentLocation.horizontalAccuracy)m")
            
            guard currentLocation.horizontalAccuracy <= 30.0 else {
                print("❌ Accuracy check failed: \(currentLocation.horizontalAccuracy)m > 30.0m")
                currentDistance = nil
                return
            }
            
            if let left = leftPoint?.coordinate, let right = rightPoint?.coordinate {
                print("✅ Both points available")
                print("📌 Left point: \(left)")
                print("📌 Right point: \(right)")
                
                // Calculate distance to line segment
                let distance = distanceToLineSegment(
                    point: currentLocation.coordinate,
                    lineStart: left,
                    lineEnd: right
                )
                print("📏 Calculated distance: \(distance)m")
                currentDistance = distance
                
            } else if let point = leftPoint?.coordinate ?? rightPoint?.coordinate {
                print("ℹ️ Single point available")
                print("📌 Reference point: \(point)")
                
                // Calculate direct distance to single point
                let distance = currentLocation.coordinate.distance(to: point)
                print("📏 Calculated direct distance: \(distance)m")
                currentDistance = distance
                
            } else {
                print("❌ No points available for distance calculation")
                currentDistance = nil
            }
            
            print("🏁 Final distance value: \(String(describing: currentDistance))m")
        }
        
    private func distanceToLineSegment(
            point: CLLocationCoordinate2D,
            lineStart: CLLocationCoordinate2D,
            lineEnd: CLLocationCoordinate2D
        ) -> Double {
            print("📐 Calculating line segment distance...")
            let a = point.distance(to: lineStart)
            let b = point.distance(to: lineEnd)
            let c = lineStart.distance(to: lineEnd)
            
            print("📏 Distances:")
            print("   To start point (a): \(a)m")
            print("   To end point (b): \(b)m")
            print("   Line length (c): \(c)m")
            
            // Guard against zero line length
            guard c > 0.1 else {  // If points are very close together
                print("⚠️ Line length too small, using direct distance")
                return min(a, b)
            }
            
            // If angle is obtuse, use distance to closest endpoint
            if (a * a > b * b + c * c) {
                print("📐 Obtuse angle at end point, using distance to end: \(b)m")
                return b
            }
            if (b * b > a * a + c * c) {
                print("📐 Obtuse angle at start point, using distance to start: \(a)m")
                return a
            }
            
            // Calculate perpendicular distance using Heron's formula
            let s = (a + b + c) / 2
            print("   Semi-perimeter (s): \(s)m")
            
            // Guard against negative values under sqrt
            let underSqrt = s * (s - a) * (s - b) * (s - c)
            guard underSqrt > 0 else {
                print("⚠️ Invalid triangle, using closest point distance")
                return min(a, b)
            }
            
            let area = sqrt(underSqrt)
            let distance = 2 * area / c
            print("📐 Area: \(area)m², Perpendicular distance: \(distance)m")
            return distance
        }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return thisLocation.distance(from: otherLocation)
    }
}
