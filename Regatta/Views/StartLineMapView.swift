//
//  StartLineMapView.swift
//  Regatta
//
//  Created by Chikai Lai on 26/01/2025.
//

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
            // When both points exist, center between them with padding
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
            // When only one point exists, center on it with fixed zoom
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        } else if let userLocation = LocationHelper.shared.lastLocation {
            // Use user's current location if available
            _region = State(initialValue: MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            // Fallback to a default region when no location is available yet
            // Using a smaller span than before for a better initial view
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }
    
    var body: some View {
        ZStack {
            MapViewWithButtons(
                region: $region,
                points: points,
                leftPoint: leftPoint,
                rightPoint: rightPoint
            )
            .edgesIgnoringSafeArea(.all)
            
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
                
                // If no points exist, try to update with user location
                if leftPoint == nil && rightPoint == nil && locationHelper.lastLocation == nil {
                    // Check again after a brief delay to allow location services to start
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if let userLocation = locationHelper.lastLocation {
                            self.region = MKCoordinateRegion(
                                center: userLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                    }
                }
                
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

// MARK: - MapView with Buttons
struct MapViewWithButtons: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var points: [StartLinePoint]
    var leftPoint: LocationData?
    var rightPoint: LocationData?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.region = region
        
        // Create buttons
        let locationButton = UIButton.createMapControlButton(
            imageName: "location.fill",
            target: context.coordinator,
            action: #selector(Coordinator.centerOnCurrentLocation(_:))
        )
        
        let zoomButton = UIButton.createMapControlButton(
            imageName: "arrow.up.left.and.arrow.down.right",
            target: context.coordinator,
            action: #selector(Coordinator.fitStartLinePoints(_:))
        )
        
        // Add buttons directly to the map view
        mapView.addSubview(locationButton)
        mapView.addSubview(zoomButton)
        
        // Position buttons in the top right corner with adequate spacing
        NSLayoutConstraint.activate([
            // Location button constraints
            locationButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 12),
            locationButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8),
            locationButton.widthAnchor.constraint(equalToConstant: 40),
            locationButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Zoom button constraints
            zoomButton.topAnchor.constraint(equalTo: locationButton.bottomAnchor, constant: 12),
            zoomButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8),
            zoomButton.widthAnchor.constraint(equalToConstant: 40),
            zoomButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add annotations for the start line points
        updateAnnotations(mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the region if it changed
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude ||
           mapView.region.span.latitudeDelta != region.span.latitudeDelta ||
           mapView.region.span.longitudeDelta != region.span.longitudeDelta {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations
        updateAnnotations(mapView)
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        // Remove existing annotations except user location
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Add the start line points as annotations
        for point in points {
            let annotation = MKPointAnnotation()
            annotation.coordinate = point.coordinate
            annotation.title = point.isLeft ? "Port End" : "Starboard End"
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithButtons
        
        init(_ parent: MapViewWithButtons) {
            self.parent = parent
            super.init()
        }
        
        @objc func centerOnCurrentLocation(_ sender: UIButton) {
            guard let mapView = sender.superview as? MKMapView else { return }
            
            // Get user location
            let userLocation = mapView.userLocation
            
            // Check if we have a valid user location
            if let location = userLocation.location, CLLocationCoordinate2DIsValid(location.coordinate) {
                // Create a region around the user location
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 500, // 500m zoom
                    longitudinalMeters: 500
                )
                
                // Set the map region with animation
                mapView.setRegion(region, animated: true)
                
                // Update the SwiftUI binding
                DispatchQueue.main.async {
                    self.parent.region = region
                }
            } else {
                // If user location isn't available, try to center on start line
                fitStartLinePoints(sender)
            }
        }
        
        @objc func fitStartLinePoints(_ sender: UIButton) {
            guard let mapView = sender.superview as? MKMapView else { return }
            
            // Check if we have both start line points
            if let leftPoint = parent.leftPoint, let rightPoint = parent.rightPoint {
                // Calculate center point between the two start line points
                let center = CLLocationCoordinate2D(
                    latitude: (leftPoint.latitude + rightPoint.latitude) / 2,
                    longitude: (leftPoint.longitude + rightPoint.longitude) / 2
                )
                
                // Calculate appropriate span to show both points with padding
                let latDelta = abs(leftPoint.latitude - rightPoint.latitude) * 1.8
                let lonDelta = abs(leftPoint.longitude - rightPoint.longitude) * 1.8
                
                // Create region with at least minimum zoom level
                let region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(
                        latitudeDelta: max(latDelta, 0.005),
                        longitudeDelta: max(lonDelta, 0.005)
                    )
                )
                
                // Set region with animation
                mapView.setRegion(region, animated: true)
                
                // Update the SwiftUI binding
                DispatchQueue.main.async {
                    self.parent.region = region
                }
            } else if let singlePoint = parent.leftPoint ?? parent.rightPoint {
                // If we only have one point, center on it
                let center = CLLocationCoordinate2D(
                    latitude: singlePoint.latitude,
                    longitude: singlePoint.longitude
                )
                
                let region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
                
                mapView.setRegion(region, animated: true)
                
                // Update the SwiftUI binding
                DispatchQueue.main.async {
                    self.parent.region = region
                }
            }
        }
        
        // Map view delegate method for customizing annotation views
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            // Create custom annotation view for start line points
            let identifier = "StartLinePoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Style the marker based on whether it's port or starboard end
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .green
                
                // Set different marker shapes
                if annotation.title == "Port End" {
                    markerView.glyphImage = UIImage(systemName: "triangle.fill")
                } else {
                    markerView.glyphImage = UIImage(systemName: "square.fill")
                }
            }
            
            return annotationView
        }
    }
}
