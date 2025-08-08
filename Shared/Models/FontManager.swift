//
//  FontManager.swift
//  Regatta
//
//  Created by Chikai Lai on 25/11/2024.
// Updated to store font data in UserDefaults for better watchOS persistence

import Foundation
import SwiftUI

// MARK: - Custom Font Model
struct CustomFont: Identifiable, Codable {
    let id: UUID
    let fontNumber: Int
    let fileName: String
    let displayName: String
    let fontData: Data  // Store the actual font data
    let dateAdded: Date
    
    init(fontNumber: Int, fileName: String, fontData: Data) {
        self.id = UUID()
        self.fontNumber = fontNumber
        self.fileName = fileName
        self.displayName = "Font \(fontNumber)"
        self.fontData = fontData
        self.dateAdded = Date()
    }
    
    // Computed property to create temporary URL when needed
    var temporaryURL: URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(fileName)
        
        // Write data to temp file if it doesn't exist
        if !FileManager.default.fileExists(atPath: tempURL.path) {
            try? fontData.write(to: tempURL)
        }
        
        return tempURL
    }
}

// MARK: - Custom Font Manager
class CustomFontManager: ObservableObject {
    static let shared = CustomFontManager()
    
    @Published var customFonts: [CustomFont] = []
    
    private let maxFileSize: Int = 200 * 1024 // 200 KB
    private let supportedFormats = ["ttf"]
    
    private init() {
        loadCustomFonts()
        
        #if os(watchOS)
        // Additional setup for watchOS persistence
        setupWatchOSPersistence()
        #endif
    }
    
    #if os(watchOS)
    private func setupWatchOSPersistence() {
        print("⌚️ Setting up watchOS persistence...")
        
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(
            forName: .NSExtensionHostWillEnterForeground,
            object: nil,
            queue: .main
        ) { _ in
            print("⌚️ App entering foreground - checking font persistence")
            self.verifyFontPersistence()
        }
    }
    
    private func verifyFontPersistence() {
        print("⌚️ Verifying font persistence...")
        print("⌚️ Expected fonts count: \(customFonts.count)")
        
        // Since we store data in UserDefaults, just verify the fonts are still in memory
        // and try to re-register them if needed
        for font in customFonts {
            let tempURL = font.temporaryURL
            if !FileManager.default.fileExists(atPath: tempURL.path) {
                print("⌚️ Recreating temp file for: \(font.fileName)")
                // The temporaryURL property will recreate the file automatically
                _ = font.temporaryURL
            }
        }
        
        print("⌚️ Font persistence verification complete")
    }
    #endif
    
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
            
            // Create CustomFont object with data stored directly
            let customFont = CustomFont(fontNumber: fontNumber, fileName: fileName, fontData: fontData)
            
            // Register font using temporary URL
            let tempURL = customFont.temporaryURL
            print("🔧 Registering font with Core Text from temp URL: \(tempURL.path)")
            
            var errorRef: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(tempURL as CFURL, .process, &errorRef)
            
            if !success {
                if let error = errorRef?.takeUnretainedValue() {
                    print("❌ Font registration error: \(error)")
                }
                return .failure(.fontRegistrationFailed)
            }
            
            print("✅ Font registered successfully with Core Text")
            
            customFonts.append(customFont)
            customFonts.sort { $0.fontNumber < $1.fontNumber }
            saveCustomFonts()
            
            print("✅ Successfully imported and registered font: \(fileName)")
            
            return .success(customFont)
        } catch {
            print("❌ Error importing font: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return .failure(.fileAccessError)
        }
    }
    
    // MARK: - Font Deletion
    func deleteFont(_ font: CustomFont) {
        // Try to unregister using temporary URL
        let tempURL = font.temporaryURL
        CTFontManagerUnregisterFontsForURL(tempURL as CFURL, .process, nil)
        
        // Clean up temp file if it exists
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
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
        
        // Register fonts using temporary URLs
        for font in storedFonts {
            print("📂 Registering font: \(font.fileName)")
            
            let tempURL = font.temporaryURL
            var errorRef: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(tempURL as CFURL, .process, &errorRef)
            
            if success {
                print("✅ Successfully registered font: \(font.fileName)")
            } else {
                print("❌ Failed to register font: \(font.fileName)")
                if let error = errorRef?.takeUnretainedValue() {
                    print("❌ Registration error: \(error)")
                }
            }
        }
        
        customFonts = storedFonts.sorted { $0.fontNumber < $1.fontNumber }
        print("📂 Loaded \(customFonts.count) fonts")
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
        guard let dataProvider = CGDataProvider(data: customFont.fontData as CFData),
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
        
        // Create CustomFont object with data stored directly
        let customFont = CustomFont(fontNumber: fontNumber, fileName: fileName, fontData: data)
        
        // Try to register the font using temporary URL
        let tempURL = customFont.temporaryURL
        
        print("⌚️ Registering font with Core Text from temp URL...")
        var errorRef: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(tempURL as CFURL, .process, &errorRef)
        
        print("⌚️ Registration call completed. Success: \(success)")
        
        if !success {
            if let error = errorRef?.takeUnretainedValue() {
                let nsError = error as Error as NSError
                print("⚠️ Registration failed (code \(nsError.code)), but continuing with data storage")
                // Don't fail - we have the data stored
            }
        } else {
            print("✅ Font registered successfully with Core Text")
        }
        
        // Update or add to customFonts array
        if let existingIndex = customFonts.firstIndex(where: { $0.fontNumber == fontNumber }) {
            print("⌚️ Updating existing font at index \(existingIndex)")
            customFonts[existingIndex] = customFont
        } else {
            print("⌚️ Adding new font to collection")
            customFonts.append(customFont)
        }
        
        // Sort and save to UserDefaults
        customFonts.sort { $0.fontNumber < $1.fontNumber }
        saveCustomFonts()
        
        print("✅ Successfully saved font data to UserDefaults: \(fileName)")
        print("⌚️ Total fonts now: \(customFonts.count)")
        
        return .success(customFont)
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

// MARK: - Font Extension
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
