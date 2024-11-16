//
//  LastMinuteSeparatorView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 21/11/2024.
//

import Foundation
import SwiftUI

struct LastMinuteSeparatorView: View {
    let mode: TimerMode
    let currentTime: TimeInterval
    let totalMinutes: Int
    let size: CGSize
    let center: CGPoint
    
    private let numberOfSeparators = 5
    
    var body: some View {
        Group {
            if mode == .countdown && currentTime <= 60 && currentTime > 0 {
                ForEach(0..<numberOfSeparators, id: \.self) { index in
                    LastMinuteSeparatorLine(
                        baseAngle: -90 + 360.0 / Double(totalMinutes),
                        rotationAngle: calculateRotationAngle(for: index),
                        center: center,
                        size: size
                    )
                }
            }
        }
        //.animation(nil) // Disable any inherited animations
    }
    
    private func calculateRotationAngle(for index: Int) -> Double {
        let regularSeparatorAngle = -360.0 / Double(totalMinutes)
        let availableAngle = abs(regularSeparatorAngle)
        let sectionAngle = availableAngle / 6.0
        return regularSeparatorAngle + (sectionAngle * Double(index + 1))
    }
}

struct LastMinuteSeparatorLine: View {
    let baseAngle: Double
    let rotationAngle: Double
    let center: CGPoint
    let size: CGSize
    
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
        // Remove all transitions and animations
    }
}
