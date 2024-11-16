//
//  TimeDisplayView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/11/2024.
//

import Foundation
import SwiftUI

struct TimeDisplayView: View {
    @ObservedObject var timerState: WatchTimerState
    
    var body: some View {
            if timerState.mode == .setup && !timerState.isConfirmed {
                Picker("Minutes", selection: Binding(
                    get: { timerState.selectedMinutes },
                    set: { newValue in
                        timerState.selectedMinutes = newValue
                        timerState.previousMinutes = timerState.selectedMinutes
                    }                
                )) {
                    ForEach(1...30, id: \.self) { minute in
                        Text("\(String(format: "%02d:00", minute))")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140, height: 75)
                .padding(.horizontal, 5)
            } else {
                Text(timerState.formattedTime)
                    .offset(y: 11)
                    .padding(.top, 13)
                    .padding(.bottom, 21)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : .cyan)
            }
        }
    }
