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
            print("HealthKit is not available")
            return
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Heart rate type not available")
            return
        }
        
        let typesToRead: Set = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error
                    print("HR Authorization error: \(error.localizedDescription)")
                    return
                }
                
                if success {
                    self?.isAuthorized = true
                    print("HR Authorization success")
                } else {
                    print("HR Authorization denied")
                }
            }
        }
    }
    
    func startHeartRateQuery() {
        if let lastQuery = lastQueryTime {
            let timeSinceLastQuery = Date().timeIntervalSince(lastQuery)
            if timeSinceLastQuery < 10 {
                return
            }
        }
        
        lastQueryTime = Date()
        print("Starting new HR query")
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-600)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let samples = samples as? [HKQuantitySample], let mostRecentSample = samples.first else {
                print("No HR samples found")
                return
            }
            
            DispatchQueue.main.async {
                let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self?.heartRate = heartRate
                print("Updated HR: \(heartRate)")
            }
        }
        
        heartRateQuery = query  // Store reference to new query
        healthStore.execute(query)
    }
    
    func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
            print("Stopped HR query")
        }
    }
    
    deinit {
        stopHeartRateQuery()
    }
}
