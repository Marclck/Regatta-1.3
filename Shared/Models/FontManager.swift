//
//  FontManager.swift
//  Regatta
//
//  Created by Chikai Lai on 25/11/2024.
//

import Foundation
import SwiftUI

// MARK: - Custom Font Model
struct CustomFont: Identifiable, Codable {
    let id: UUID
    let fontNumber: Int
    let fileName: String
    let displayName: String
    let fileURL: URL
    let dateAdded: Date
    
    init(fontNumber: Int, fileName: String, fileURL: URL) {
        self.id = UUID()
        self.fontNumber = fontNumber
        self.fileName = fileName
        self.displayName = "Font \(fontNumber)"
        self.fileURL = fileURL
        self.dateAdded = Date()
    }
}

// MARK: - Custom Font Manager
class CustomFontManager: ObservableObject {
    static let shared = CustomFontManager()
    
    @Published var customFonts: [CustomFont] = []
    
    internal let fontsDirectory: URL  // Changed from private to internal
    private let maxFileSize: Int = 200 * 1024 // 200 KB
    private let supportedFormats = ["ttf"]
    
    private init() {
        // Create fonts directory in app's private storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fontsDirectory = documentsPath.appendingPathComponent("CustomFonts", isDirectory: true)
        
        createFontsDirectoryIfNeeded()
        loadCustomFonts()
        
        // Debug: Print directory contents
        debugPrintFontsDirectory()
    }
    
