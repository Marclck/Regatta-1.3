//
//  CurrentTimeView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/11/2024.
//

import Foundation
import SwiftUI

struct CurrentTimeView: View {
    @ObservedObject var timerState: WatchTimerState  // Add this property
    @EnvironmentObject var colorManager: ColorManager


    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timeString(from: currentTime))
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.black)
            .padding(.horizontal, 10) // Add horizontal padding inside the background
                        .padding(.vertical, 4)    // Add vertical padding inside the background
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(backgroundColor) // Semi-transparent black background
                            )
            .onReceive(timer) { input in
                currentTime = input
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
