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
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Route History")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
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
                    PlanDetailView(plan: plan, mapStyle: $mapStyleConfig)
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
    @Binding var mapStyle: MapStyleConfiguration
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
                            ForEach(MapStyleConfiguration.allCases) { style in
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
                        .padding(.bottom, 16)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Route Details")
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.semibold)
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

// MARK: - Preview Providers
#Preview("Plan History View") {
    PlanHistoryView()
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
                        ]
                    ),
                    RoutePlan(
                        date: Date().addingTimeInterval(-172800), // 2 days ago
                        points: [
                            PlanPoint(latitude: 34.0522, longitude: -118.2437, order: 0),
                            PlanPoint(latitude: 34.1184, longitude: -118.3004, order: 1),
                            PlanPoint(latitude: 33.9416, longitude: -118.4085, order: 2)
                        ]
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
            ]
        ),
        mapStyle: .constant(.standard)
    )
    .previewDisplayName("Plan Detail")
}
