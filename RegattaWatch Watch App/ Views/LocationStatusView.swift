//
//  LocationStatusView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 20/01/2025.
//

import SwiftUI
import CoreLocation
#if os(iOS)
import UIKit
#else
import WatchKit
#endif

struct LocationStatusView: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        Group {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                Button("Enable Location") {
                    locationManager.requestLocationPermission()
                }
            case .restricted, .denied:
                VStack {
                    Text("Location Access Required")
                        .font(.headline)
                    Text("Please enable location access in Settings")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Open Settings") {
                        openSettings()
                    }
                }
            case .authorizedWhenInUse, .authorizedAlways:
                // Location is enabled, show speed or other content
                EmptyView()
            @unknown default:
                Text("Unknown Location Status")
            }
        }
    }
    
    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #else
        if let url = URL(string: "x-apple-watch://") {
            WKExtension.shared().openSystemURL(url)
        }
        #endif
    }
}
