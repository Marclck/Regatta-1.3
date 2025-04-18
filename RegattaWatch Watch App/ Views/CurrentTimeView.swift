//
//  CurrentTimeView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/11/2024.
//

import Foundation
import SwiftUI

struct CurrentTimeView: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings

    @State private var currentTime = Date()
    @State private var lastUpdateTime: TimeInterval = 0
    @State private var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timeString(from: currentTime))
            .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 14) : .system(size: 14, design: .monospaced))
            .dynamicTypeSize(.xSmall)
            .foregroundColor(.black)
            .padding(.horizontal, settings.debugMode ? 10 : 10)
            .padding(.vertical, settings.debugMode ? 7 : 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .onChange(of: timerState.currentTime) { _ in
                let now = Date().timeIntervalSince1970
                if now - lastUpdateTime >= 1.0 {
                    currentTime = Date()
                    lastUpdateTime = now
                }
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .onAppear {
                currentTime = Date()
                lastUpdateTime = Date().timeIntervalSince1970
            }
    }
    
    private var backgroundColor: Color {
        timerState.mode == .countdown && timerState.currentTime <= 60
            ? Color.orange.opacity(1)
            : Color(hex: colorManager.selectedTheme.rawValue).opacity(1)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
