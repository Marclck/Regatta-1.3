//
//  DataMigrationUtility.swift
//  Regatta
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation

class DataMigrationUtility {
    static let shared = DataMigrationUtility()
    
    private let migrationCompletedKey = "SessionArchiveMigrationCompleted"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    /// Check if the initial migration has been performed
    var isMigrationCompleted: Bool {
        defaults.bool(forKey: migrationCompletedKey)
    }
    
    /// Mark migration as completed
    func markMigrationAsCompleted() {
        defaults.set(true, forKey: migrationCompletedKey)
        defaults.synchronize()
        print("📊 Migration Utility: Migration marked as completed")
    }
    
    /// Perform initial data migration (called once during app launch)
    func performInitialMigration() {
        guard !isMigrationCompleted else {
            print("📊 Migration Utility: Migration already completed, skipping")
            return
        }
        
        print("📊 Migration Utility: Performing initial data migration")
        
        // Migrate existing sessions from SharedDefaults to archive
        SessionArchiveManager.shared.migrateExistingSessionsToArchive()
        
        // Mark migration as completed
        markMigrationAsCompleted()
        
        print("📊 Migration Utility: Initial migration completed successfully")
    }
}
