//
//  FontManager.swift
//  Regatta
//
//  Created by Chikai Lai on 25/11/2024.
//

import Foundation
import SwiftUI

extension Font {
    static func zenithBeta(size: CGFloat) -> Font {
        // Base font descriptor with system font
        let baseDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        
        // Create traits dictionary with width
        let traits = [
            UIFontDescriptor.TraitKey.width: 0.13
        ]
        
        // Add width trait to the descriptor
        let descriptorWithTrait = baseDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: traits
        ])
        
        // Add stylistic alternate features
        let fontDescriptor = descriptorWithTrait.addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kStylisticAlternativesType,
                    UIFontDescriptor.FeatureKey.selector: kStylisticAltOneOnSelector
                ],
                [
                    UIFontDescriptor.FeatureKey.type: kStylisticAlternativesType,
                    UIFontDescriptor.FeatureKey.selector: kStylisticAltTwoOnSelector
                ]
            ]
        ])
        
        // Create a UIFont from the descriptor with the specified size
        let uiFont = UIFont(descriptor: fontDescriptor, size: size)
        
        // Convert to SwiftUI Font
        return Font(uiFont)
    }
    
    // Optional: Keep the original property for default size
    static var zenithBeta: Font {
        zenithBeta(size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    }
}
