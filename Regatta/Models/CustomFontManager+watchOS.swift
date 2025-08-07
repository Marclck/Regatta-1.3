//
//  CustomFontManager+watchOS.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 07/08/2025.
//

import Foundation
import SwiftUI

#if os(watchOS)
// MARK: - watchOS Font Saving Extension
extension CustomFontManager {
    
    // Save font data received from iOS
    func saveFontData(_ data: Data, fontNumber: Int, fileName: String, fontId: String) -> Result<CustomFont, FontImportError> {
        // Validate font data
        guard let dataProvider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(dataProvider) else {
            return .failure(.invalidFontFile)
        }
        
        // Create destination URL
        let destinationURL = fontsDirectory.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Write font data
            try data.write(to: destinationURL)
            
            // Verify file was written
            guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                return .failure(.fileAccessError)
            }
            
            // Register font with Core Text
            var errorRef: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(destinationURL as CFURL, .process, &errorRef)
            
            if !success {
                // Clean up file if registration fails
                try? FileManager.default.removeItem(at: destinationURL)
                if let error = errorRef?.takeUnretainedValue() {
                    print("⌚️ Font registration error: \(error)")
                }
                return .failure(.fontRegistrationFailed)
            }
            
            // Create CustomFont object
            let customFont = CustomFont(fontNumber: fontNumber, fileName: fileName, fileURL: destinationURL)
            
            // Update or add to customFonts array
            if let existingIndex = customFonts.firstIndex(where: { $0.fontNumber == fontNumber }) {
                // Update existing font
                customFonts[existingIndex] = customFont
            } else {
                // Add new font
                customFonts.append(customFont)
            }
            
            // Sort and save
            customFonts.sort { $0.fontNumber < $1.fontNumber }
            saveCustomFonts()
            
            print("✅ Successfully saved and registered font: \(fileName)")
            
            return .success(customFont)
            
        } catch {
            print("❌ Error saving font data: \(error)")
            return .failure(.fileAccessError)
        }
    }
    
    // MARK: - Access to Directory (for watchOS)
    var fontsDirectoryForWatch: URL {
        return fontsDirectory
    }
}
#endif
