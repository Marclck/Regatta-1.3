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
   
   @State private var timer: Timer?
   
    private func handleTimerState() {
        if !timerState.isRunning {
            timer?.invalidate()
            timer = nil
            hrManager.stopHeartRateQuery()
        } else {
            hrManager.startHeartRateQuery()
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                hrManager.startHeartRateQuery()
                if hrManager.heartRate > 0 {  // Only record if we have a valid heart rate
                    JournalManager.shared.addDataPoint(
                        heartRate: Int(hrManager.heartRate),
                        speed: nil,
                        location: nil
                    )
                }
            }
        }
    }
   
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
           .onAppear {
               handleTimerState()
           }
           .onChange(of: timerState.isRunning) { _, _ in
               handleTimerState()
           }
           .onDisappear {
               timer?.invalidate()
               timer = nil
               hrManager.stopHeartRateQuery()
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
