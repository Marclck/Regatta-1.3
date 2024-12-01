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
    @FocusState var FocusState
    
    var body: some View {
            if timerState.mode == .setup && !timerState.isConfirmed {
                Picker("Minutes", selection: Binding(
                    get: { timerState.selectedMinutes },
                    set: { newValue in
                        timerState.selectedMinutes = newValue
                        timerState.previousMinutes = timerState.selectedMinutes
                    }                
                ))
                {
                    ForEach(1...30, id: \.self) { minute in
                        Text("\(String(format: "%02d:00", minute))")
                            .font(.zenithBeta(size: 38)) //36 b4 adjustment
                            .scaleEffect(x:1, y:1)
                            .foregroundColor(.white)
                    }
                }
                .offset(y:6)
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(width: 150, height: 60) //140 by 75
                .scaleEffect(x:1, y:1)
                .padding(.horizontal, 5)
                .focused($FocusState)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 12.5).stroke(lineWidth: 2.1)
                        .offset(y:5)
                        .frame(width: 149.5, height: 58)
                        .foregroundColor(FocusState ? .cyan : .clear)
                }
            } else {
                Text(timerState.formattedTime)
                    .offset(y:10.5) //11 with wheel label, 4.5 without
                    .padding(.top, 13)
                    .padding(.bottom, 21)
                    .font(.zenithBeta(size: 38)) //36 b4 adjustment
                    .scaleEffect(x:1, y:1)
                    .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : .white)
            }
        }
    }
