//
//  PlannerView.swift
//  Regatta
//
//  Created by Chikai Lai on 12/03/2025.
//

import Foundation
import SwiftUI
import MapKit

// MARK: - Main Planner View
struct PlannerView: View {
    @StateObject private var planStore = RoutePlanStore.shared
    @ObservedObject private var colorManager = ColorManager()
    
    @State private var mapStyleConfig: MapStyleConfiguration = .standard
    @State private var activePinningPoint: UUID?
    @State private var showHistory = false
    @State private var showSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
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
                    // Map Section - with red circle and coordinate display
                    PlannerMapSection(
                        planStore: planStore,
                        mapStyleConfig: $mapStyleConfig,
                        activePinningPoint: $activePinningPoint
                    )
                    
                    // Waypoints List Section
                    ScrollView {
                        PlannerWaypointsSection(
                            planStore: planStore,
                            activePinningPoint: $activePinningPoint,
                            showSaveConfirmation: $showSaveConfirmation
                        )
                    }
                    .animation(.easeInOut, value: planStore.currentPlan.count)
                }
                
                // Add a transparent overlay only when in pinning mode
                // This replaces the .onTapGesture approach
                if activePinningPoint != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            activePinningPoint = nil
                        }
                        .allowsHitTesting(true)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Planner")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showHistory = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12))
                            Text("History")
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
            .sheet(isPresented: $showHistory) {
                PlanHistoryView()
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
                PlanPoint(latitude: 37.7749, longitude: -122.4194, accuracy: nil, order: 0), // San Francisco
                PlanPoint(latitude: 37.8199, longitude: -122.4783, accuracy: nil, order: 1), // Golden Gate Bridge
                PlanPoint(latitude: 37.8716, longitude: -122.2727, accuracy: nil, order: 2)  // Berkeley
            ]
        }
}
