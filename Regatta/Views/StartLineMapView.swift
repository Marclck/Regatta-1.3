//
//  StartLineMapView.swift
//  Regatta
//
//  Created by Chikai Lai on 26/01/2025.
//

import Foundation
import SwiftUI
import MapKit

struct StartLinePoint: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let isLeft: Bool
}

struct StartLineMapView: View {
    let leftPoint: LocationData?
    let rightPoint: LocationData?
    @StateObject private var locationHelper = LocationHelper.shared
    @State private var region: MKCoordinateRegion
    @State private var isInitialSetup = true  // Track initial setup
    
    private var points: [StartLinePoint] {
        var result: [StartLinePoint] = []
        if let left = leftPoint {
            result.append(StartLinePoint(
                id: "left",
                coordinate: CLLocationCoordinate2D(
                    latitude: left.latitude,
                    longitude: left.longitude
                ),
                isLeft: true
            ))
        }
        if let right = rightPoint {
            result.append(StartLinePoint(
                id: "right",
                coordinate: CLLocationCoordinate2D(
                    latitude: right.latitude,
                    longitude: right.longitude
                ),
                isLeft: false
            ))
        }
        return result
    }
    
    init(leftPoint: LocationData?, rightPoint: LocationData?) {
        self.leftPoint = leftPoint
        self.rightPoint = rightPoint
        
        // Calculate initial region based on points
        if let left = leftPoint, let right = rightPoint {
            let center = CLLocationCoordinate2D(
                latitude: (left.latitude + right.latitude) / 2,
                longitude: (left.longitude + right.longitude) / 2
            )
            let latDelta = abs(left.latitude - right.latitude) * 1.5
            let lonDelta = abs(left.longitude - right.longitude) * 1.5
            _region = State(initialValue: MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.005), longitudeDelta: max(lonDelta, 0.005))
            ))
        } else if let point = leftPoint ?? rightPoint {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
            ))
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: .none,
            annotationItems: points) { point in
            MapAnnotation(coordinate: point.coordinate) {
                Image(systemName: point.isLeft ? "triangle.fill" : "square.fill")
                    .foregroundColor(.green)
                    .frame(width: 20, height: 20)
                    .id(point.id)
            }
        }
        .overlay {
            if let left = leftPoint, let right = rightPoint {
                GeometryReader { geometry in
                    let leftPoint = convertToPoint(
                        coordinate: CLLocationCoordinate2D(latitude: left.latitude, longitude: left.longitude),
                        in: geometry,
                        region: region
                    )
                    let rightPoint = convertToPoint(
                        coordinate: CLLocationCoordinate2D(latitude: right.latitude, longitude: right.longitude),
                        in: geometry,
                        region: region
                    )
                    
                    Path { path in
                        path.move(to: leftPoint)
                        path.addLine(to: rightPoint)
                    }
                    .stroke(Color.green, lineWidth: 2)
                }
            }
        }
        .frame(height: 200)
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            if isInitialSetup {
                locationHelper.requestLocationPermission()
                locationHelper.startUpdatingLocation()
                isInitialSetup = false
            }
        }
        .onDisappear {
            locationHelper.stopUpdatingLocation()
        }
    }
    
    private func convertToPoint(coordinate: CLLocationCoordinate2D, in geometry: GeometryProxy, region: MKCoordinateRegion) -> CGPoint {
        let latRatio = (coordinate.latitude - region.center.latitude) / region.span.latitudeDelta
        let lonRatio = (coordinate.longitude - region.center.longitude) / region.span.longitudeDelta
        
        let midX = geometry.size.width / 2
        let midY = geometry.size.height / 2
        
        return CGPoint(
            x: midX + midX * CGFloat(lonRatio) * 2,
            y: midY - midY * CGFloat(latRatio) * 2
        )
    }
}
