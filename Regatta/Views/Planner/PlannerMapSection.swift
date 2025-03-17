//
//  PlannerMapSection.swift
//  Regatta
//
//  Created by Chikai Lai on 13/03/2025.
//

import Foundation
import SwiftUI
import MapKit

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
    
    var body: some View {
        VStack(spacing: 0) {
            // Map style picker
            Picker("Map Style", selection: $mapStyleConfig) {
                ForEach(MapStyleConfiguration.allCases) { style in
                    Text(style.name).tag(style)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .materialBackground()

            
            // Main map view - 1.5x height compared to JournalView
            ZStack {
                
                // First layer: Semi-transparent overlay (when in pinning mode)
                if activePinningPoint != nil {
                    Color.black.opacity(0.3)
                        .cornerRadius(12)
                        .allowsHitTesting(false)
                }
                
                // Map with coordinate tracking
                RoutePlanMapView(
                    points: planStore.currentPlan,
                    mapStyle: mapStyleConfig,
                    activePinningMode: activePinningPoint != nil,
                    onMapMoved: { coordinate in
                        // Update center coordinate as map moves
                        self.centerCoordinate = coordinate
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
                .frame(height: 350) // 1.5x height compared to JournalView
                .cornerRadius(12)
                
                // Center pin indicator and red circle when in pinning mode
                if activePinningPoint != nil {
                    // Red circle at center of map
                    ZStack{
                        Circle()
                            .stroke(Color.red, lineWidth: 2)
                            .background(Circle().fill(Color.red.opacity(0.2)))
                            .frame(width: 20, height: 20)
                     
                        Circle()
                            .fill(Color.red)
                            .frame(width: 2, height: 2)
                        
                    }
                        
                    // The pin indicator
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
                    
                    /*
                    // Semi-transparent overlay
                    Color.black.opacity(0.3)
                        .cornerRadius(12)
                        .allowsHitTesting(false)
                     */
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Display coordinates when in pinning mode
            if activePinningPoint != nil {
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
}

#Preview {
    PlannerMapSection(
        planStore: RoutePlanStore.shared,
        mapStyleConfig: .constant(.standard),
        activePinningPoint: .constant(UUID())
    )
    .background(Color.black)
}
