//
//  ScreenEdgePath.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import Foundation
import SwiftUI

import SwiftUI

struct ScreenEdgePath: Shape {
    let size: CGSize
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Use entire screen dimensions
        let width = size.width
        let height = size.height
        let cornerRadius: CGFloat = 40
        
        // Start from top left corner
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        
        // Left edge to top left corner
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(180),
                   endAngle: .degrees(270),
                   clockwise: false)
        
        // Top edge
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        
        // Top right corner
        path.addArc(center: CGPoint(x: width - cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(270),
                   endAngle: .degrees(0),
                   clockwise: false)
        
        // Right edge
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        
        // Bottom right corner
        path.addArc(center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(0),
                   endAngle: .degrees(90),
                   clockwise: false)
        
        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        
        // Bottom left corner
        path.addArc(center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(90),
                   endAngle: .degrees(180),
                   clockwise: false)
        
        // Close the path
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        
        return path
    }
}
