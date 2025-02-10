//
//  TabBarView.swift
//  Regatta
//
//  Created by Chikai Lai on 21/12/2024.
//

import Foundation
import MapKit
import SwiftUI

struct TabBarView: View {
    var body: some View {
        WithTabBar { selection in
            switch selection {
                case .home:
                    TabScrollContentView(tab: .home)
                case .discover:
                    TabScrollContentView(tab: .discover)
                case .profile:
                    TabScrollContentView(tab: .profile)
                case .settings:
                    TabScrollContentView(tab: .settings)
            }
        }
    }
}

#Preview {
    TabBarView()
}
