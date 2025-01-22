//
//  HeartRateManager.swift
//  Regatta
//
//  Created by Chikai Lai on 21/01/2025.
//

import Foundation
import HealthKit
import Combine

class HeartRateManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    
    @Published var heartRate: Double = 0
    @Published var isAuthorized: Bool = false
    @Published var error: Error?
    
    override init() {
        super.init()
        setupHealthKit()
    }
    
    private func setupHealthKit() {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Define the heart rate type we want to read
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Heart rate type is not available")
            return
        }
        
        // Request authorization
        let typesToRead: Set = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error
                    print("Authorization error: \(error.localizedDescription)")
                    return
                }
                
                if success {
                    self?.isAuthorized = true
                    self?.startHeartRateQuery()
                } else {
                    print("Authorization denied")
                }
            }
        }
    }
    
    func startHeartRateQuery() {
        // Define the heart rate type
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Query to observe heart rate data
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        // Update handler for continuous monitoring
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        // Execute the query
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async { [weak self] in
            // Get the latest heart rate reading
            if let mostRecentSample = samples.last {
                let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self?.heartRate = heartRate
                print("Updated heart rate: \(heartRate)")
            }
        }
    }
    
    func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }
    
    deinit {
        stopHeartRateQuery()
    }
}

// MARK: - Protocol Conformance
extension HeartRateManager: HeartRateManagerProtocol {}