    private func createFontsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: fontsDirectory.path) {
            try? FileManager.default.createDirectory(at: fontsDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Font Import
    func importFont(from url: URL) -> Result<CustomFont, FontImportError> {
        print("🔍 Starting font import from: \(url)")
        
        // Start accessing security-scoped resource
        let hasAccess = url.startAccessingSecurityScopedResource()
        print("🔐 Security scoped resource access: \(hasAccess)")
        
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
                print("🔐 Stopped accessing security scoped resource")
            }
        }
        
        // Validate file extension
        let fileExtension = url.pathExtension.lowercased()
        print("📄 File extension: \(fileExtension)")
        guard supportedFormats.contains(fileExtension) else {
            print("❌ Unsupported format: \(fileExtension)")
            return .failure(.unsupportedFormat)
        }
        
        // Check if file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File does not exist at path: \(url.path)")
            return .failure(.fileAccessError)
        }
        
        // Check file size
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .isReadableKey])
            print("📏 File size: \(resourceValues.fileSize ?? -1) bytes")
            print("📖 File readable: \(resourceValues.isReadable ?? false)")
            
            if let fileSize = resourceValues.fileSize, fileSize > maxFileSize {
                print("❌ File too large: \(fileSize) > \(maxFileSize)")
                return .failure(.fileTooLarge)
            }
        } catch {
            print("❌ Error reading file properties: \(error)")
            return .failure(.fileAccessError)
        }
        
        // Read and validate font file
        do {
            print("📖 Attempting to read font data...")
            let fontData = try Data(contentsOf: url)
            print("✅ Successfully read \(fontData.count) bytes of font data")
            
            guard let dataProvider = CGDataProvider(data: fontData as CFData) else {
                print("❌ Failed to create CGDataProvider")
                return .failure(.invalidFontFile)
            }
            
            guard let cgFont = CGFont(dataProvider) else {
                print("❌ Failed to create CGFont from data provider")
                return .failure(.invalidFontFile)
            }
            
            print("✅ Successfully validated font file")
            
            // Generate unique font number
            let fontNumber = getNextFontNumber()
            let fileName = "font_\(fontNumber).\(fileExtension)"
            let destinationURL = fontsDirectory.appendingPathComponent(fileName)
            
            print("💾 Saving to: \(destinationURL.path)")
            
            // Copy font file to private storage
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try fontData.write(to: destinationURL)
            
            // Verify file was written correctly
            guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                print("❌ File was not written to destination")
                return .failure(.fileAccessError)
            }
            
            // Verify written file size
            let writtenSize = (try? destinationURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            print("✅ Written file size: \(writtenSize) bytes")
            
            // Register font with Core Text
            print("🔧 Registering font with Core Text...")
            var errorRef: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(destinationURL as CFURL, .process, &errorRef)
            
            if !success {
                // Clean up file if registration fails
                try? FileManager.default.removeItem(at: destinationURL)
                if let error = errorRef?.takeUnretainedValue() {
                    print("❌ Font registration error: \(error)")
                }
                return .failure(.fontRegistrationFailed)
            }
            
            print("✅ Font registered successfully with Core Text")
            
            let customFont = CustomFont(fontNumber: fontNumber, fileName: fileName, fileURL: destinationURL)
            customFonts.append(customFont)
            customFonts.sort { $0.fontNumber < $1.fontNumber }
            saveCustomFonts()
            
            print("✅ Successfully imported and registered font: \(fileName)")
            debugPrintFontsDirectory()
            
            return .success(customFont)
        } catch {
            print("❌ Error importing font: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return .failure(.fileAccessError)
        }
    }
    
    // MARK: - Font Deletion
    func deleteFont(_ font: CustomFont) {
        // Unregister font
        CTFontManagerUnregisterFontsForURL(font.fileURL as CFURL, .process, nil)
        
        // Delete file
        try? FileManager.default.removeItem(at: font.fileURL)
        
        // Remove from array
        customFonts.removeAll { $0.id == font.id }
        saveCustomFonts()
    }
    
    // MARK: - Font Loading
    private func loadCustomFonts() {
        // Debug: Check what's in UserDefaults
        let hasStoredFonts = UserDefaults.standard.data(forKey: "CustomFonts") != nil
        print("📂 Loading custom fonts... UserDefaults has stored fonts: \(hasStoredFonts)")
        
        guard let data = UserDefaults.standard.data(forKey: "CustomFonts"),
              let storedFonts = try? JSONDecoder().decode([CustomFont].self, from: data) else {
            print("📂 No stored fonts found in UserDefaults")
            return
        }
        
        print("📂 Found \(storedFonts.count) stored fonts in UserDefaults")
        
        // Validate that font files still exist and register them
        var validFonts: [CustomFont] = []
        
        for font in storedFonts {
            print("📂 Checking font: \(font.fileName) at \(font.fileURL.path)")
            
            if FileManager.default.fileExists(atPath: font.fileURL.path) {
                print("✅ Font file exists: \(font.fileName)")
                
                // Register font with Core Text
                var errorRef: Unmanaged<CFError>?
                let success = CTFontManagerRegisterFontsForURL(font.fileURL as CFURL, .process, &errorRef)
                
                if success {
                    print("✅ Successfully registered font: \(font.fileName)")
                    validFonts.append(font)
                } else {
                    print("❌ Failed to register font: \(font.fileName)")
                    if let error = errorRef?.takeUnretainedValue() {
                        print("❌ Registration error: \(error)")
                    }
                }
            } else {
                print("❌ Font file missing: \(font.fileName) at \(font.fileURL.path)")
            }
        }
        
        customFonts = validFonts.sorted { $0.fontNumber < $1.fontNumber }
        
        // Save the validated fonts back to UserDefaults
        if validFonts.count != storedFonts.count {
            saveCustomFonts()
        }
        
        print("📂 Loaded \(validFonts.count) valid fonts")
    }
    
    private func saveCustomFonts() {
        do {
            let data = try JSONEncoder().encode(customFonts)
            UserDefaults.standard.set(data, forKey: "CustomFonts")
            UserDefaults.standard.synchronize()
            print("💾 Saved \(customFonts.count) fonts to UserDefaults")
        } catch {
            print("❌ Failed to save fonts to UserDefaults: \(error)")
        }
    }
    
    // MARK: - Debug Helper
    private func debugPrintFontsDirectory() {
        print("📁 Fonts directory: \(fontsDirectory.path)")
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: fontsDirectory.path)
            print("📁 Directory contents: \(contents)")
            
            for file in contents {
                let fileURL = fontsDirectory.appendingPathComponent(file)
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("📁   - \(file) (\(fileSize) bytes)")
            }
        } catch {
            print("❌ Error reading fonts directory: \(error)")
        }
    }
    
    private func getNextFontNumber() -> Int {
        let usedNumbers = Set(customFonts.map { $0.fontNumber })
        var number = 1
        while usedNumbers.contains(number) {
            number += 1
        }
        return number
    }
    
    // MARK: - Font Creation
    func createFont(from customFont: CustomFont, size: CGFloat, weight: Font.Weight = .regular) -> Font? {
        guard let fontData = try? Data(contentsOf: customFont.fileURL),
              let dataProvider = CGDataProvider(data: fontData as CFData),
              let cgFont = CGFont(dataProvider),
              let fontName = cgFont.postScriptName else {
            return nil
        }
        
        let uiFontWeight = convertToUIFontWeight(weight)
        
        // Create font descriptor with weight
        let fontDescriptor = UIFontDescriptor(name: String(fontName), size: size)
        let traits: [UIFontDescriptor.TraitKey: Any] = [
            .weight: uiFontWeight.rawValue
        ]
        
        let descriptorWithTraits = fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: traits
        ])
        
        let uiFont = UIFont(descriptor: descriptorWithTraits, size: size)
        return Font(uiFont)
    }
    
    // MARK: - Font Data Saving (for watchOS sync)
    #if os(watchOS)
    func saveFontData(_ data: Data, fontNumber: Int, fileName: String, fontId: String) -> Result<CustomFont, FontImportError> {
        print("⌚️ Starting to save font data: \(fileName) (\(data.count) bytes)")
        
        // Validate font data
        guard let dataProvider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(dataProvider) else {
            print("❌ Invalid font data for: \(fileName)")
            return .failure(.invalidFontFile)
        }
        
        print("✅ Font data validated for: \(fileName)")
        
        // Create destination URL
        let destinationURL = fontsDirectory.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                print("⌚️ Removing existing font file: \(fileName)")
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Write font data
            try data.write(to: destinationURL)
            print("✅ Font file written to: \(destinationURL.path)")
            
            // Verify file was written
            guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                print("❌ Font file verification failed: \(fileName)")
                return .failure(.fileAccessError)
            }
            
            // Check if font is already registered by trying to unregister it first
            print("⌚️ Checking if font is already registered...")
            CTFontManagerUnregisterFontsForURL(destinationURL as CFURL, .process, nil)
            
            // Now register the font
            print("⌚️ Registering font with Core Text...")
            var errorRef: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(destinationURL as CFURL, .process, &errorRef)
            
            if !success {
                // Get detailed error information
                if let error = errorRef?.takeUnretainedValue() {
                    let nsError = error as Error as NSError
                    print("❌ Font registration failed:")
                    print("   Domain: \(nsError.domain)")
                    print("   Code: \(nsError.code)")
                    print("   Description: \(nsError.localizedDescription)")
                    print("   UserInfo: \(nsError.userInfo)")
                }
                
                // Don't fail if error code 105 (font already registered) or 305
                if let error = errorRef?.takeUnretainedValue() {
                    let nsError = error as Error as NSError
                    if nsError.code == 105 || nsError.code == 305 {
                        print("⚠️ Font registration issue (code \(nsError.code)), but continuing anyway")
                        // Continue with font creation even if registration "failed"
                    } else {
                        // Clean up file for other errors
                        try? FileManager.default.removeItem(at: destinationURL)
                        return .failure(.fontRegistrationFailed)
                    }
                } else {
                    // Clean up file if registration fails with unknown error
                    try? FileManager.default.removeItem(at: destinationURL)
                    return .failure(.fontRegistrationFailed)
                }
            } else {
                print("✅ Font registered successfully with Core Text")
            }
            
            // Create CustomFont object
            let customFont = CustomFont(fontNumber: fontNumber, fileName: fileName, fileURL: destinationURL)
            
            // Update or add to customFonts array
            if let existingIndex = customFonts.firstIndex(where: { $0.fontNumber == fontNumber }) {
                print("⌚️ Updating existing font at index \(existingIndex)")
                customFonts[existingIndex] = customFont
            } else {
                print("⌚️ Adding new font to collection")
                customFonts.append(customFont)
            }
            
            // Sort and save
            customFonts.sort { $0.fontNumber < $1.fontNumber }
            saveCustomFonts()
            
            print("✅ Successfully saved and processed font: \(fileName)")
            print("⌚️ Total fonts now: \(customFonts.count)")
            
            return .success(customFont)
            
        } catch {
            print("❌ Error saving font data: \(error)")
            return .failure(.fileAccessError)
        }
    }
    #endif
    
    // Helper function to convert SwiftUI Font.Weight to UIFont.Weight
    private func convertToUIFontWeight(_ weight: Font.Weight) -> UIFont.Weight {
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
}

