//
//  Tabs.swift
//  Regatta
//
//  Created by Chikai Lai on 21/12/2024.
//

import Foundation

enum Tabs: CaseIterable {
    case home, discover, profile, settings
    var item: TabItem {
        switch self {
            case .home:
                .init(title: "Home", systemImage: "house", color: .blue)
            case .discover:
                .init(title: "Discover", systemImage: "sparkles", color: .red)
            case .profile:
                .init(title: "Profile", systemImage: "person", color: .purple)
            case .settings:
                .init(title: "Settings", systemImage: "gear", color: .orange)
        }
    }
}
