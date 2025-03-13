//
//  PlannerView.swift
//  Regatta
//
//  Created by Chikai Lai on 12/03/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

// MARK: - Location Plan Models
struct PlanPoint: Identifiable, Codable, Equatable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var order: Int
    
    init(id: UUID = UUID(), latitude: Double, longitude: Double, order: Int) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.order = order
    }
    
    var locationData: LocationData {
        LocationData(latitude: latitude, longitude: longitude)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func == (lhs: PlanPoint, rhs: PlanPoint) -> Bool {
        lhs.id == rhs.id
    }
}

struct RoutePlan: Identifiable, Codable {
    let id: UUID
    let date: Date
    var points: [PlanPoint]
    
    init(id: UUID = UUID(), date: Date = Date(), points: [PlanPoint]) {
        self.id = id
        self.date = date
        self.points = points
    }
    
    // Format date and time for display
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Route Plan Store
class RoutePlanStore: ObservableObject {
    static let shared = RoutePlanStore()
    
    @Published var currentPlan: [PlanPoint] = []
    @Published var savedPlans: [RoutePlan] = []
    @Published var isPlanSaved: Bool = true
    
    private let planStorageKey = "savedRoutePlans"
    
    init() {
        loadSavedPlans()
        
        // Initialize with 3 empty points
        if currentPlan.isEmpty {
            resetCurrentPlan()
        }
    }
    
    func resetCurrentPlan() {
        currentPlan = [
            PlanPoint(latitude: 0.0, longitude: 0.0, order: 0),
            PlanPoint(latitude: 0.0, longitude: 0.0, order: 1),
            PlanPoint(latitude: 0.0, longitude: 0.0, order: 2)
        ]
        isPlanSaved = true
    }
    
    func addPoint() {
        let newOrder = currentPlan.count
        currentPlan.append(PlanPoint(latitude: 0.0, longitude: 0.0, order: newOrder))
        isPlanSaved = false
    }
    
    func removePoint(at index: Int) {
        if index < currentPlan.count {
            currentPlan.remove(at: index)
            
            // Update order for remaining points
            for i in 0..<currentPlan.count {
                currentPlan[i].order = i
            }
            
            isPlanSaved = false
        }
    }
    
    func updatePoint(id: UUID, latitude: Double, longitude: Double) {
        if let index = currentPlan.firstIndex(where: { $0.id == id }) {
            currentPlan[index].latitude = latitude
            currentPlan[index].longitude = longitude
            isPlanSaved = false
        }
    }
    
    func reorderPoints(fromIndex: Int, toIndex: Int) {
        if fromIndex != toIndex && fromIndex < currentPlan.count && toIndex < currentPlan.count {
            let movedItem = currentPlan.remove(at: fromIndex)
            currentPlan.insert(movedItem, at: toIndex)
            
            // Update order for all points
            for i in 0..<currentPlan.count {
                currentPlan[i].order = i
            }
            
            isPlanSaved = false
        }
    }
    
    func savePlan() {
        // Filter out empty points (lat & lng both 0)
        let validPoints = currentPlan.filter { !(abs($0.latitude) < 0.0001 && abs($0.longitude) < 0.0001) }
        
        // Only save if there are valid points
        if !validPoints.isEmpty {
            let newPlan = RoutePlan(points: validPoints)
            savedPlans.append(newPlan)
            isPlanSaved = true
            
            // Persist to storage
            savePlansToStorage()
        }
    }
    
    func loadPlan(_ plan: RoutePlan) {
        currentPlan = plan.points
        isPlanSaved = true
    }
    
    private func savePlansToStorage() {
        if let encoded = try? JSONEncoder().encode(savedPlans) {
            UserDefaults.standard.set(encoded, forKey: planStorageKey)
        }
    }
    
    private func loadSavedPlans() {
        if let data = UserDefaults.standard.data(forKey: planStorageKey),
           let decoded = try? JSONDecoder().decode([RoutePlan].self, from: data) {
            savedPlans = decoded
        }
    }
}

// MARK: - Map Style Selector
enum MapStyle: Int, CaseIterable, Identifiable {
    case standard
    case satellite
    case hybrid
    
