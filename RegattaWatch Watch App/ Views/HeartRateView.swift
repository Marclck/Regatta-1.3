//
//  HeartRateView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 23/01/2025.
//

import Foundation
import SwiftUI

// Create a dedicated manager for this view to avoid conflicts
class HeartRateViewManager: HeartRateManager {
    // Inherits all functionality from HeartRateManager
    // Can add specific functionality for this view if needed later
}

struct HeartRateView: View {
    // Use a different name for the manager to avoid conflicts
    @StateObject private var hrManager = HeartRateViewManager()
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    
    // Timer for periodic heart rate updates
    private let updateTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timerState.isRunning ? "\(Int(hrManager.heartRate))" : "HR")
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 30)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: ColorTheme.racingRed.rawValue))
            )
            .onReceive(updateTimer) { _ in
                if timerState.isRunning {
                    hrManager.startHeartRateQuery()
                }
            }
            .onChange(of: timerState.isRunning) { isRunning in
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
