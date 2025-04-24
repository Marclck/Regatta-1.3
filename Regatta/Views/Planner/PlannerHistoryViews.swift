//
//  PlannerHistoryViews.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI
import MapKit

// MARK: - Plan History View
struct PlanHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var planStore = RoutePlanStore.shared
    @State private var selectedPlan: RoutePlan?
    @State private var showPlanDetail = false
    @State private var mapStyleConfig: MapStyleConfiguration = .standard
    @State private var editingPlanId: UUID?
    @State private var showEditNameAlert = false
    
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
                        // Create a sorted array that we'll use for both display and deletion
                        let sortedPlans = planStore.savedPlans.sorted(by: { $0.date > $1.date })
                        
                        List {
                            ForEach(sortedPlans) { plan in
                                HStack {
                                    Button(action: {
                                        selectedPlan = plan
                                        showPlanDetail = true
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(plan.name)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                
                                                HStack {
                                                    Text(plan.formattedDateTime())
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.7))
                                                    
                                                    Text("•")
                                                        .foregroundColor(.white.opacity(0.7))
                                                    
                                                    Text("\(plan.points.count) waypoints")
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    
                                    // Edit name button
                                    Button(action: {
                                        editingPlanId = plan.id
                                        showEditNameAlert = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.leading, 8)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(
                                    Color.clear
                                        .background(.ultraThinMaterial)
                                        .environment(\.colorScheme, .dark)
                                )
                            }
                            .onDelete { indexSet in
                                // Get the IDs of plans to remove from the sorted array
                                let plansToRemove = indexSet.map { sortedPlans[$0].id }
                                
                                // Remove those plans from the original array
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
                .padding(.top, 1)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Route History")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Text("Close")
                                .font(.system(.subheadline))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPlanDetail, content: {
                if let plan = selectedPlan {
                    PlanDetailView(plan: plan, mapStyle: $mapStyleConfig)
                        .preferredColorScheme(.dark) // Ensure sheet is in dark mode
                }
            })
            .customRouteNameEditor(
                isPresented: $showEditNameAlert,
                planId: editingPlanId ?? UUID(),
                initialName: planStore.savedPlans.first(where: { $0.id == editingPlanId })?.name ?? "",
                onSave: { planId, newName in
                    planStore.updatePlanName(id: planId, newName: newName)
                }
            )
        }
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark) // Add this line to ensure system-wide dark mode
    }
}

