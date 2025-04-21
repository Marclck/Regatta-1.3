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

// MARK: - Custom Distance Annotation
class DistanceAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var offsetFromLine: CGFloat = 20.0  // Offset distance from the route line
    
    init(coordinate: CLLocationCoordinate2D, distance: Double) {
        self.coordinate = coordinate
        self.title = String(format: "%.1f NM", distance)
        super.init()
    }
}

// MARK: - Route Planning Map View
struct RoutePlanMapView: UIViewRepresentable {
    var points: [PlanPoint]
    var mapStyle: MapStyleConfiguration
    var activePinningMode: Bool // Keeping parameter for compatibility but now ignored
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
        
        // Always add the pan gesture regardless of pinning mode
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        panGesture.cancelsTouchesInView = false
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        mapView.addGestureRecognizer(panGesture)
        context.coordinator.panGestureRecognizer = panGesture
        
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
            locationButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 60),
            locationButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8),
            locationButton.widthAnchor.constraint(equalToConstant: 40),
            locationButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Zoom button constraints
            zoomButton.topAnchor.constraint(equalTo: locationButton.bottomAnchor, constant: 12),
            zoomButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8),
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
            
            // Add distance annotations for each segment
            for i in 0..<(validPoints.count - 1) {
                // Calculate the distance for this segment
                let startPoint = validPoints[i]
                let endPoint = validPoints[i + 1]
                let segmentDistance = calculateDistanceInNauticalMiles(from: startPoint, to: endPoint)
                
                // Find midpoint of this segment with offset
                if let midpointCoordinate = findMidpointWithOffset(for: [startPoint, endPoint]) {
                    // Create distance annotation for this segment
                    let distanceAnnotation = DistanceAnnotation(coordinate: midpointCoordinate, distance: segmentDistance)
                    mapView.addAnnotation(distanceAnnotation)
                }
            }
            
            // Zoom to fit the route if needed
            if let firstUpdate = context.coordinator.firstUpdate, firstUpdate {
                context.coordinator.firstUpdate = false
                mapView.setVisibleMapRect(
                    polyline.boundingMapRect.insetBy(dx: -5000, dy: -5000),
                    animated: true
                )
            }
        }
        
        // Always track center coordinates regardless of pinning mode
        onMapMoved?(mapView.centerCoordinate)
        
        // Always track coordinates
        if !context.coordinator.isTrackingCoordinates {
            context.coordinator.startCoordinateTracking(mapView)
        }
    }
    
    // Function to calculate distance between two points in nautical miles
    private func calculateDistanceInNauticalMiles(from startPoint: PlanPoint, to endPoint: PlanPoint) -> Double {
        let start = CLLocation(latitude: startPoint.latitude, longitude: startPoint.longitude)
        let end = CLLocation(latitude: endPoint.latitude, longitude: endPoint.longitude)
        let distanceMeters = start.distance(from: end)
        
        // Convert meters to nautical miles (1 nautical mile = 1852 meters)
        return distanceMeters / 1852.0
    }
    
    // Function to calculate total route distance in nautical miles
    private func calculateTotalDistanceInNauticalMiles(points: [PlanPoint]) -> Double {
        guard points.count >= 2 else { return 0.0 }
        
        var totalDistanceMeters: CLLocationDistance = 0.0
        
        for i in 0..<(points.count - 1) {
            let start = CLLocation(latitude: points[i].latitude, longitude: points[i].longitude)
            let end = CLLocation(latitude: points[i + 1].latitude, longitude: points[i + 1].longitude)
            totalDistanceMeters += start.distance(from: end)
        }
        
        // Convert meters to nautical miles (1 nautical mile = 1852 meters)
        return totalDistanceMeters / 1852.0
    }
    
    // Function to find the midpoint of the route with a slight offset to avoid overlapping the line
    private func findMidpointWithOffset(for points: [PlanPoint]) -> CLLocationCoordinate2D? {
        guard points.count >= 2 else { return nil }
        
        // If we only have 2 points, find the midpoint of the line
        if points.count == 2 {
            // Calculate midpoint
            let midLat = (points[0].latitude + points[1].latitude) / 2.0
            let midLon = (points[0].longitude + points[1].longitude) / 2.0
            
            // Calculate perpendicular vector for offset
            let dx = points[1].longitude - points[0].longitude
            let dy = points[1].latitude - points[0].latitude
            
            // Normalize and perpendicular
            let length = sqrt(dx * dx + dy * dy)
            let offsetFactor = 0.0001 // Small coordinate offset, adjust as needed
            
            // Perpendicular offset to the right of the line
            let perpX = -dy / length * offsetFactor
            let perpY = dx / length * offsetFactor
            
            return CLLocationCoordinate2D(latitude: midLat + perpY, longitude: midLon + perpX)
        }
        
        // For more than 2 points, find approximate midpoint by distance
        var distanceSoFar: CLLocationDistance = 0.0
        var cumulativeDistances: [CLLocationDistance] = [0.0]
        
        // Calculate cumulative distances
        for i in 1..<points.count {
            let start = CLLocation(latitude: points[i-1].latitude, longitude: points[i-1].longitude)
            let end = CLLocation(latitude: points[i].latitude, longitude: points[i].longitude)
            distanceSoFar += start.distance(from: end)
            cumulativeDistances.append(distanceSoFar)
        }
        
        let totalDistance = distanceSoFar
        let midDistance = totalDistance / 2.0
        
        // Find the segment containing the midpoint
        for i in 1..<points.count {
            if cumulativeDistances[i-1] <= midDistance && cumulativeDistances[i] >= midDistance {
                // Interpolate within this segment
                let segmentLength = cumulativeDistances[i] - cumulativeDistances[i-1]
                let ratio = (midDistance - cumulativeDistances[i-1]) / segmentLength
                
                let startPoint = points[i-1]
                let endPoint = points[i]
                
                let midLat = startPoint.latitude + (endPoint.latitude - startPoint.latitude) * ratio
                let midLon = startPoint.longitude + (endPoint.longitude - startPoint.longitude) * ratio
                
                // Calculate perpendicular offset
                let dx = endPoint.longitude - startPoint.longitude
                let dy = endPoint.latitude - startPoint.latitude
                let length = sqrt(dx * dx + dy * dy)
                let offsetFactor = 0.0001 // Small coordinate offset, adjust as needed
                
                // Perpendicular offset to the right of the line
                let perpX = -dy / length * offsetFactor
                let perpY = dx / length * offsetFactor
                
                return CLLocationCoordinate2D(latitude: midLat + perpY, longitude: midLon + perpX)
            }
        }
        
        // Fallback to approximate center
        let midIndex = points.count / 2
        return points[midIndex].coordinate
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
        var activePinningMode: Bool = false // Keeping for compatibility but now ignored
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
                let annotations = mapView.annotations.filter { !($0 is MKUserLocation) && !($0 is DistanceAnnotation) }
                
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
            // Return nil for user location to use default blue dot
            if annotation is MKUserLocation {
                return nil
            }
            
            // Special handling for distance annotation
            if let distanceAnnotation = annotation as? DistanceAnnotation {
                // Use regular MKAnnotationView instead of MKMarkerAnnotationView for distance labels
                let identifier = "DistanceAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    // Create a plain annotation view without a pin
                    annotationView = MKAnnotationView(annotation: distanceAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false
                } else {
                    annotationView?.annotation = distanceAnnotation
                }
                
                // Create custom label for the distance
                let label = UILabel()
                label.text = distanceAnnotation.title
                label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                label.textColor = UIColor.white
                label.backgroundColor = UIColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                label.layer.cornerRadius = 8
                label.clipsToBounds = true
                label.textAlignment = .center
                label.sizeToFit()
                
                // Add padding
                let padding: CGFloat = 4
                let newFrame = CGRect(
                    x: -label.frame.width/2,
                    y: -label.frame.height/2,
                    width: label.frame.width + padding * 2,
                    height: label.frame.height + padding * 2
                )
                label.frame = newFrame
                label.textAlignment = .center
                
                // Clear any existing subviews and add the label
                annotationView?.subviews.forEach { $0.removeFromSuperview() }
                annotationView?.addSubview(label)
                
                // Set the frame for the annotation view to match the label size
                annotationView?.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: newFrame.width,
                    height: newFrame.height
                )
                
                return annotationView
            }
            
            // Regular route point annotation
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
            guard let mapView = gesture.view as? MKMapView else { return }
            
            // Always handle pan gestures and report center coordinates
            // Removed dependency on activePinningMode
            if gesture.state == .ended {
                let centerCoordinate = mapView.centerCoordinate
                parent.onMapMoved?(centerCoordinate)
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
            guard let mapView = mapViewRef else { return }
            // Always report coordinates regardless of pinning mode
            parent.onMapMoved?(mapView.centerCoordinate)
        }
    }
}
