//
//  TimeDisplayViewV4.swift
//  Regatta
//
//  Created by Chikai Lai on 02/08/2025.
//

// THIS IS EXPERIMENT VERSION OF V3

import Foundation
import SwiftUI
import WatchKit

struct TimeDisplayViewV4: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @FocusState var FocusState

    @State private var isMinuteAdjustmentActive = false
    @State private var adjustmentTimer: Timer?
    @State private var selectedMinuteAdjustment: Int = 0

    // MARK: - State Variables
    // Controls the visibility of the static time display.
    @State private var isPickerScrolling = false
    // Timer to detect when scrolling has stopped.
    @State private var scrollingTimer: Timer?

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
    
    // --- NEW APPROACH ---
    // Helper function to determine the color for a picker item.
    private func colorForPickerItem(at minute: Int) -> Color {
        let isSelectedAndNotScrolling = (minute == timerState.selectedMinutes && !isPickerScrolling)
        
        if isSelectedAndNotScrolling {
            // If the item is selected and the picker is not scrolling, make it clear.
            return .clear
        } else {
            // Otherwise, use the standard light/dark mode color.
            return settings.lightMode ? .black : .white
        }
    }

    var body: some View {
        if timerState.mode == .setup && !timerState.isConfirmed {
            ZStack {
                Picker("Minutes", selection: Binding(
                    get: { timerState.selectedMinutes },
                    set: { newValue in
                        // When the picker value changes, show all picker items.
//                        withAnimation {
                            isPickerScrolling = true
//                        }
                        
                        // Invalidate any existing timer.
                        scrollingTimer?.invalidate()
                        
                        // Set a new timer to detect when scrolling stops.
                        scrollingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                            // Use withAnimation for a smoother transition
//                            withAnimation {
                                isPickerScrolling = false
//                            }
                        }
                        
                        timerState.selectedMinutes = newValue
                        timerState.previousMinutes = timerState.selectedMinutes
                    }
                )) {
                    ForEach(0...30, id: \.self) { minute in
                        HStack(spacing: 2) {
                            Text(String(format: "%02d", minute))
                                .font(settings.debugMode ? Font.custom("Hermes-Numbers", size: 28) : .zenithBeta(size: 28, weight: .medium))
                                .foregroundColor(colorForPickerItem(at: minute))
                                .offset(x:1.5, y: 0)
                            
                            VStack(spacing: 6.5) {
                                Circle()
                                    .fill(colorForPickerItem(at: minute))
                                    .frame(width: 4, height: 4)
                                Circle()
                                    .fill(colorForPickerItem(at: minute))
                                    .frame(width: 4, height: 4)
                            }
                            .offset(x:-0.5, y:-0.5)
                            
                            Text("00")
                                .font(settings.debugMode ? Font.custom("Hermes-Numbers", size: 28) : .zenithBeta(size: 28, weight: .medium))
                                .foregroundColor(colorForPickerItem(at: minute))
                                .offset(x:0.5)
                        }
                        .drawingGroup()
                        .offset(y:1)
                        .padding(.vertical)
                        .dynamicTypeSize(.xSmall)
                        .scaleEffect(x: 1, y: 1)
                    }
                }
                .offset(y:5)
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(width: 100, height: 52)
                .scaleEffect(x:1.5, y:1.5)
                .padding(.horizontal, 5)
                .colorScheme(settings.lightMode ? .light : .dark)
                .focused($FocusState)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            settings.lightMode ?
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(1.4), location: 0),
                                    .init(color: .clear, location: 0.25),
                                    .init(color: .clear, location: 0.5),
                                    .init(color: .clear, location: 0.75),
                                    .init(color: .white.opacity(1.4), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .clear, location: 1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .stroke(settings.lightMode ? Color.black : ColorManager.getCurrentThemeColor(), lineWidth: 2.5)
                        .offset(y: 19)
                        .frame(width: 146, height: 75)
                        .opacity(FocusState ? 1.0 : 0.0)
                        .allowsHitTesting(false)
                }

                // This HStack will now fade in/out when the picker stops/starts scrolling.
                HStack(spacing: 2) {
                    Text(String(format: "%02d", timerState.selectedMinutes))
                        .font(settings.debugMode ? Font.custom("Hermes-Numbers", size: 42) : .zenithBeta(size: 28, weight: .medium))
                        .foregroundColor(isPickerScrolling ? .clear : settings.lightMode ? .black : .white)
                        .offset(x:1, y:0)
                    
                    VStack(spacing: 10) {
                        Circle()
                            .fill(isPickerScrolling ? .clear : settings.lightMode ? .black : .white)
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(isPickerScrolling ? .clear : settings.lightMode ? .black : .white)
                            .frame(width: 6, height: 6)
                    }
                    .offset(x:-0.5)
                    
                    Text("00")
                        .font(settings.debugMode ? Font.custom("Hermes-Numbers", size: 42) : .zenithBeta(size: 28, weight: .medium))
                        .foregroundColor(isPickerScrolling ? .clear : settings.lightMode ? .black : .white)
                        .offset(x:2)
                    
                }
                .offset(y:12)
                .padding(.top, 13)
                .padding(.bottom, 21)
                //.opacity(isPickerScrolling ? 0 : 1)
                .allowsHitTesting(false)
            }
        } else {
            // The rest of your view remains unchanged.
            ZStack {
                // Main time display
                HStack(spacing: 2) {
                    Text(timeComponents.minutes)
                        .font(settings.debugMode ? Font.custom("Hermes-Numbers", size: 42) : .zenithBeta(size: 28, weight: .medium))
                        .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : settings.lightMode ? .black : .white)
                        .offset(x:1, y:0)

                    VStack(spacing: 10) {
                        Circle()
                            .fill(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : settings.lightMode ? .black : .white)
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : settings.lightMode ? .black : .white)
                            .frame(width: 6, height: 6)
                    }
                    .offset(x:-0.5)
                    
                    Text(timeComponents.seconds)
                        .font(settings.debugMode ? Font.custom("Hermes-Numbers", size: 42) : .zenithBeta(size: 28, weight: .medium))
                        .foregroundColor(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : settings.lightMode ? .black : .white)
                        .offset(x:2)

                }
                .offset(y:12)
                .padding(.top, 13)
                .padding(.bottom, 21)
                .onTapGesture(count: 2) {
                    if timerState.mode == .countdown && settings.useProButtons {
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
                            .frame(width: 90, height: 80)
                            .offset(x: -40, y: 10)
                        
                        Picker("", selection: $selectedMinuteAdjustment) {
                            ForEach(0...30, id: \.self) { minute in
                                Text("\(String(format: "%02d", minute))")
                                    .font(settings.debugMode ? Font.custom("Hermes-Numbers", size: 28) : .zenithBeta(size: 28, weight: .medium))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                            }
                        }
                        .drawingGroup()
                        .pickerStyle(.wheel)
                        .frame(width: 55, height: 60)
                        .scaleEffect(x:1.5, y:1.5)
                        .offset(x: -37, y: -4)
                        .overlay(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    settings.lightMode ?
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .white.opacity(1.4), location: 0),
                                            .init(color: .clear, location: 0.25),
                                            .init(color: .clear, location: 0.5),
                                            .init(color: .clear, location: 0.75),
                                            .init(color: .white.opacity(1.4), location: 1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .clear, location: 1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                    .stroke(ColorManager.getCurrentThemeColor(), lineWidth: 3)
                                    .offset(x:-37, y: 8)
                                    .frame(width: 77, height: 61)
                                    .allowsHitTesting(false)
                        }
                    }
                }
            }
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

// The preview provider remains the same.
struct TimeDisplayViewV4_Previews: PreviewProvider {
    static var previews: some View {
        let timerState = WatchTimerState()
        timerState.selectedMinutes = 5
        timerState.previousMinutes = 5
        timerState.mode = .setup
        timerState.isConfirmed = false

        return Group {
            TimeDisplayViewV4(timerState: timerState)
                .environmentObject(ColorManager())
                .environmentObject(AppSettings())
                .previewDisplayName("Setup Mode - Light")
                .environment(\.colorScheme, .light)

            TimeDisplayViewV4(timerState: timerState)
                .environmentObject(ColorManager())
                .environmentObject(AppSettings())
                .previewDisplayName("Setup Mode - Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}
