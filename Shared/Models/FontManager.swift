//
//  FontManager.swift
//  Regatta
//
//  Created by Chikai Lai on 25/11/2024.
//

import Foundation
import SwiftUI

extension Font {
    static func zenithBeta(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Base font descriptor with system font
        let baseDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        
        // Convert SwiftUI Font.Weight to UIFont.Weight
        let uiFontWeight = convertToUIFontWeight(weight)
        
        // Create traits dictionary with width and weight
        let traits: [UIFontDescriptor.TraitKey: Any] = [
            .width: 0.13,
            .weight: uiFontWeight.rawValue
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
    
    // Helper function to convert SwiftUI Font.Weight to UIFont.Weight
    private static func convertToUIFontWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        default:
            return .regular
        }
    }
    
    
    // Optional: Keep the original property for default size
    static var zenithBeta: Font {
        zenithBeta(size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    }
}
