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
                            .font(.system(size: 36)) //36 b4 adjustment
                            .scaleEffect(x:1.4, y:1)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140, height: 75) //140 by 75
                .scaleEffect(x:1, y:1)
                .padding(.horizontal, 5)
            } else {
                Text(timerState.formattedTime)
                    .offset(y: 11)
                    .padding(.top, 13)
                    .padding(.bottom, 21)
                    .font(.system(size: 36))
                    .scaleEffect(x:1.4, y:1)
                    .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : .white)
            }
        }
    }
