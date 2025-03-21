//
//  UnifiedSeparatorView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 21/03/2025.
//

import Foundation
import SwiftUI

struct UnifiedSeparatorView: View {
    let totalMinutes: Int
    let previousMinutes: Int
    let mode: TimerMode
    let currentTime: TimeInterval
    let frame: CGRect
    @EnvironmentObject var settings: AppSettings

    // Derived values
    private var barHeight: CGFloat {
        min(frame.width, frame.height)
    }
    private var barWidth: CGFloat {
        barHeight
    }
    
    var body: some View {
        
        ZStack {
            // Only show separators for non-stopwatch modes
            if mode != .stopwatch {
                // 12 o'clock trim compensator (only needed if there are separators)
                if totalMinutes > 0 {
                    RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                        .trim(from: 0, to: 0.002)
                        .stroke(Color.black,
                            style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                        )
                        .frame(width: barHeight, height: barWidth)
                        .position(x: frame.midX, y: frame.midY)
                        .rotationEffect(.degrees(-90))
                }
                
                // Regular minute separators
                ForEach(0..<totalMinutes, id: \.self) { index in
                    let separatorPosition = Double(index) / Double(totalMinutes)
                    
                    RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                        .trim(from: max(0, separatorPosition - 0.002),
                              to: min(1, separatorPosition + 0.002))
                        .stroke(Color.black,
                            style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                        )
                        .frame(width: barHeight, height: barWidth)
                        .position(x: frame.midX, y: frame.midY)
                        .rotationEffect(.degrees(-90))
                        .transition(.scale.combined(with: .opacity))
                        .animation(
                            .spring(
                                response: 0.6,
                                dampingFraction: 0.9,
                                blendDuration: 0
                            )
                            .delay(calculateDelay(for: index)),
                            value: totalMinutes
                        )
                }
                
                // Last minute separators (only in countdown mode and during last minute)
                if mode == .countdown && currentTime <= 60 && currentTime > 0 && totalMinutes > 0 {
                    ForEach(0..<5, id: \.self) { index in
                        let minuteSegmentWidth = 1.0 / Double(totalMinutes)
                        let lastSegmentStart = 1.0 - minuteSegmentWidth
                        let subSegmentPosition = lastSegmentStart + (minuteSegmentWidth / 6.0 * Double(index + 1))
                        
                        RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                            .trim(from: max(0, subSegmentPosition - 0.002),
                                  to: min(1, subSegmentPosition + 0.002))
                            .stroke(Color.black,
                                style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                            )
                            .frame(width: barHeight, height: barWidth)
                            .position(x: frame.midX, y: frame.midY)
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
        }
    }
    
    // Delay calculation for smooth animation when adding/removing separators
    private func calculateDelay(for index: Int) -> Double {
        let isAdding = totalMinutes > previousMinutes
        
        if isAdding {
            guard index >= previousMinutes && index < totalMinutes else { return 0 }
            return Double(index - previousMinutes) * 0.1
        } else {
            guard index < previousMinutes else { return 0 }
            let distanceFromEnd = previousMinutes - index - 1
            return Double(distanceFromEnd) * 0.1
        }
    }
}
