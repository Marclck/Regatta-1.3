//
//  PlannerMapSection.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

struct PlannerMapSection: View {
    @ObservedObject var planStore: RoutePlanStore
    @Binding var mapStyleConfig: MapStyleConfiguration
    @Binding var activePinningPoint: UUID?
    
    // For tracking the center coordinate of the map
    @State private var centerCoordinate: CLLocationCoordinate2D =
        CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    // Add a binding to notify parent of coordinate changes
    @Binding var externalCenterCoordinate: CLLocationCoordinate2D
    
    var body: some View {
        VStack(spacing: 0) {
            // Map style picker
            VStack {
                Picker("Map Style", selection: $mapStyleConfig) {
                    ForEach(MapStyleConfiguration.allCases) { style in
                        Text(style.name).tag(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            
            // Main map view - 1.5x height compared to JournalView
            ZStack {
                // Map with coordinate tracking
                RoutePlanMapView(
                    points: planStore.currentPlan,
                    mapStyle: mapStyleConfig,
                    activePinningMode: false, // Always false since we're not toggling pinning mode
                    onMapMoved: { coordinate in
                        // Update center coordinate as map moves
                        self.centerCoordinate = coordinate
                        // Also update external coordinate
                        self.externalCenterCoordinate = coordinate
                    },
                    onLocationSelected: { coordinate in
                        if let pointId = activePinningPoint {
                            planStore.updatePoint(
                                id: pointId,
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude,
                                accuracy: nil // Map taps don't have accuracy
                            )
                        }
                    }
                )
                .frame(height: 300) // 1.5x height compared to JournalView
                .cornerRadius(12)
                
                // Red crosshairs always displayed at the center of the map
                ZStack{
                    // Horizontal line
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 20, height: 2)
                    
                    // Vertical line
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 20)
                    
                    // Central circle
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Always display coordinates
            HStack {
                Spacer()
                Text(String(format: "(%.6f, %.6f)", centerCoordinate.latitude, centerCoordinate.longitude))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    PlannerMapSection(
        planStore: RoutePlanStore.shared,
        mapStyleConfig: .constant(.standard),
        activePinningPoint: .constant(UUID()),
        externalCenterCoordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0))
    )
    .background(Color.black)
}
