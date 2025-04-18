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
    var name: String
    
    init(id: UUID = UUID(), date: Date = Date(), points: [PlanPoint], name: String = "Untitled Route") {
        self.id = id
        self.date = date
        self.points = points
        self.name = name
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
    @Published var currentPlanName: String = "Untitled Route"
    
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
        currentPlanName = "Untitled Route"
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
            // Create a copy of valid points with re-numerated order values
            var reorderedPoints = validPoints
            
            // Re-numerate the order property to ensure sequential ordering without gaps
            for i in 0..<reorderedPoints.count {
                reorderedPoints[i].order = i
            }
            
            let newPlan = RoutePlan(points: reorderedPoints, name: currentPlanName)
            savedPlans.append(newPlan)
            isPlanSaved = true
            
            // Persist to storage
            savePlansToStorage()
        }
    }
    
    func loadPlan(_ plan: RoutePlan) {
        currentPlan = plan.points
        currentPlanName = plan.name
        isPlanSaved = true
    }
    
    func updatePlanName(id: UUID, newName: String) {
        if let index = savedPlans.firstIndex(where: { $0.id == id }) {
            var updatedPlan = savedPlans[index]
            updatedPlan.name = newName
            savedPlans[index] = updatedPlan
            
            // Persist the changes
            savePlansToStorage()
        }
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
    
    // Add direct binding to center coordinate
    @Binding var centerCoordinate: CLLocationCoordinate2D
    
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
    
    @FocusState private var isLatitudeFocused: Bool
    @FocusState private var isLongitudeFocused: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Point number
            Text("\(index + 1)")
                .font(.system(.headline))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.2)))
            
            // Coordinate fields
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Lat:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(.caption, design: .monospaced))
                    
                    TextField("0.000000", text: latitudeText)
                        .keyboardType(.numbersAndPunctuation)
                        .foregroundColor(.white)
                        .focused($isLatitudeFocused)
                        .font(.system(.caption, design: .monospaced))
                }
                
                HStack {
                    Text("Lng:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(.caption, design: .monospaced))
                    
                    TextField("0.000000", text: longitudeText)
                        .keyboardType(.numbersAndPunctuation)
                        .foregroundColor(.white)
                        .focused($isLongitudeFocused)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .padding(.horizontal, 4)
            .dismissKeyboardOnTap()
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {

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
                        Image(systemName: "delete.left.fill")
                            .foregroundColor(.red.opacity(0.7))
                    }
                } else {
                    // Placeholder to maintain spacing when no delete button
                    Image(systemName: "delete.left.fill")
                        .foregroundColor(.clear)
                        .opacity(0)
                }
                
                Spacer()
                
                // Get Coordinates button - directly capture coordinates from map
                Button {
                    // Directly update the point with current center coordinates
                    DispatchQueue.main.async {
                        // First, tell parent we're starting pinning for this point (to highlight it)
                        onStartPinning()
                        
                        // Use the direct binding to center coordinate
                        point.latitude = centerCoordinate.latitude
                        point.longitude = centerCoordinate.longitude
                        
                        // After a short delay, tell parent we're done pinning
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onStopPinning()
                        }
                    }
                } label: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue))
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

// MARK: - Route Name Editor Alert
struct CustomRouteNameEditor: View {
    @Binding var isPresented: Bool
    let planId: UUID
    let initialName: String
    let onSave: (UUID, String) -> Void
    
    @State private var routeName: String = ""
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Dialog content
            VStack(spacing: 16) {
                Text("Route Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Enter a name for this route")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                TextField("Enter route name", text: $routeName)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Button("Save") {
                        onSave(planId, routeName)
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(hex: ColorTheme.ultraBlue.rawValue))
                    .cornerRadius(8)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
            .frame(width: 300)
            .onAppear {
                routeName = initialName
            }
        }
    }
}

// Extension to use the custom dialog
extension View {
    func customRouteNameEditor(
        isPresented: Binding<Bool>,
        planId: UUID,
        initialName: String,
        onSave: @escaping (UUID, String) -> Void
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                CustomRouteNameEditor(
                    isPresented: isPresented,
                    planId: planId,
                    initialName: initialName,
                    onSave: onSave
                )
            }
        }
    }
}
