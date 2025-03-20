//
//  MapUIButtonExtention.swift
//  Regatta
//
//  Created by Chikai Lai on 19/03/2025.
//

import Foundation
import UIKit
import SwiftUI

extension UIButton {
    /// Creates a custom map control button with standardized styling
    /// - Parameters:
    ///   - imageName: SF Symbol name for the button icon
    ///   - target: Target object that will receive the action
    ///   - action: Selector to be called when button is tapped
    ///   - tintColor: Optional custom tint color for the button icon
    /// - Returns: Configured UIButton instance ready for auto layout constraints
    public static func createMapControlButton(
        imageName: String,
        target: Any?,
        action: Selector,
        tintColor: UIColor? = nil
    ) -> UIButton {
        let button = UIButton(type: .system)
        
        // Configure the image with proper sizing
        if let image = UIImage(systemName: imageName) {
            // Create a configuration for the icon
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            let scaledImage = image.withConfiguration(config)
            button.setImage(scaledImage, for: .normal)
        }
        
        // Style the button
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        if let customTint = tintColor {
            button.tintColor = customTint
        } else {
            button.tintColor = UIColor(Color(hex: ColorTheme.ultraBlue.rawValue))
        }
        button.layer.cornerRadius = 8
        
        // Important: Let Auto Layout handle sizing
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set target and action
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}
