//
//  PlannerModels.swift
//  Regatta
//
//  Created by Chikai Lai on 17/03/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import UniformTypeIdentifiers

// MARK: - Location Plan Models
struct PlanPoint: Identifiable, Codable, Equatable, Transferable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var accuracy: Double?
    var order: Int
    
    init(id: UUID = UUID(), latitude: Double, longitude: Double, accuracy: Double? = nil, order: Int) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.order = order
    }
    
    var asLocationData: LocationData {
        LocationData(latitude: latitude, longitude: longitude, accuracy: accuracy ?? 0.0)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func == (lhs: PlanPoint, rhs: PlanPoint) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Transferable conformance
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .planPoint)
    }
}

extension PlanPoint: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(order)
    }
}

// MARK: - UTType Extension for PlanPoint
extension UTType {
    static var planPoint: UTType {
        UTType(exportedAs: "com.regatta.planpoint")
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
    
    func removePointById(_ id: UUID) {
        // Only proceed if we have more than one point (always keep at least one)
        if currentPlan.count > 1 {
            // Find the index of the point with the given id
            if let indexToRemove = currentPlan.firstIndex(where: { $0.id == id }) {
                // Don't remove the first point (index 0)
                if indexToRemove > 0 {
                    // Make a copy of the current plan to avoid modification during iteration
                    var updatedPlan = currentPlan
                    
                    // Remove the point at the found index
                    updatedPlan.remove(at: indexToRemove)
                    
                    // Update order for remaining points
                    for i in 0..<updatedPlan.count {
                        updatedPlan[i].order = i
                    }
                    
                    // Update the published property with the new array
                    currentPlan = updatedPlan
                    isPlanSaved = false
                }
            }
        }
    }
    
    func resetCurrentPlan() {
        currentPlan = [
            PlanPoint(latitude: 0.0, longitude: 0.0, accuracy: nil, order: 0),
            PlanPoint(latitude: 0.0, longitude: 0.0, accuracy: nil, order: 1),
            PlanPoint(latitude: 0.0, longitude: 0.0, accuracy: nil, order: 2)
        ]
        isPlanSaved = true
    }
    
    func addPoint() {
        let newOrder = currentPlan.count
        currentPlan.append(PlanPoint(latitude: 0.0, longitude: 0.0, accuracy: nil, order: newOrder))
        isPlanSaved = false
    }
    
    func removePoint(at index: Int) {
        // Only proceed if index is valid and not the first point
        if index > 0 && index < currentPlan.count && currentPlan.count > 1 {
            // Get the ID of the point to remove
            let pointId = currentPlan[index].id
            
            // Use our safer method
            removePointById(pointId)
        }
    }
    
    func updatePoint(id: UUID, latitude: Double, longitude: Double, accuracy: Double? = nil) {
        if let index = currentPlan.firstIndex(where: { $0.id == id }) {
            currentPlan[index].latitude = latitude
            currentPlan[index].longitude = longitude
            currentPlan[index].accuracy = accuracy
            isPlanSaved = false
        }
    }
    
    func reorderPoints(fromIndex: Int, toIndex: Int) {
        // Ensure indices are valid
        guard fromIndex >= 0, fromIndex < currentPlan.count,
              toIndex >= 0, toIndex < currentPlan.count,
              fromIndex != toIndex else {
            return
        }
        
        // Get the item to move
        let item = currentPlan[fromIndex]
        
        // Remove the item from its original position
        currentPlan.remove(at: fromIndex)
        
        // Insert it at the new position
        currentPlan.insert(item, at: toIndex)
        
        // Update order properties if needed
        for (index, var point) in currentPlan.enumerated() {
            point.order = index
            currentPlan[index] = point
        }
        
        // Notify observers that the plan has changed
        objectWillChange.send()
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

// MARK: - Location Point Editor
struct LocationPointEditor: View {
    @Binding var point: PlanPoint
    let index: Int
    let onDelete: () -> Void
    let onStartPinning: () -> Void
    let onStopPinning: () -> Void
    
    // Use computed properties instead of State variables
    private var latitudeText: Binding<String> {
        Binding<String>(
            get: { String(format: "%.6f", point.latitude) },
            set: { newValue in
                if let newLat = Double(newValue) {
                    point.latitude = newLat
                }
            }
        )
    }
    
    private var longitudeText: Binding<String> {
        Binding<String>(
            get: { String(format: "%.6f", point.longitude) },
            set: { newValue in
                if let newLng = Double(newValue) {
                    point.longitude = newLng
                }
            }
        )
    }
    
    @State private var isPinningActive: Bool = false
    @FocusState private var isLatitudeFocused: Bool
    @FocusState private var isLongitudeFocused: Bool
    
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
                    
                    TextField("0.000000", text: latitudeText)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .focused($isLatitudeFocused)
                        .font(.system(.caption, design: .monospaced))
                }
                
                HStack {
                    Text("Lng:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(.caption, design: .monospaced))
                    
                    TextField("0.000000", text: longitudeText)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .focused($isLongitudeFocused)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .padding(.horizontal, 4)
            .dismissKeyboardOnTap()
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isLatitudeFocused = false
                        isLongitudeFocused = false
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Delete button - only show if not the first waypoint
                if index > 0 {
                    Button {
                        // Wrap in a DispatchQueue.main.async to ensure UI state is fully updated
                        DispatchQueue.main.async {
                            onDelete()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.7))
                    }
                } else {
                    // Placeholder to maintain spacing when no delete button
                    Image(systemName: "trash")
                        .foregroundColor(.clear)
                        .opacity(0)
                }
                
                Spacer()
                
                // Pin on map button
                Button {
                    isPinningActive.toggle()
                    if isPinningActive {
                        // Wrap in a DispatchQueue.main.async to ensure UI state is fully updated
                        DispatchQueue.main.async {
                            onStartPinning()
                        }
                    } else {
                        DispatchQueue.main.async {
                            onStopPinning()
                        }
                    }
                } label: {
                    Image(systemName: "mappin")
                        .foregroundColor(isPinningActive ? Color(hex: ColorTheme.signalOrange.rawValue) : .blue.opacity(0.7))
                }
                
                Spacer()
                
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

// Extension to dismiss keyboard when tapping outside of a text field
extension View {
    func dismissKeyboardOnTap() -> some View {
        return self
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                      to: nil,
                                                      from: nil,
                                                      for: nil)
                    }
            )
    }
}
