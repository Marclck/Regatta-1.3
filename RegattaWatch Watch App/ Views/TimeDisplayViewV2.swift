//
//  TimeDisplayViewV2.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 17/11/2024.
//

//NOT IN USE - ATTEMPT ON CUSTOM WHEEL PICKER, CANNOT SOLVE SNAPPING ISSUE

import Foundation
import SwiftUI
import WatchKit

struct CustomWheelPicker<Content: View, T: Hashable>: View {
    @EnvironmentObject var settings: AppSettings

    @Binding var selection: T
    private let content: (T) -> Content
    private let items: [T]
    private let itemHeight: CGFloat = 40.0
    private let itemSpacing: CGFloat = 8.0
    
    // Calculate total item height including spacing
    private var totalItemHeight: CGFloat {
        itemHeight + itemSpacing
    }
    
    // Track the selected index instead of the actual value
    @State private var selectedIndex: Int? = nil
    @State private var crownValue: Double = 0
    
    init(selection: Binding<T>, items: [T], @ViewBuilder content: @escaping (T) -> Content) {
        _selection = selection
        self.items = items
        self.content = content
        
        // Initialize with the current selection index
        if let index = items.firstIndex(where: { $0 == selection.wrappedValue }) {
            _selectedIndex = State(initialValue: index)
            _crownValue = State(initialValue: Double(index))
        } else {
            _selectedIndex = State(initialValue: items.isEmpty ? nil : 0)
            _crownValue = State(initialValue: 0)
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: itemSpacing) {
                            // Calculate exact spacer height to center items perfectly
                            let spacerHeight = (geometry.size.height - itemHeight) / 2
                            
                            // Top spacer to allow first item to be centered
                            Color.clear
                                .frame(height: spacerHeight)
                            
                            ForEach(items.indices, id: \.self) { index in
                                content(items[index])
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: itemHeight)
                                    .id(index)
                            }
                            
                            // Bottom spacer to allow last item to be centered
                            Color.clear
                                .frame(height: spacerHeight)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $selectedIndex, anchor: .center)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollIndicators(.hidden)
                    .clipped()
                    .digitalCrownRotation(
                        $crownValue,
                        from: 0,
                        through: Double(items.count - 1),
                        by: 1.0,
                        sensitivity: DigitalCrownRotationalSensitivity.medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )
                    .onAppear {
                        // Set initial position
                        if let index = items.firstIndex(of: selection) {
                            selectedIndex = index
                            crownValue = Double(index)
                            print("CustomWheelPicker onAppear: Set to index \(index) for value \(selection)")
                        }
                    }
                    .onChange(of: selection) { oldValue, newValue in
                        // Update selectedIndex when selection changes externally
                        if let index = items.firstIndex(of: newValue) {
                            selectedIndex = index
                            crownValue = Double(index)
                            print("CustomWheelPicker selection changed from \(oldValue) to \(newValue), index \(index)")
                        }
                    }
                    .onChange(of: selectedIndex) { oldValue, newValue in
                        // Update selection when scroll position changes
                        guard let newValue = newValue,
                              newValue >= 0,
                              newValue < items.count else { return }
                        
                        let newItem = items[newValue]
                        if newItem != selection {
                            selection = newItem
                            crownValue = Double(newValue)
                            print("ScrollPosition changed to index \(newValue), item: \(newItem)")
                        }
                    }
                    .onChange(of: crownValue) { oldValue, newValue in
                        // Update selectedIndex when crown rotates
                        let newIndex = Int(newValue.rounded())
                        if newIndex != selectedIndex && newIndex >= 0 && newIndex < items.count {
                            selectedIndex = newIndex
                            print("Crown rotated to index \(newIndex)")
                        }
                    }
                }
            }
            
            // Dedicated box to show the selected item
            RoundedRectangle(cornerRadius: 10)
                .stroke(.secondary, lineWidth: 2)
                .frame(height: itemHeight)
        }
    }
}

struct TimeDisplayViewV2: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @FocusState var focusState
    
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
        Group {
            if timerState.mode == .setup && !timerState.isConfirmed {
                CustomWheelPicker(selection: Binding(
                    get: { timerState.selectedMinutes },
                    set: { newValue in
                        print("Picker selection changed to \(newValue)")
                        timerState.selectedMinutes = newValue
                        timerState.previousMinutes = timerState.selectedMinutes
                    }
                ), items: Array(0...30)) { minute in
                    Text("\(String(format: "%02d:00", minute))")
                        .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 42) : .zenithBeta(size: 38, weight: .medium))
                        .dynamicTypeSize(.xSmall)
                        .padding(.vertical, 4)
                        .scaleEffect(x: 1, y: 1)
                        .foregroundColor(settings.lightMode ? .black : .white)
                }
                .frame(width: 150, height: 80)
                .padding(.horizontal, 5)
                .colorScheme(settings.lightMode ? .light : .dark)
                .focused($focusState)
            } else {
                ZStack {
                    // Main time display
                    HStack(spacing: 0) {
                        Text(timeComponents.minutes)
                            .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 42) : .zenithBeta(size: 38, weight: .medium))
                        Text(":")
                            .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 42) : .zenithBeta(size: 38, weight: .medium))
                            .offset(x: -0.5, y: -4.3)
                        Text(timeComponents.seconds)
                            .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 42) : .zenithBeta(size: 38, weight: .medium))
                    }
                    .dynamicTypeSize(.xSmall)
                    .offset(y: 10.5)
                    .padding(.top, 13)
                    .padding(.bottom, 21)
                    .scaleEffect(x: 1, y: 1)
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
                                .frame(width: 80, height: 80)
                                .offset(x: -40, y: -3)
                            
                            CustomWheelPicker(selection: $selectedMinuteAdjustment, items: Array(0...30)) { minute in
                                Text("\(String(format: "%02d", minute))")
                                    .font(.zenithBeta(size: 38, weight: .medium))
                                    .dynamicTypeSize(.xSmall)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(settings.lightMode ? .black : .white)
                            }
                            .frame(width: 80, height: 80)
                            .offset(x: -40, y: -2)
                            .overlay(alignment: .bottom) {
                                if settings.lightMode {
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
                                        .offset(x: -40, y: 0)
                                        .frame(width: 80, height: 80)
                                }
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
        .border(Color.blue, width: 2)
    }
}

#Preview {
    TimeDisplayViewV2(timerState: WatchTimerState())
        .environmentObject(ColorManager())
        .environmentObject(AppSettings())
}
