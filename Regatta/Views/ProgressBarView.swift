//
//  ProgressBarView.swift



import SwiftUI

struct ProgressBarView: View {
    @ObservedObject var timerState: TimerState
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let barWidth = screenWidth - 24
            let barHeight = screenHeight - 24
            
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 90)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 80)
                    .frame(width: barWidth, height: barHeight)
                    .position(x: frame.midX, y: frame.midY)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 90)
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        Color(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : .cyan),
                        style: StrokeStyle(lineWidth: 80, lineCap: .butt)
                    )
                    .frame(width: barHeight, height: barWidth)
                    .position(x: frame.midX, y: frame.midY)
                    .rotationEffect(.degrees(-90))  // Align trim start to top
                
                // Separators overlay
                SeparatorOverlay(
                    totalMinutes: timerState.selectedMinutes,
                    mode: timerState.mode,
                    currentTime: timerState.currentTime,
                    frameSize: CGSize(width: barWidth, height: barHeight),
                    center: CGPoint(x: frame.midX, y: frame.midY)
                )
            }
        }
        .ignoresSafeArea()
    }
    private var progressValue: CGFloat {
        if timerState.mode == .countdown {
            return 1 - timerState.progress
        } else {
            return timerState.progress
        }
    }
}

struct SeparatorOverlay: View {
    let totalMinutes: Int
    let mode: TimerMode
    let currentTime: TimeInterval
    let frameSize: CGSize
    let center: CGPoint
    @State private var isVisible = false
    @State private var previousMinutes: Int = 0
    
    // Maximum number of separators (same as max minutes in picker)
    private let maxSeparators = 60
    
    var body: some View {
        ZStack {
            // Create all possible separators
            ForEach(0..<maxSeparators, id: \.self) { index in
                SeparatorLine(
                    baseAngle: -90,  // 12 o'clock position
                    rotationAngle: calculateRotationAngle(for: index),
                    center: center,
                    size: frameSize,
                    isVisible: index < totalMinutes,
                    animationDelay: calculateDelay(for: index)
                )
            }
        }
        .onChange(of: totalMinutes) { oldValue, newValue in
            previousMinutes = oldValue
        }
    }
    
    private func calculateRotationAngle(for index: Int) -> Double {
        // Calculate how much each separator should rotate based on total minutes
        -360.0 * Double(index) / Double(totalMinutes)
    }
    
    private func calculateDelay(for index: Int) -> Double {
        let isAdding = totalMinutes > previousMinutes
        
        if isAdding {
            // When adding markers, start from the one closest to 12 o'clock
            guard index >= previousMinutes && index < totalMinutes else { return 0 }
            return Double(index - previousMinutes) * 0.1
        } else {
            // When removing markers, start from the one furthest from 12 o'clock
            guard index < previousMinutes else { return 0 }
            let distanceFromEnd = previousMinutes - index - 1
            return Double(distanceFromEnd) * 0.1
        }
    }
    
    
    struct SeparatorLine: View {
        let baseAngle: Double      // Starting angle (12 o'clock)
        let rotationAngle: Double  // How much to rotate from base
        let center: CGPoint
        let size: CGSize
        let isVisible: Bool
        let animationDelay: Double  // Added this line

        var body: some View {
            GeometryReader { geometry in
                Path { path in
                    let radius = max(size.width, size.height)
                    let radians = baseAngle * .pi / 180
                    
                    // Start point (center)
                    let startX = center.x
                    let startY = center.y
                    
                    // End point (edge)
                    let endX = startX + radius * cos(CGFloat(radians))
                    let endY = startY + radius * sin(CGFloat(radians))
                    
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(Color.black, lineWidth: 6)
                .rotationEffect(.degrees(rotationAngle), anchor: .center)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: isVisible)
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: rotationAngle)
            }
        }
    }
}
