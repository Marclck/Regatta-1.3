//
//  CoordinateUtilities.swift
//  Regatta
//
//  Created by Chikai Lai on 18/04/2025.
//

import Foundation
import SwiftUI
import CoreLocation

// Create a wrapper struct for CLLocationCoordinate2D that conforms to Equatable
struct EquatableCoordinate: Equatable {
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

// Define the preference key using the wrapper
struct CenterCoordinatePreferenceKey: PreferenceKey {
    static var defaultValue: EquatableCoordinate = EquatableCoordinate(
        coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
    )
    
    static func reduce(value: inout EquatableCoordinate, nextValue: () -> EquatableCoordinate) {
        value = nextValue()
    }
}
