//
//  PlannerMapView.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Route Planning Map View
struct RoutePlanMapView: UIViewRepresentable {
    var points: [PlanPoint]
    var mapStyle: MapStyleConfiguration
    var activePinningMode: Bool
    var onMapMoved: ((CLLocationCoordinate2D) -> Void)?
    var onLocationSelected: ((CLLocationCoordinate2D) -> Void)?
    private static var coordinatorKey: UInt8 = 0
    private static var coordinatorHolder: [String: Coordinator] = [:]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Store reference to the mapView in coordinator for button actions
        context.coordinator.mapViewRef = mapView

        // Make sure the coordinator doesn't get deallocated
        objc_setAssociatedObject(mapView, &RoutePlanMapView.coordinatorKey, context.coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // Convert the MapStyleConfiguration to MKMapType
        switch mapStyle {
        case .standard:
            mapView.mapType = .standard
        case .hybrid:
            mapView.mapType = .hybrid
        case .satellite:
            mapView.mapType = .satellite
        }
        
        // Only add the pan gesture if initially in pinning mode
        if activePinningMode {
            let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
            panGesture.delegate = context.coordinator
            panGesture.cancelsTouchesInView = false
            panGesture.delaysTouchesBegan = false
            panGesture.delaysTouchesEnded = false
            mapView.addGestureRecognizer(panGesture)
            context.coordinator.panGestureRecognizer = panGesture
        }
        
        // Create buttons
        let locationButton = createMapControlButton(
            imageName: "location.fill",
            target: context.coordinator,
            action: #selector(Coordinator.centerOnCurrentLocation(_:))
        )
        
        let zoomButton = createMapControlButton(
            imageName: "arrow.up.left.and.arrow.down.right",
            target: context.coordinator,
            action: #selector(Coordinator.fitAnnotations(_:))
        )
        
        // Add buttons directly to the map view
        mapView.addSubview(locationButton)
        mapView.addSubview(zoomButton)
        
        // Position buttons in the top right corner with adequate spacing
        NSLayoutConstraint.activate([
            // Location button constraints
            locationButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 16),
            locationButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -16),
            locationButton.widthAnchor.constraint(equalToConstant: 40),
            locationButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Zoom button constraints
            zoomButton.topAnchor.constraint(equalTo: locationButton.bottomAnchor, constant: 12),
            zoomButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -16),
            zoomButton.widthAnchor.constraint(equalToConstant: 40),
            zoomButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        return mapView
    }

    private func createMapControlButton(imageName: String, target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        
        // Configure the image with proper sizing
        if let image = UIImage(systemName: imageName) {
            // Create a configuration for the icon
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            let scaledImage = image.withConfiguration(config)
            button.setImage(scaledImage, for: .normal)
        }
        
        // Style the button
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.tintColor = UIColor(Color(hex: ColorTheme.ultraBlue.rawValue))
        button.layer.cornerRadius = 8
        
        // Important: Let Auto Layout handle sizing
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set target and action
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Store the mapView reference in the coordinator at every update
        context.coordinator.mapViewRef = mapView
        
        // Ensure the coordinator doesn't get deallocated
        objc_setAssociatedObject(mapView, &RoutePlanMapView.coordinatorKey, context.coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Update the coordinator's parent reference
        context.coordinator.parent = self
                
        // Existing update logic remains the same
        if RoutePlanMapView.coordinatorHolder.count > 10 {
            RoutePlanMapView.coordinatorHolder = RoutePlanMapView.coordinatorHolder.filter {
                $0.value === context.coordinator
            }
        }
        
        // Convert the MapStyleConfiguration to MKMapType
        switch mapStyle {
        case .standard:
            mapView.mapType = .standard
        case .hybrid:
            mapView.mapType = .hybrid
        case .satellite:
            mapView.mapType = .satellite
        }
        
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Add route points as annotations
        let validPoints = points.filter { !(abs($0.latitude) < 0.0001 && abs($0.longitude) < 0.0001) }
        
        let annotations = validPoints.map { point -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = point.coordinate
            annotation.title = "\(point.order + 1)"
            return annotation
        }
        
        mapView.addAnnotations(annotations)
        
        // Add route line if we have at least 2 points
        if validPoints.count >= 2 {
            let coordinates = validPoints.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            
            // Zoom to fit the route if needed
            if let firstUpdate = context.coordinator.firstUpdate, firstUpdate {
                context.coordinator.firstUpdate = false
                mapView.setVisibleMapRect(
                    polyline.boundingMapRect.insetBy(dx: -5000, dy: -5000),
                    animated: true
                )
            }
        }
        
        // Update coordinator with current pinning mode
        let wasPinningMode = context.coordinator.activePinningMode
        context.coordinator.activePinningMode = activePinningMode
        
        // Handle the pan gesture recognizer based on pinning mode
        if activePinningMode && context.coordinator.panGestureRecognizer == nil {
            // Add the gesture if needed
            let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
            panGesture.delegate = context.coordinator
            panGesture.cancelsTouchesInView = false
            panGesture.delaysTouchesBegan = false
            panGesture.delaysTouchesEnded = false
            mapView.addGestureRecognizer(panGesture)
            context.coordinator.panGestureRecognizer = panGesture
        } else if !activePinningMode && context.coordinator.panGestureRecognizer != nil {
            // Remove the gesture if needed
            if let panGesture = context.coordinator.panGestureRecognizer {
                mapView.removeGestureRecognizer(panGesture)
                context.coordinator.panGestureRecognizer = nil
            }
        }
        
        // Report the current center coordinate when in pinning mode
        if activePinningMode {
            onMapMoved?(mapView.centerCoordinate)
            
            // Start coordinate tracking if not already
            if !context.coordinator.isTrackingCoordinates {
                context.coordinator.startCoordinateTracking(mapView)
            }
        } else {
            // Stop coordinate tracking if it was active
            if context.coordinator.isTrackingCoordinates {
                context.coordinator.stopCoordinateTracking()
            }
        }
    }
    
    // Add this method back to the RoutePlanMapView struct
    func makeCoordinator() -> Coordinator {
        // Define a stable ID for this view instance
        let viewID = "\(points.hashValue)-\(mapStyle.hashValue)-\(activePinningMode.hashValue)"
        
        // Check if we already have a coordinator for this view
        if let existingCoordinator = RoutePlanMapView.coordinatorHolder[viewID] {
            print("DEBUG: Reusing existing coordinator")
            return existingCoordinator
        }
        
        print("DEBUG: Creating new coordinator for ID: \(viewID)")
        let coordinator = Coordinator(self)
        RoutePlanMapView.coordinatorHolder[viewID] = coordinator
        return coordinator
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: RoutePlanMapView
        var firstUpdate: Bool? = true
        var activePinningMode: Bool = false
        var isTrackingCoordinates: Bool = false
        var displayLink: CADisplayLink?
        var mapViewRef: MKMapView?
        var panGestureRecognizer: UIPanGestureRecognizer?


        init(_ parent: RoutePlanMapView) {
            self.parent = parent
            super.init()
        }
        
        @objc func centerOnCurrentLocation(_ sender: UIButton) {
            print("DEBUG: centerOnCurrentLocation called")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                     // Get the map view - force unwrap for debugging
                guard let mapView = self.mapViewRef else {
                print("DEBUG: mapViewRef is nil")
                return
            }
            
            // Get user location
            let userLocation = mapView.userLocation
            
            // Check if we have a valid user location
            if let location = userLocation.location, CLLocationCoordinate2DIsValid(location.coordinate) {
                print("DEBUG: Setting region to user location: \(location.coordinate)")
                
                // Create a region around the user location
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 1000, // 1km zoom
                    longitudinalMeters: 1000
                )
                
                // Set the map region with animation and force UI update
                mapView.setRegion(region, animated: true)
                
                // Force layout update in case animation doesn't trigger properly
                DispatchQueue.main.async {
                    mapView.layoutIfNeeded()
                }
            } else {
                print("DEBUG: User location not available or invalid")
                
                // If user location isn't available, at least center on first annotation
                if let firstAnnotation = mapView.annotations.first(where: { !($0 is MKUserLocation) }) {
                    print("DEBUG: Centering on first annotation instead")
                    mapView.setCenter(firstAnnotation.coordinate, animated: true)
                }
            }
        }
        }

        @objc func fitAnnotations(_ sender: UIButton) {
            print("DEBUG: fitAnnotations called")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                         // Get the map view
                guard let mapView = self.mapViewRef else {
                    print("DEBUG: mapViewRef is nil")
                    return
                }
                
                // Get all annotations except the user location annotation
                let annotations = mapView.annotations.filter { !($0 is MKUserLocation) }
                
                // Make sure we have at least one annotation
                guard !annotations.isEmpty else {
                    print("DEBUG: No annotations to fit")
                    return
                }
                
                print("DEBUG: Found \(annotations.count) annotations to fit")
                
                // Set the visible region to show all annotations with padding
                let padding = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
                if mapView.annotations.count > 1 {
                    // For multiple annotations, use showAnnotations with animation
                    mapView.showAnnotations(annotations, animated: true)
                    
                    // Force layout update
                    DispatchQueue.main.async {
                        mapView.layoutIfNeeded()
                    }
                } else if let annotation = annotations.first {
                    // For a single annotation, just center on it with appropriate zoom
                    let coordinate = annotation.coordinate
                    let region = MKCoordinateRegion(
                        center: coordinate,
                        latitudinalMeters: 1000,
                        longitudinalMeters: 1000
                    )
                    mapView.setRegion(region, animated: true)
                    
                    // Force layout update
                    DispatchQueue.main.async {
                        mapView.layoutIfNeeded()
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "RoutePoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = UIColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                markerView.glyphText = annotation.title ?? "•"
            }
            
            return annotationView
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard activePinningMode, let mapView = gesture.view as? MKMapView else { return }
            
            // Only allow moving the map, not interacting with annotations
            if gesture.state == .ended {
                let centerCoordinate = mapView.centerCoordinate
                parent.onLocationSelected?(centerCoordinate)
            }
        }
        
        // MARK: - Gesture Recognizer Delegate Methods
        
        // This method tells the gesture system to not handle touches on buttons
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // If touch is on a button, don't let the gesture recognizer handle it
            if let touchView = touch.view, (touchView is UIButton || touchView.superview is UIButton) {
                return false
            }
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Don't compete with button touch handlers
            if otherGestureRecognizer.view is UIButton || otherGestureRecognizer.view?.superview is UIButton {
                return false
            }
            return true
        }
        
        // Track coordinates in real-time using CADisplayLink
        func startCoordinateTracking(_ mapView: MKMapView) {
            mapViewRef = mapView
            displayLink = CADisplayLink(target: self, selector: #selector(updateCoordinates))
            displayLink?.add(to: .main, forMode: .common)
            isTrackingCoordinates = true
        }
        
        func stopCoordinateTracking() {
            displayLink?.invalidate()
            displayLink = nil
            isTrackingCoordinates = false
        }
        
        @objc func updateCoordinates() {
            guard let mapView = mapViewRef, activePinningMode else { return }
            parent.onMapMoved?(mapView.centerCoordinate)
        }
    }
}
