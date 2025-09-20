//
//  SecondProgressBarView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 01/12/2024.
//

import Foundation
import SwiftUI

struct SecondProgressBarView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @StateObject private var fontManager = CustomFontManager.shared
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings

    @State private var currentSecond: Double = 0
    @State private var timer = Timer.publish(every: AppSettings().timerInterval, on: .main, in: .common).autoconnect()

    
    private func updateSecond() {
        let components = Calendar.current.dateComponents([.second, .nanosecond], from: Date())
        
        // If timer interval is 1 second, only update on exact seconds
        if settings.timerInterval == 1.0 {
            currentSecond = Double(components.second!)
        } else {
            // For smooth animation, include nanoseconds
            currentSecond = Double(components.second!) + Double(components.nanosecond!) / 1_000_000_000
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            let barWidth = frame.width
            let barHeight = frame.height
            let centerY = frame.height
            
            ZStack {
                RoundedRectangle(cornerRadius: settings.ultraModel ? screenBounds.height > 255 ? 60 : 55 : 42)
                    .stroke(Color(hex: colorManager.selectedTheme.rawValue).opacity(isLuminanceReduced ? 0.2 : 0.2), lineWidth: 25)
                        .frame(width: barWidth, height: barHeight)
                        .position(x: frame.midX, y: frame.midY)
                
                Text(settings.teamName)
                    .font(settings.teamNameFont == "Default" ?
                        .system(size: 9, weight: .semibold) :
                        Font.customFont(fontManager.customFonts.first(where: { $0.id.uuidString == settings.teamNameFont }) ?? fontManager.customFonts.first!, size: 9) ?? .system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(270), anchor: .center)
                    .kerning(0.5)
                    .foregroundColor(settings.altTeamNameColor ? (isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : Color(hex: settings.teamNameColorHex).opacity(1)) : Color(hex: settings.teamNameColorHex).opacity(1))
//                    .foregroundColor(Color(hex: colorManager.selectedTheme.rawValue).opacity(1))
                    .position(x: settings.teamNameFont == "Default" ? 6 : 7, y: centerY/2+25)
                
                // Progress fill for seconds
                if !isLuminanceReduced {
                    RoundedRectangle(cornerRadius: settings.ultraModel ? screenBounds.height > 255 ? 60 : 55 : 42)
                        .trim(from: 0, to: currentSecond/60)
                        .stroke(
                            Color(hex: colorManager.selectedTheme.rawValue).opacity(0.9),
                            style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                        )
                        .frame(width: barHeight, height: barWidth)
                        .position(x: frame.midX, y: frame.midY)
                        .rotationEffect(.degrees(-90))  // Align trim start to top
                        .overlay(
                            Text(settings.teamName)
                                .font(settings.teamNameFont == "Default" ?
                                    .system(size: 9, weight: .semibold) :
                                        Font.customFont(fontManager.customFonts.first(where: { $0.id.uuidString == settings.teamNameFont }) ?? fontManager.customFonts.first!, size: 9) ?? .system(size: 9, weight: .semibold))
                                .rotationEffect(.degrees(270), anchor: .center)
                                .kerning(0.5)
                                .foregroundColor(Color.black.opacity(1)) //settings.altTeamNameColor ? Color(hex: ColorTheme.speedPapaya.rawValue) :
                            //                                .foregroundColor(Color(hex: settings.teamNameColorHex).opacity(1))
                                .position(x: settings.teamNameFont == "Default" ? 6 : 7, y: centerY/2+25)
                                .mask(
                                    RoundedRectangle(cornerRadius: settings.ultraModel ? screenBounds.height > 255 ? 60 : 55 : 42)
                                        .trim(from: 0, to: currentSecond/60)
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 25, lineCap: .butt))  // ADD THIS
                                        .frame(width: barHeight, height: barWidth)
                                        .rotationEffect(.degrees(-90))
                                )
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Initialize the second value immediately when view appears
            updateSecond()
        }
        .onReceive(timer) { _ in
            // Regular timer updates
            updateSecond()
        }
    }
}
