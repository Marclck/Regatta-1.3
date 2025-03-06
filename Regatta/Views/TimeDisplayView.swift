//
//  TimeDisplayView.swift
//  Regatta
//
//  Created by Chikai Lai on 17/11/2024.
//

import SwiftUI

struct TimeDisplayView: View {
    @ObservedObject var timerState: TimerState
    
    var body: some View {
        if timerState.mode == .setup && !timerState.isConfirmed {
            Picker("Minutes", selection: Binding(
                get: { timerState.selectedMinutes },
                set: { timerState.updateMinutes($0) }
            )) {
                ForEach(1...30, id: \.self) { minute in
                    Text("\(String(format: "%02d:00", minute))")
                        .font(.system(size: 48, design: .monospaced))  // Match size with timer display
                        .foregroundColor(.cyan)
                        .lineSpacing(100)  // Add line spacing
                        .frame(height: 100) // Fixed height for each row
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 200, height: 100)
            .clipped()  // Ensures content stays within bounds
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.cyan, lineWidth: 10)
            )
            .padding(.horizontal)  // Add some padding around the border
            .background(Color.black)
            .accentColor(.cyan)
            .onChange(of: timerState.selectedMinutes) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    // Animation will be triggered by Published property
                }
            }
        } else {
            Text(timerState.formattedTime)
                .font(.system(size: 48, design: .monospaced))  // Temporary until Zenith Beta is added
                .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : .cyan)
                .monospacedDigit()
        }
    }
}
