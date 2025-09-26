//
//  TimerDisplayAsCurrentTimeView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 01/12/2024.
//

import Foundation
import SwiftUI
import WatchKit

struct TimerDisplayAsCurrentTime: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings

    
    var body: some View {
        HStack(spacing: -2) {
            // Hours/Minutes component
            Text(String(displayText.prefix(2))) // "HH" or "mm"
                .font(settings.timeFont == "Default" ?
                    .system(size: 14, design: .monospaced) :
                        (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 14, weight: .medium) } ?? .system(size: 14, design: .monospaced)))
                .dynamicTypeSize(.xSmall)
                .foregroundColor(.black)
            
            // Colon separator
            Text(":")
                .font(.system(size: 14, design: .monospaced))
                .dynamicTypeSize(.xSmall)
                .foregroundColor(.black)
                .offset(y:-1)
            
            // Minutes/Seconds component
            Text(String(displayText.suffix(2))) // "mm" or "ss"
                .font(settings.timeFont == "Default" ?
                    .system(size: 14, design: .monospaced) :
                        (CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }).flatMap { Font.customFont($0, size: 14, weight: .medium) } ?? .system(size: 14, design: .monospaced)))
                .dynamicTypeSize(.xSmall)
                .foregroundColor(.black)
        }
        .padding(.horizontal, settings.debugMode ? 6 : 10)
        .padding(.vertical, settings.debugMode ? 4 : 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .applyTimerDisplayGlassEffect(glassEffect: settings.glassEffect)
    }
    
    private var displayText: String {
        switch timerState.mode {
        case .setup:
            return String(format: "%02d:00", timerState.selectedMinutes)
        case .countdown, .stopwatch:
            return timerState.formattedTime
        }
    }
    
    private var backgroundColor: Color {
        timerState.mode == .countdown && timerState.currentTime <= 60
            ? Color.orange.opacity(1)
            : Color(hex: colorManager.selectedTheme.rawValue).opacity(1)
    }
}

// MARK: - View Extension for Timer Display Glass Effect
extension View {
    @ViewBuilder
    func applyTimerDisplayGlassEffect(glassEffect: Bool) -> some View {
        if glassEffect {
            self
                .glassEffect(in: RoundedRectangle(cornerRadius: 8.0))
        } else {
            self
        }
    }
}
