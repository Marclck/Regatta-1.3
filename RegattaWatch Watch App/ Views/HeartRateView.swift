//
//  HeartRateView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 23/01/2025.
//

import Foundation
import SwiftUI

class HeartRateViewManager: HeartRateManager {}

struct HeartRateView: View {
    @StateObject private var hrManager = HeartRateViewManager()
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    
    private let updateTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timerState.isRunning ? "\(Int(hrManager.heartRate))" : "HR")
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(timerState.isRunning ? Color.white : Color.white.opacity(0.3))
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 30)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(timerState.isRunning ? Color(hex: ColorTheme.racingRed.rawValue) : Color(hex: ColorTheme.racingRed.rawValue).opacity(0.3))
            )
            .onReceive(updateTimer) { _ in
                print("Timer tick, isRunning: \(timerState.isRunning)")
                if timerState.isRunning {
                    hrManager.startHeartRateQuery()
                }
            }
            .onChange(of: timerState.isRunning) { isRunning in
                print("Timer state changed to: \(isRunning)")
                if isRunning {
                    hrManager.startHeartRateQuery()
                } else {
                    hrManager.stopHeartRateQuery()
                }
            }
    }
}

// MARK: - Preview Helpers
#if DEBUG
private class PreviewHeartRateViewManager: HeartRateViewManager {
    override init() {
        super.init()
        self.heartRate = 142
    }
}

private class PreviewWatchTimerState: WatchTimerState {
    override init() {
        super.init()
        self.isRunning = false  // Preview with "HR" state
    }
}

struct HeartRateView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                HeartRateView(timerState: PreviewWatchTimerState())
                    .environmentObject(ColorManager())
            }
        }
        .frame(width: 180, height: 180)
    }
}
#endif
