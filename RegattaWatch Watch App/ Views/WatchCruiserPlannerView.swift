//
//  WatchCruisePlannerView.swift
//  RegattaWatch Watch App
//
//  Created on 18/03/2025.
//

import SwiftUI
import MapKit
import CoreLocation
import WatchKit
import Combine

// MARK: - Cruise Plan State Manager
class WatchCruisePlanState: ObservableObject {
    static let shared = WatchCruisePlanState()
    @ObservedObject var plannerManager = WatchPlannerDataManager.shared

    // Keys for UserDefaults
    private let isActiveKey = "cruisePlanIsActive"
    private let isPausedKey = "cruisePlanIsPaused"
    private let lastResetTimeKey = "cruisePlanLastResetTime"
    
    @Published var isActive: Bool = false {
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var isPaused: Bool = false {
        didSet {
            saveToUserDefaults()
        }
    }
    
    @Published var lastResetTime: Date? = nil {
        didSet {
            saveToUserDefaults()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // Private initializer for singleton
    private init() {
        // Load saved state from UserDefaults
        loadFromUserDefaults()
        
        // Observe changes in @Published properties to save to UserDefaults
        $isActive
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                self?.saveToUserDefaults()
            }
            .store(in: &cancellables)
        
        $isPaused
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                self?.saveToUserDefaults()
            }
            .store(in: &cancellables)
        
        $lastResetTime
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                self?.saveToUserDefaults()
            }
            .store(in: &cancellables)
    }
    
    var statusText: String {
        if isActive {
            return "\(plannerManager.currentPlanName) Plan Active"
        } else if isPaused {
            return "\(plannerManager.currentPlanName) Plan Paused"
        } else {
            return "\(plannerManager.currentPlanName) Loaded"
        }
    }
    
    var statusColor: Color {
        if isActive {
            return .green
        } else if isPaused {
            return .orange
        } else {
            return .white
        }
    }
    
    func startCruisePlan() {
        isActive = true
        isPaused = false
        saveToUserDefaults()
        HapticManager.shared.playConfirmFeedback()
    }
    
    func pauseCruisePlan() {
        isActive = false
        isPaused = true
        saveToUserDefaults()
        HapticManager.shared.playCancelFeedback()
    }
    
    func resetCruisePlan() {
        isActive = false
        isPaused = false
        lastResetTime = Date()
        saveToUserDefaults()
        HapticManager.shared.playFailureFeedback()
    }
    
    func toggleCruisePlan() {
        if isActive {
            pauseCruisePlan()
        } else {
            startCruisePlan()
        }
    }
    
    // Save state to UserDefaults
    private func saveToUserDefaults() {
        UserDefaults.standard.set(isActive, forKey: isActiveKey)
        UserDefaults.standard.set(isPaused, forKey: isPausedKey)
        if let lastReset = lastResetTime {
            UserDefaults.standard.set(lastReset, forKey: lastResetTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastResetTimeKey)
        }
    }
    
    // Load state from UserDefaults
    private func loadFromUserDefaults() {
        isActive = UserDefaults.standard.bool(forKey: isActiveKey)
        isPaused = UserDefaults.standard.bool(forKey: isPausedKey)
        lastResetTime = UserDefaults.standard.object(forKey: lastResetTimeKey) as? Date
    }
}

// MARK: - Watch Cruise Planner View
struct WatchCruisePlannerView: View {
    @ObservedObject var plannerManager = WatchPlannerDataManager.shared
    @ObservedObject var cruisePlanState = WatchCruisePlanState.shared
    @State private var selectedWaypoint: WatchPlanPoint? = nil
    @State private var showingMap: Bool = false
    @ObservedObject var activeWaypointManager = ActiveWaypointManager.shared

