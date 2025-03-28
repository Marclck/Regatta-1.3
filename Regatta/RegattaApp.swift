//
//  RegattaApp.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import SwiftUI
import SwiftData

@main
struct RegattaApp: App {
    
    @StateObject private var colorManager = ColorManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environmentObject(colorManager)
        .modelContainer(sharedModelContainer)
    }
}
