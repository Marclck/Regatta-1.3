//
//  ButtonsView.swift
//  Regatta
//
//  Created by Chikai Lai on 17/11/2024.
//

import SwiftUI

struct ButtonsView: View {
    @ObservedObject var timerState: TimerState
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                switch timerState.mode {
                case .setup:
                    timerState.isConfirmed.toggle()
                case .countdown, .stopwatch:
                    timerState.resetTimer()
                }
            }) {
                Image(systemName: leftButtonIcon)
                    .font(.title)
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(.cyan)
                    .frame(width: 100, height: 60)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(15)
            }
            
            Button(action: {
                if timerState.isRunning {
                    timerState.pauseTimer()
                } else {
                    timerState.startTimer()
                }
            }) {
                Image(systemName: rightButtonIcon)
                    .font(.title)
                    .fontWeight(.heavy)
                    .symbolVariant(.fill)
                    .foregroundColor(.cyan)
                    .frame(width: 100, height: 60)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(15)
            }
        }
    }
    
    private var leftButtonIcon: String {
        switch timerState.mode {
        case .setup:
            return timerState.isConfirmed ? "arrow.counterclockwise" : "checkmark"
        case .countdown, .stopwatch:
            return "xmark"
        }
    }
    
    private var rightButtonIcon: String {
        if timerState.mode == .setup {
            return "play"
        } else {
            return timerState.isRunning ? "pause" : "play"
        }
    }
}