    // Helper function to scroll to active waypoint
    private func scrollToActiveWaypoint(proxy: ScrollViewProxy) {
        // Only scroll if cruise plan is active and we have an active waypoint
        if cruisePlanState.isActive,
           let activeWaypoint = activeWaypointManager.activeWaypoint {
            withAnimation {
                proxy.scrollTo(activeWaypoint.id, anchor: .center)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Status indicator
            if !plannerManager.currentPlan.isEmpty {
                
                Text(cruisePlanState.statusText)
                    .font(.caption2)
                    .dynamicTypeSize(.xSmall)
                    .foregroundColor(cruisePlanState.statusColor)
                    .padding(.top, 2)
                                
            // Cruise control buttons
                CruiseControlButtons(cruisePlanState: cruisePlanState)
                    .padding(.horizontal)
            }
            
            // Waypoint list
            ScrollViewReader { scrollProxy in
                List {
                    if plannerManager.currentPlan.isEmpty {
                        Text("No waypoints available")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .dynamicTypeSize(.xSmall)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(plannerManager.currentPlan) { waypoint in
                            WaypointRow(
                                waypoint: waypoint,
                                isActive: cruisePlanState.isActive &&
                                         activeWaypointManager.activeWaypoint?.id == waypoint.id
                            )
                            .listRowBackground(RoundedRectangle(cornerRadius: 15)
                                .fill(cruisePlanState.isActive &&
                                     activeWaypointManager.activeWaypoint?.id == waypoint.id ?
                                      Color.green.opacity(0.3) : Color.white.opacity(0.3))
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Open the waypoint in the native Maps app
                                let coordinate = CLLocationCoordinate2D(
                                    latitude: waypoint.latitude,
                                    longitude: waypoint.longitude
                                )
                                let placemark = MKPlacemark(coordinate: coordinate)
                                let mapItem = MKMapItem(placemark: placemark)
                                mapItem.name = "Waypoint \(waypoint.order + 1)"
                                mapItem.openInMaps()
                            }
                            .id(waypoint.id) // Add id to enable scrolling to this item
                        }
                    }
                    
                    if let lastUpdate = plannerManager.lastUpdateTime {
                        HStack {
                            Spacer()
                            Text("Last updated: \(timeAgoString(from: lastUpdate))")
                                .font(.caption2)
                                .dynamicTypeSize(.xSmall)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(CarouselListStyle())
                .onAppear {
                    scrollToActiveWaypoint(proxy: scrollProxy)
                }
                .onChange(of: activeWaypointManager.activeWaypoint) { _ in
                    scrollToActiveWaypoint(proxy: scrollProxy)
                }
                .onChange(of: cruisePlanState.isActive) { isActive in
                    if isActive {
                        scrollToActiveWaypoint(proxy: scrollProxy)
                    }
                }
            }
            .listStyle(CarouselListStyle())
        }
        .navigationTitle("Cruise Plan")
    }
    
    // Helper function to display time ago
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - Waypoint Map View Sheet
struct WaypointMapView: View {
    let waypoint: WatchPlanPoint
    @State private var mapRegion = MKCoordinateRegion()
    @State private var zoomLevel: Double = 0.0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Map
            WaypointMapViewRepresentable(waypoint: waypoint, mapRegion: $mapRegion)
                .focusable(true)
                .digitalCrownRotation(
                    $zoomLevel,
                    from: -5.0,
                    through: 5.0,
                    by: 0.1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: zoomLevel) { newValue in
                    handleZoom(delta: newValue)
                }
                .onAppear {
                    setInitialRegion()
                }
                
            // Waypoint info
            VStack(alignment: .leading) {
                Text("Waypoint \(waypoint.order + 1)")
                    .font(.headline)
                    .dynamicTypeSize(.xSmall)
                Text(waypoint.formattedCoordinates())
                    .font(.system(.caption, design: .monospaced))
                    .dynamicTypeSize(.xSmall)
            }
            .padding(.bottom)
        }
    }
    
    private func setInitialRegion() {
        let waypointCoordinate = CLLocationCoordinate2D(
            latitude: waypoint.latitude,
            longitude: waypoint.longitude
        )
        
        mapRegion = MKCoordinateRegion(
            center: waypointCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func handleZoom(delta: Double) {
        // Adjust map region based on zoom level
        var newRegion = mapRegion
        
        // Calculate zoom factor based on digital crown rotation
        let zoomFactor = 1.0 - (delta * 0.05)
        
        // Apply zoom to the region's span
        newRegion.span.latitudeDelta *= zoomFactor
        newRegion.span.longitudeDelta *= zoomFactor
        
        // Constrain zoom levels
        newRegion.span.latitudeDelta = min(max(newRegion.span.latitudeDelta, 0.001), 180)
        newRegion.span.longitudeDelta = min(max(newRegion.span.longitudeDelta, 0.001), 180)
        
        mapRegion = newRegion
    }
}

// MARK: - Waypoint Map View Representable
struct WaypointMapViewRepresentable: WKInterfaceObjectRepresentable {
    typealias WKInterfaceObjectType = WKInterfaceMap
    
    let waypoint: WatchPlanPoint
    @Binding var mapRegion: MKCoordinateRegion
    
    func makeWKInterfaceObject(context: Context) -> WKInterfaceMap {
        let map = WKInterfaceMap()
        
        // Enable user location and heading
        map.setShowsUserLocation(true)
        map.setShowsUserHeading(true)
        
        return map
    }
    
    func updateWKInterfaceObject(_ map: WKInterfaceMap, context: Context) {
        // Clear existing pins
        map.removeAllAnnotations()
        
        // Set the map region
        map.setRegion(mapRegion)
        
        // Add waypoint pin
        let coordinate = CLLocationCoordinate2D(
            latitude: waypoint.latitude,
            longitude: waypoint.longitude
        )
        map.addAnnotation(coordinate, with: .red)
        
        // Note: WKInterfaceMap doesn't support drawing lines between points
        // If lines are needed, we would need to use different technology
    }
}

// MARK: - Cruise Control Buttons
struct CruiseControlButtons: View {
    @ObservedObject var cruisePlanState: WatchCruisePlanState
    @EnvironmentObject var colorManager: ColorManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Left Button - Either Reset or Complete Segment based on isActive
            Button(action: {
                if cruisePlanState.isActive {
                    // Call the completeCurrentSegment function via notification
                    NotificationCenter.default.post(
                        name: Notification.Name("RequestSegmentCompletion"),
                        object: nil
                    )
                    HapticManager.shared.playConfirmFeedback()
                } else {
                    // Regular reset functionality when not active
                    cruisePlanState.resetCruisePlan()
                }
            }) {
                // Change icon and color based on active state
                if cruisePlanState.isActive {
                    // Green checkmark when active
                    Image(systemName: "checkmark")
                        .font(.system(size: 24))
                        .fontWeight(.heavy)
                        .dynamicTypeSize(.xSmall)
                        .symbolVariant(.fill)
                        .foregroundColor(.green)
                        .frame(width: 65, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color.green.opacity(0.4))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                } else {
                    // Orange reset icon when not active
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24))
                        .fontWeight(.heavy)
                        .dynamicTypeSize(.xSmall)
                        .symbolVariant(.fill)
                        .foregroundColor(Color.orange)
                        .frame(width: 65, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color.orange.opacity(0.4))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .buttonStyle(.plain)
            //            .buttonStyle(.glass)
//            .glassEffect(in: RoundedRectangle(cornerRadius: 40.0))
            .frame(width: 65, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 40.0))
//            .colorScheme(.light)
            
            // Start/Pause Button
            Button(action: {
                cruisePlanState.toggleCruisePlan()
            }) {
                Image(systemName: cruisePlanState.isActive ? "pause" : "play")
                    .font(.system(size: 24))
                    .fontWeight(.heavy)
                    .dynamicTypeSize(.xSmall)
                    .symbolVariant(.fill)
                    .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue))
                    .frame(width: 65, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.4))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
//            .buttonStyle(.glass)
//            .glassEffect(in: RoundedRectangle(cornerRadius: 40.0))
            .frame(width: 65, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 40.0))
//            .colorScheme(.light)
        }
    }
}

// MARK: - Previews
struct WatchCruisePlannerView_Previews: PreviewProvider {
    static var previews: some View {
        WatchCruisePlannerView()
            .environmentObject(ColorManager())
    }
}
