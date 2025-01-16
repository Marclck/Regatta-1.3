//
//  ColorManager.swift
//  Regatta
//
//  Created by Chikai Lai on 06/12/2024.
//

import Foundation
import SwiftUI
#if os(iOS)
import WatchConnectivity
#elseif os(watchOS)
import WatchConnectivity
#endif

enum ColorTheme: String, CaseIterable, Codable {
    case cambridgeBlue = "A0C1AB"
    case ultraBlue = "47BBFC"    // Adding cyan as Ultra Blue
    case brittanBlue = "#8FCB5A"
    case marimbaBlue = "049DFE"
    case racingRed = "C9293E"
    case kiwiBlue = "01EAF8"
    case speedPapaya = "D5791C"
    case signalOrange = "F37021"
    case marineYellow = "F6A726"
    
    var name: String {
        switch self {
        case .cambridgeBlue: return "Cambridge Blue"
        case .ultraBlue: return "Ultra Blue"    // Add this case
        case .brittanBlue: return "Brittan Blue"
        case .marimbaBlue: return "Marimba Blue"
        case .racingRed: return "Racing Red"
        case .kiwiBlue: return "Kiwi Blue"
        case .speedPapaya: return "Speed Papaya"
        case .signalOrange: return "Signal Orange"
        case .marineYellow: return "Marine Yellow"
        }
    }
}

class ColorManager: NSObject, ObservableObject {
    // Remove this as we're using SharedDefaults.shared instead
    // static let sharedDefaults = UserDefaults(suiteName: "group.com.heart.astrolabe")!
    
    // Update static method to use SharedDefaults
    static func getCurrentThemeColor() -> Color {
        let theme = SharedDefaults.getTheme()
        return Color(hex: theme.rawValue)
    }
    
    @Published var selectedTheme: ColorTheme {
        didSet {
            SharedDefaults.saveTheme(selectedTheme)
            #if os(iOS)
            sendToWatch()
            #endif
        }
    }
    
    // Remove this as it's now handled in SharedDefaults
    // private let themeKey = "selectedTheme"
    
    override init() {
        // Update to use SharedDefaults
        self.selectedTheme = SharedDefaults.getTheme()
        super.init()
        
        #if os(iOS)
        setupWatchConnection()
        #endif
    }
    
#if os(iOS)
private func setupWatchConnection() {
    if WCSession.isSupported() {
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
}

private func sendToWatch() {
    guard WCSession.default.isReachable else { return }
    
    do {
        try WCSession.default.updateApplicationContext([
            "selectedTheme": selectedTheme.rawValue
        ])
    } catch {
        print("Error sending theme to watch: \(error.localizedDescription)")
    }
}
#endif
    
    // Remove this as it's now handled in SharedDefaults.saveTheme
    // private func saveTheme() {
    //     ColorManager.sharedDefaults.set(selectedTheme.rawValue, forKey: themeKey)
    // }
    
    // Rest of the code remains the same...
}




extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#if os(iOS)
extension ColorManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation
        WCSession.default.activate()
    }
}
#endif

#if os(watchOS)
extension ColorManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let themeString = applicationContext["selectedTheme"] as? String,
           let newTheme = ColorTheme(rawValue: themeString) {
            DispatchQueue.main.async {
                self.selectedTheme = newTheme
            }
        }
    }
}
#endif