    var id: Int { self.rawValue }
    
    var name: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        }
    }
    
    var mapType: MKMapType {
        switch self {
        case .standard: return .standard
        case .satellite: return .satellite
        case .hybrid: return .hybrid
        }
    }
}

// MARK: - Route Planning Map View
struct RoutePlanMapView: UIViewRepresentable {
    var points: [PlanPoint]
    var mapStyle: MapStyle
    var activePinningMode: Bool
    var onLocationSelected: ((CLLocationCoordinate2D) -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = mapStyle.mapType
        
        // Add gesture recognizer for pinning mode
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map type
        mapView.mapType = mapStyle.mapType
        
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Add route points as annotations
        let validPoints = points.filter { !(abs($0.latitude) < 0.0001 && abs($0.longitude) < 0.0001) }
        
        let annotations = validPoints.map { point -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = point.coordinate
            annotation.title = "Point \(point.order + 1)"
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
        context.coordinator.activePinningMode = activePinningMode
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: RoutePlanMapView
        var firstUpdate: Bool? = true
        var activePinningMode: Bool = false
        
        init(_ parent: RoutePlanMapView) {
            self.parent = parent
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
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

// MARK: - Location Point Editor
struct LocationPointEditor: View {
    @Binding var point: PlanPoint
    @State private var latitudeText: String
    @State private var longitudeText: String
    @State private var isPinningActive: Bool = false
    
    let index: Int
    let onDelete: () -> Void
    let onStartPinning: () -> Void
    let onStopPinning: () -> Void
    
    init(point: Binding<PlanPoint>, index: Int, onDelete: @escaping () -> Void, onStartPinning: @escaping () -> Void, onStopPinning: @escaping () -> Void) {
        self._point = point
        self.index = index
        self.onDelete = onDelete
        self.onStartPinning = onStartPinning
        self.onStopPinning = onStopPinning
        
        // Initialize text fields with current values
        self._latitudeText = State(initialValue: String(format: "%.6f", point.wrappedValue.latitude))
        self._longitudeText = State(initialValue: String(format: "%.6f", point.wrappedValue.longitude))
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Point number
            Text("\(index + 1)")
                .font(.system(.headline))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color(hex: ColorTheme.ultraBlue.rawValue)))
            
            // Coordinate fields
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Lat:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(.caption, design: .monospaced))
                    
                    TextField("0.000000", text: $latitudeText)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: latitudeText) { _, newValue in
                            if let newLat = Double(newValue) {
                                point.latitude = newLat
                            }
                        }
                }
                
                HStack {
                    Text("Lng:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(.caption, design: .monospaced))
                    
                    TextField("0.000000", text: $longitudeText)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: longitudeText) { _, newValue in
                            if let newLng = Double(newValue) {
                                point.longitude = newLng
                            }
                        }
                }
            }
            .padding(.horizontal, 4)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Pin on map button
                Button(action: {
                    isPinningActive.toggle()
                    if isPinningActive {
                        onStartPinning()
                    } else {
                        onStopPinning()
                    }
                }) {
                    Image(systemName: "mappin")
                        .foregroundColor(isPinningActive ? Color(hex: ColorTheme.signalOrange.rawValue) : .white.opacity(0.7))
                }
                
                // Copy coordinates button
                Button(action: {
                    UIPasteboard.general.string = "\(point.latitude),\(point.longitude)"
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Reorder handle
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white.opacity(0.7))
            }
            .font(.system(size: 16))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - Plan History View
