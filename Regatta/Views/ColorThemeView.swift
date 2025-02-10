//
//  ColorThemeView.swift
//  Regatta
//
//  Created by Chikai Lai on 06/12/2024.
//

import Foundation
import SwiftUI

struct ColorThemeView: View {
    @EnvironmentObject var colorManager: ColorManager
    
    var body: some View {
        List(ColorTheme.allCases, id: \.self) { theme in
            HStack {
                Circle()
                    .fill(Color(hex: theme.rawValue))
                    .frame(width: 24, height: 24)
                
                Text(theme.name)
                    .padding(.leading, 8)
                
                Spacer()
                
                if colorManager.selectedTheme == theme {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                colorManager.selectedTheme = theme
            }
        }
        .navigationTitle("Theme Color")
    }
}
