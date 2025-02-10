//
//  SettingsView.swift
//  Regatta
//
//  Created by Chikai Lai on 06/12/2024.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var colorManager: ColorManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    NavigationLink {
                        ColorThemeView()
                    } label: {
                        HStack {
                            Text("Theme Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: colorManager.selectedTheme.rawValue))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
