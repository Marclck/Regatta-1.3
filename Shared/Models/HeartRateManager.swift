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
    private var lastQueryTime: Date?
    
    @Published var heartRate: Double = 0
    @Published var isAuthorized: Bool = false
    @Published var error: Error?
    
    override init() {
        super.init()
        setupHealthKit()
    }
    
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Heart rate type is not available")
            return
        }
        
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
                } else {
                    print("Authorization denied")
                }
            }
        }
    }
    
    func startHeartRateQuery() {
        // Check if 10 seconds have passed since last query
        if let lastQuery = lastQueryTime {
            let timeSinceLastQuery = Date().timeIntervalSince(lastQuery)
            if timeSinceLastQuery < 10 {
                return
            }
        }
        
        lastQueryTime = Date()
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Create a predicate for the last 10 seconds
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-10)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        // Query for the most recent heart rate
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let samples = samples as? [HKQuantitySample], let mostRecentSample = samples.first else {
                return
            }
            
            DispatchQueue.main.async {
                let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self?.heartRate = heartRate
                print("Updated heart rate: \(heartRate)")
            }
        }
        
        healthStore.execute(query)
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
