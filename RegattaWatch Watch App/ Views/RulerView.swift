//
//  RulerView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 22/02/2025.
//

import Foundation
import SwiftUI

struct RulerView: View {
    let numberOfSegments: Int
    let width: CGFloat
    
    // Computed properties for responsive sizing
    private var spacing: CGFloat {
        width / CGFloat(numberOfSegments)
    }
    
    private var tickWidth: CGFloat {
        max(1, spacing * 0.2) // Ensure tick is never thinner than 1pt
    }
    
    private var maxHeight: CGFloat {
        width * 0.1 // Height is 10% of total width
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<numberOfSegments, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: tickWidth, height: getTickHeight(for: index))
                        .frame(height: maxHeight, alignment: .bottom)
                        .offset(x: CGFloat(index) * spacing)
                }
            }
        }
        .frame(width: width, height: maxHeight)
    }
    
    private func getTickHeight(for index: Int) -> CGFloat {
        if index % 8 == 0 {
            return maxHeight // Full height
        } else if index % 4 == 0 {
            return maxHeight * 0.75 // 75% height
        } else {
            return maxHeight * 0.5 // 50% height
        }
    }
}

struct RulerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Small ruler with fewer segments
            RulerView(numberOfSegments: 9, width: 25)
                .previewDisplayName("Small Ruler")
            
            // Medium ruler
            RulerView(numberOfSegments: 32, width: 300)
                .previewDisplayName("Medium Ruler")
            
            // Large ruler with many segments
            RulerView(numberOfSegments: 48, width: 400)
                .previewDisplayName("Large Ruler")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
