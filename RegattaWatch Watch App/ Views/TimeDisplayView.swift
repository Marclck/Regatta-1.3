//
//  TimeDisplayView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/11/2024.
//

import Foundation
import SwiftUI
import WatchKit

struct TimeDisplayView: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings  // Add AppSettings
    @FocusState var FocusState
    
    @State private var isMinuteAdjustmentActive = false
    @State private var adjustmentTimer: Timer?
    @State private var selectedMinuteAdjustment: Int = 0
    
    private var timeComponents: (minutes: String, seconds: String) {
        let components = timerState.formattedTime.split(separator: ":")
        return (
            minutes: String(components[0]),
            seconds: String(components[1])
        )
    }
    
    private func startAdjustmentTimer() {
        adjustmentTimer?.invalidate()
        adjustmentTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                updateMinutes(selectedMinuteAdjustment)
                isMinuteAdjustmentActive = false
            }
        }
    }
    
    private func updateMinutes(_ newMinutes: Int) {
        if newMinutes >= 0 && newMinutes <= 30 {
            timerState.adjustMinutes(newMinutes)
            WKInterfaceDevice.current().play(.stop)
        }
    }
    
    var body: some View {
        if timerState.mode == .setup && !timerState.isConfirmed {
            Picker("Minutes", selection: Binding(
                get: { timerState.selectedMinutes },
                set: { newValue in
                    timerState.selectedMinutes = newValue
                    timerState.previousMinutes = timerState.selectedMinutes
                }
            )) {
                ForEach(0...30, id: \.self) { minute in
                    Text("\(String(format: "%02d:00", minute))")
                        .font(.zenithBeta(size: 38, weight: .medium))
                        .dynamicTypeSize(.xSmall)
                        .padding(.vertical)
                        .scaleEffect(x:1, y:1)
                        .foregroundColor(settings.lightMode ? .black : .white)
                }
            }
            .offset(y:6)
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(width: 150, height: 80)
            .scaleEffect(x:1, y:1)
            .padding(.horizontal, 5)
            .colorScheme(settings.lightMode ? .light : .dark)
            .focused($FocusState)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12.5)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white.opacity(1.4), location: 0),
                                .init(color: .clear, location: 0.5),
                                .init(color: .white.opacity(1.4), location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: 5)
                    .frame(width: 149, height: 78)
                    .opacity(FocusState ? 1.0 : 0.0) // Show/hide based on focus state
            }
        } else {
            ZStack {
                // Main time display
                HStack(spacing: 0) {
                    Text(timeComponents.minutes)
                        .font(.zenithBeta(size: 38, weight: .medium))
                        .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : settings.lightMode ? .black : .white)

                    Text(":")
                        .font(.zenithBeta(size: 38, weight: .medium))
                        .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : settings.lightMode ? .black : .white)
                        .offset(x:-0.5, y:-4.3)
                    
                    Text(timeComponents.seconds)
                        .font(.zenithBeta(size: 38, weight: .medium))
                        .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : settings.lightMode ? .black : .white)
                }
                .offset(y:10.5)
                .padding(.top, 13)
                .padding(.bottom, 21)
                .scaleEffect(x:1, y:1)
                .onTapGesture(count: 2) {
                    if timerState.mode == .countdown && settings.useProButtons {  // Check if proButtons is enabled
                        selectedMinuteAdjustment = Int(timerState.currentTime) / 60
                        withAnimation {
                            isMinuteAdjustmentActive = true
                            WKInterfaceDevice.current().play(.start)
                            startAdjustmentTimer()
                        }
                    }
                }
                
                // Minute adjustment picker overlay
                if isMinuteAdjustmentActive {
                    ZStack {
                        Rectangle()
                            .fill(settings.lightMode ? Color.white : Color.black)
                            .frame(width: 80, height: 80)
                            .offset(x: -40, y: -3)
                        
                        Picker("", selection: $selectedMinuteAdjustment) {
                            ForEach(0...30, id: \.self) { minute in
                                Text("\(String(format: "%02d", minute))")
                                    .font(.zenithBeta(size: 38, weight: .medium))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 80)
                        .offset(x: -40, y: -2)
                        .overlay(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 12.5)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .white.opacity(1.8), location: 0),
                                            .init(color: .clear, location: 0.6),
                                            .init(color: .white.opacity(1.4), location: 1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .offset(x:-40, y: 0)
                                .frame(width: 80, height: 80)
                        }
                    }
                }
            }
            // Add tap gesture to exit adjustment mode and apply changes
            .onTapGesture {
                if isMinuteAdjustmentActive {
                    withAnimation {
                        updateMinutes(selectedMinuteAdjustment)
                        isMinuteAdjustmentActive = false
                    }
                }
            }
        }
    }
}
