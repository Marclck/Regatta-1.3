//
//  SeparatorOverlay.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 18/11/2024.
//

import Foundation
import SwiftUI

struct WatchSeparatorOverlay: View {
    let totalMinutes: Int
    let previousMinutes: Int
    let mode: TimerMode
    let currentTime: TimeInterval
    let size: CGSize
    let center: CGPoint
    
    private let maxSeparators = 60
    
    var body: some View {
        ZStack {
            if mode != .stopwatch {
                ForEach(0..<maxSeparators, id: \.self) { index in
                    WatchSeparatorLine(
                        baseAngle: -90,
                        rotationAngle: calculateRotationAngle(for: index),
                        center: center,
                        size: size,
                        isVisible: index < totalMinutes,
                        animationDelay: calculateDelay(for: index)
                    )
                }
            }
        }
    }
    private func calculateRotationAngle(for index: Int) -> Double {
        guard index < totalMinutes else { return 0 }
        return -360.0 * Double(index) / Double(totalMinutes)
    }
    
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

struct WatchSeparatorLine: View {
    let baseAngle: Double
    let rotationAngle: Double
    let center: CGPoint
    let size: CGSize
    let isVisible: Bool
    let animationDelay: Double
    
    var body: some View {
        Path { path in
            let radius = max(size.width, size.height)
            let radians = baseAngle * .pi / 180
            
            let startX = center.x
            let startY = center.y
            let endX = startX + radius * cos(CGFloat(radians))
            let endY = startY + radius * sin(CGFloat(radians))
            
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(Color.black, lineWidth: 4)
        .rotationEffect(.degrees(rotationAngle), anchor: .center)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.1, anchor: .center)
        .animation(
            .spring(
                response: 0.6,
                dampingFraction: 0.9,
                blendDuration: 0
            )
            .delay(animationDelay),
            value: isVisible
        )
        .animation(
            .spring(
                response: 0.6,
                dampingFraction: 0.9,
                blendDuration: 0
            ),
            value: rotationAngle
        )
    }
}
