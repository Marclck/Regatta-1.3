//
//  SeparatorMark.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import Foundation
import SwiftUI

struct SeparatorMark: Shape {
    let angle: Double
    let size: CGSize
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let markLength: CGFloat = 24  // Increased length
        let markWidth: CGFloat = 4    // Increased width
        
        // Calculate position on the screen edge
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius = max(size.width, size.height) / 2
        
        let angleInRadians = angle * .pi / 180
        
        let startPoint = CGPoint(
            x: centerX + (radius - markWidth) * cos(CGFloat(angleInRadians)),
            y: centerY + (radius - markWidth) * sin(CGFloat(angleInRadians))
        )
        
        let endPoint = CGPoint(
            x: centerX + (radius + markLength) * cos(CGFloat(angleInRadians)),
            y: centerY + (radius + markLength) * sin(CGFloat(angleInRadians))
        )
        
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        path.addRect(CGRect(x: startPoint.x - markWidth/2,
                          y: startPoint.y - markWidth/2,
                          width: markWidth,
                          height: markLength))
        
        return path
    }
}