// MARK: - Font Import Error
enum FontImportError: LocalizedError {
    case unsupportedFormat
    case fileTooLarge
    case invalidFontFile
    case fileAccessError
    case fontRegistrationFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Only TTF font files are supported. Please select a .ttf file."
        case .fileTooLarge:
            return "Font file must be smaller than 200 KB. Please choose a smaller font file."
        case .invalidFontFile:
            return "The selected file is not a valid font file or is corrupted."
        case .fileAccessError:
            return "Unable to access the font file. Please try selecting the file again."
        case .fontRegistrationFailed:
            return "Failed to register the font with the system. The font may already be installed or corrupted."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unsupportedFormat:
            return "Convert your font to TTF format using a font converter."
        case .fileTooLarge:
            return "Try using a font compression tool or choose a different font."
        case .invalidFontFile:
            return "Verify the font file is not corrupted and try downloading it again."
        case .fileAccessError:
            return "Make sure the file is accessible and try again."
        case .fontRegistrationFailed:
            return "Try restarting the app or choose a different font."
        }
    }
}

// MARK: - Original Font Extension (Updated)
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
    
    // MARK: - Custom Font Creation
    static func customFont(_ customFont: CustomFont, size: CGFloat, weight: Font.Weight = .regular) -> Font? {
        return CustomFontManager.shared.createFont(from: customFont, size: size, weight: weight)
    }
}