// MARK: - Plan Detail View
struct PlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let plan: RoutePlan
    @Binding var mapStyle: MapStyleConfiguration
    @ObservedObject private var planStore = RoutePlanStore.shared
    @State private var showEditNameAlert = false
    @State private var localPlanName: String
    @State private var totalDistance: Double = 0.0

    init(plan: RoutePlan, mapStyle: Binding<MapStyleConfiguration>) {
        self.plan = plan
        self._mapStyle = mapStyle
        self._localPlanName = State(initialValue: plan.name)
    }
    
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
                        // Route name with edit button
                        HStack {
                            Text(localPlanName)
                                .font(.title2)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            
                            Button(action: {
                                showEditNameAlert = true
                            }) {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Date, waypoint count, and total distance
                        HStack {
                            Text(plan.formattedDateTime())
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(plan.points.count) waypoints")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if totalDistance > 0 {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(String(format: "%.1f NM total", totalDistance))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .onAppear {
                            // Calculate total distance on appear
                            totalDistance = calculateTotalDistanceInNauticalMiles(points: plan.points)
                        }
                        
                        // Map style picker
                        Picker("Map Style", selection: $mapStyle) {
                            ForEach(MapStyleConfiguration.allCases) { style in
                                Text(style.name).tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .materialBackground()
                        .environment(\.colorScheme, .dark) // Ensure picker is in dark mode
                        
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
            
                       Button(action: {
                           planStore.loadPlanWithWatch(plan)
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
            
                        // Waypoints list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Waypoints")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            
                            let sortedPoints = plan.points.sorted(by: { $0.order < $1.order })
                            
                            ForEach(0..<sortedPoints.count, id: \.self) { index in
                                let point = sortedPoints[index]
                                
                                VStack(alignment: .leading, spacing: 4) {
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
                                    
                                    // Display segment distance if not the first point
                                    if index > 0 {
                                        let prevPoint = sortedPoints[index - 1]
                                        let distance = calculateDistanceInNauticalMiles(from: prevPoint, to: point)
                                        
                                        Text(String(format: "Distance from previous: %.1f NM", distance))
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(Color(hex: ColorTheme.ultraBlue.rawValue))
                                            .padding(.leading, 32)
                                    }
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
                        .environment(\.colorScheme, .dark) // Ensure material background is in dark mode
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .padding(.top, 1)
                }
                .padding(.top, 1)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Route Details")
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Text("Close")
                                .font(.system(.subheadline))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .customRouteNameEditor(
                isPresented: $showEditNameAlert,
                planId: plan.id,
                initialName: localPlanName,
                onSave: { planId, newName in
                    // Update local state
                    localPlanName = newName
                    // Update the plan in the store
                    planStore.updatePlanName(id: planId, newName: newName)
                }
            )
        }
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark) // Add this line to ensure system-wide dark mode
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
        
        // Sort points by order
        let sortedPoints = points.sorted(by: { $0.order < $1.order })
        
        var totalDistanceMeters: CLLocationDistance = 0.0
        
        for i in 0..<(sortedPoints.count - 1) {
            let start = CLLocation(latitude: sortedPoints[i].latitude, longitude: sortedPoints[i].longitude)
            let end = CLLocation(latitude: sortedPoints[i + 1].latitude, longitude: sortedPoints[i + 1].longitude)
            totalDistanceMeters += start.distance(from: end)
        }
        
        // Convert meters to nautical miles (1 nautical mile = a.1852 meters)
        return totalDistanceMeters / 1852.0
    }
}

// MARK: - Preview Providers
#Preview("Plan History View") {
    PlanHistoryView()
        .preferredColorScheme(.dark) // Ensure preview is in dark mode
        .previewDisplayName("History View")
        .onAppear {
            // Set up sample history for preview
            let store = RoutePlanStore.shared
            if store.savedPlans.isEmpty {
                store.savedPlans = [
                    RoutePlan(
                        date: Date().addingTimeInterval(-86400), // Yesterday
                        points: [
                            PlanPoint(latitude: 37.7749, longitude: -122.4194, order: 0),
                            PlanPoint(latitude: 37.8199, longitude: -122.4783, order: 1)
                        ],
                        name: "Golden Gate Bridge Tour"
                    ),
                    RoutePlan(
                        date: Date().addingTimeInterval(-172800), // 2 days ago
                        points: [
                            PlanPoint(latitude: 34.0522, longitude: -118.2437, order: 0),
                            PlanPoint(latitude: 34.1184, longitude: -118.3004, order: 1),
                            PlanPoint(latitude: 33.9416, longitude: -118.4085, order: 2)
                        ],
                        name: "LA Harbor Tour"
                    )
                ]
            }
        }
}

#Preview("Plan Detail") {
    PlanDetailView(
        plan: RoutePlan(
            date: Date(),
            points: [
                PlanPoint(latitude: 37.7749, longitude: -122.4194, order: 0), // San Francisco
                PlanPoint(latitude: 37.8199, longitude: -122.4783, order: 1), // Golden Gate Bridge
                PlanPoint(latitude: 37.8716, longitude: -122.2727, order: 2)  // Berkeley
            ],
            name: "San Francisco Bay Tour"
        ),
        mapStyle: .constant(.standard)
    )
    .preferredColorScheme(.dark) // Ensure preview is in dark mode
    .previewDisplayName("Plan Detail")
}