struct PlanHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var planStore = RoutePlanStore.shared
    @State private var selectedPlan: RoutePlan?
    @State private var showPlanDetail = false
    @State private var mapStyle: MapStyle = .standard
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: ColorManager().selectedTheme.rawValue), location: 0.0),
                        .init(color: Color.black, location: 0.3),
                        .init(color: Color.black, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                VStack {
                    if planStore.savedPlans.isEmpty {
                        VStack {
                            Text("No saved route plans")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Text("Create a plan to see it here")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 4)
                        }
                        .padding(.top, 50)
                    } else {
                        List {
                            ForEach(planStore.savedPlans.sorted(by: { $0.date > $1.date })) { plan in
                                Button(action: {
                                    selectedPlan = plan
                                    showPlanDetail = true
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(plan.formattedDateTime())
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text("\(plan.points.count) waypoints")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(
                                    Color.clear
                                        .background(.ultraThinMaterial)
                                        .environment(\.colorScheme, .dark)
                                )
                            }
                            .onDelete { indexSet in
                                // Remove the plans at the specified indices
                                var plansToRemove: [UUID] = []
                                for index in indexSet {
                                    plansToRemove.append(planStore.savedPlans[index].id)
                                }
                                planStore.savedPlans.removeAll { plan in
                                    plansToRemove.contains(plan.id)
                                }
                                // Save changes
                                UserDefaults.standard.set(try? JSONEncoder().encode(planStore.savedPlans), forKey: "savedRoutePlans")
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Route History")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPlanDetail, content: {
                if let plan = selectedPlan {
                    PlanDetailView(plan: plan, mapStyle: $mapStyle)
                }
            })
        }
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Plan Detail View
struct PlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let plan: RoutePlan
    @Binding var mapStyle: MapStyle
    @ObservedObject private var planStore = RoutePlanStore.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: ColorManager().selectedTheme.rawValue), location: 0.0),
                        .init(color: Color.black, location: 0.3),
                        .init(color: Color.black, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Map style picker
                        Picker("Map Style", selection: $mapStyle) {
                            ForEach(MapStyle.allCases) { style in
                                Text(style.name).tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .materialBackground()
                        
                        // Map view
                        RoutePlanMapView(
                            points: plan.points,
                            mapStyle: mapStyle,
                            activePinningMode: false,
                            onLocationSelected: nil
                        )
                        .frame(height: 350)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Waypoints list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Waypoints")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(plan.points.sorted(by: { $0.order < $1.order })) { point in
                                HStack {
                                    Text("\(point.order + 1)")
                                        .font(.system(.headline))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color(hex: ColorTheme.ultraBlue.rawValue)))
                                    
                                    Text(String(format: "Lat: %.6f, Lng: %.6f", point.latitude, point.longitude))
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.3))
                                )
                                .padding(.horizontal)
                            }
                        }
                        .materialBackground()
                        .padding(.horizontal)
                        
                        Button(action: {
                            planStore.loadPlan(plan)
                            dismiss()
                        }) {
                            Text("Load This Plan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: ColorTheme.ultraBlue.rawValue))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Route Details")
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Main Planner View
struct PlannerView: View {
    @StateObject private var planStore = RoutePlanStore.shared
    @ObservedObject private var colorManager = ColorManager()
    
    @State private var mapStyle: MapStyle = .standard
    @State private var activePinningPoint: UUID?
    @State private var showHistory = false
    @State private var showSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background - IMPORTANT: This must be the first element in the ZStack
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: colorManager.selectedTheme.rawValue), location: 0.0),
                        .init(color: Color.black, location: 0.3),
                        .init(color: Color.black, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Map style picker
                    Picker("Map Style", selection: $mapStyle) {
                        ForEach(MapStyle.allCases) { style in
                            Text(style.name).tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .materialBackground()
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Main map view - 1.5x height compared to JournalView
                    ZStack {
                        RoutePlanMapView(
                            points: planStore.currentPlan,
                            mapStyle: mapStyle,
                            activePinningMode: activePinningPoint != nil,
                            onLocationSelected: { coordinate in
                                if let pointId = activePinningPoint {
                                    planStore.updatePoint(
                                        id: pointId,
                                        latitude: coordinate.latitude,
                                        longitude: coordinate.longitude
                                    )
                                    
                                    // Update the text fields indirectly
                                    if let index = planStore.currentPlan.firstIndex(where: { $0.id == pointId }) {
                                        // This will be handled by the bindings in LocationPointEditor
                                    }
                                }
                            }
                        )
                        .frame(height: 350) // 1.5x height compared to JournalView
                        .cornerRadius(12)
                        
                        // Center pin indicator when in pinning mode
                        if activePinningPoint != nil {
                            VStack {
                                Spacer()
                                Image(systemName: "mappin")
                                    .font(.system(size: 30))
                                    .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
                                Text("Tap to place pin")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .padding(.bottom, 80)
                            }
                            
                            // Semi-transparent overlay
                            Color.black.opacity(0.3)
                                .cornerRadius(12)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Points list
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("Waypoints")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            // Draggable list of points
                            ForEach(Array(planStore.currentPlan.enumerated()), id: \.element.id) { index, _ in
                                LocationPointEditor(
                                    point: Binding(
                                        get: { planStore.currentPlan[index] },
                                        set: { planStore.currentPlan[index] = $0 }
                                    ),
                                    index: index,
                                    onDelete: {
                                        planStore.removePoint(at: index)
                                    },
                                    onStartPinning: {
                                        activePinningPoint = planStore.currentPlan[index].id
                                    },
                                    onStopPinning: {
                                        activePinningPoint = nil
                                    }
                                )
                                .padding(.horizontal)
                                .draggable(planStore.currentPlan[index]) {
                                    // Preview for dragging
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.system(.headline))
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                            .background(Circle().fill(Color(hex: ColorTheme.ultraBlue.rawValue)))
                                        
                                        Text("Waypoint \(index + 1)")
                                            .foregroundColor(.white)
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.black.opacity(0.7))
                                    )
                                }
                                .dropDestination(for: PlanPoint.self) { items, location in
                                    guard let droppedItem = items.first,
                                          let fromIndex = planStore.currentPlan.firstIndex(where: { $0.id == droppedItem.id }),
                                          fromIndex != index else {
                                        return false
                                    }
                                    
                                    // Perform the reordering
                                    planStore.reorderPoints(fromIndex: fromIndex, toIndex: index)
                                    return true
                                }
                            }
                            
                            // Add waypoint button (if less than 12 points)
                            if planStore.currentPlan.count < 12 {
                                Button(action: {
                                    planStore.addPoint()
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Waypoint")
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.5))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Bottom action buttons
                            HStack {
                                // Clear button
                                Button(action: {
                                    planStore.resetCurrentPlan()
                                }) {
                                    Text("Clear")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: ColorTheme.signalOrange.rawValue))
                                        .cornerRadius(12)
                                }
                                
                                // Save button
                                Button(action: {
                                    planStore.savePlan()
                                    showSaveConfirmation = true
                                    
                                    // Hide the confirmation after 1.5 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        showSaveConfirmation = false
                                    }
                                }) {
                                    Text(showSaveConfirmation ? "Saved!" : "Save")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            showSaveConfirmation
                                                ? Color.green
                                                : (planStore.isPlanSaved ? Color.white : Color.white)
                                        )
                                        .cornerRadius(12)
                                }
                                .disabled(planStore.isPlanSaved && !showSaveConfirmation)
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                        }
                        .materialBackground()
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .animation(.easeInOut, value: planStore.currentPlan.count)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Planner")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showHistory = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("History")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showHistory) {
                PlanHistoryView()
            }
            .onTapGesture {
                // Cancel pinning mode if tapping outside map
                if activePinningPoint != nil {
                    activePinningPoint = nil
                }
            }
            .onAppear {
                // Load saved plans when view appears
                if planStore.savedPlans.isEmpty {
                    if let data = UserDefaults.standard.data(forKey: "savedRoutePlans"),
                       let decoded = try? JSONDecoder().decode([RoutePlan].self, from: data) {
                        planStore.savedPlans = decoded
                    }
                }
            }
        }
    }
}

// MARK: - Preview for PlannerView
#Preview("Planner View") {
    PlannerView()
        .previewDisplayName("Planner View")
        .onAppear {
            // Set up some sample points for preview
            let store = RoutePlanStore.shared
            store.currentPlan = [
                PlanPoint(latitude: 37.7749, longitude: -122.4194, order: 0), // San Francisco
                PlanPoint(latitude: 37.8199, longitude: -122.4783, order: 1), // Golden Gate Bridge
                PlanPoint(latitude: 37.8716, longitude: -122.2727, order: 2)  // Berkeley
            ]
        }
}
