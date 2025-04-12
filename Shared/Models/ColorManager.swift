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
    case cambridgeBlue = "9bbea9" //9bbea9 or A0C1AB
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
    // Add this static shared property
    static let shared = ColorManager()
    
    // Static method to use SharedDefaults
    static func getCurrentThemeColor() -> Color {
        let theme = SharedDefaults.getTheme()
        return Color(hex: theme.rawValue)
    }
    
    @Published var selectedTheme: ColorTheme {
        didSet {
            SharedDefaults.saveTheme(selectedTheme)
            #if os(watchOS)
            // Instead of sending directly, notify WatchSessionManager
            notifyThemeChanged()
            #endif
        }
    }
    
    // Queue for message sending
    private let queue = DispatchQueue(label: "com.heart.astrolabe.colormanager")
    
    // Keep the constructor public for now, but consider making it private later
    override init() {
        // Use SharedDefaults for initialization
        self.selectedTheme = SharedDefaults.getTheme()
        super.init()
    }
    
#if os(watchOS)
// Add this method instead of the previous sendToPhone
private func notifyThemeChanged() {
    // Let WatchSessionManager handle the communication
    WatchSessionManager.shared.sendThemeUpdate(theme: selectedTheme)
}
    
#endif
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


/*
#if os(watchOS)
extension ColorManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("⌚️ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("⌚️ WCSession activated with state: \(activationState.rawValue)")
            
            // Send current theme when session activates
            if activationState == .activated {
                sendToPhone()
            }
        }
    }
    
    // For completeness, handle incoming messages from iPhone if needed
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // We don't expect theme updates from the iPhone, but handle for completeness
        if let messageType = message["messageType"] as? String, messageType == "theme_update",
           let themeString = message["selectedTheme"] as? String,
           let newTheme = ColorTheme(rawValue: themeString) {
            
            DispatchQueue.main.async {
                print("⌚️ Received theme update from iPhone: \(newTheme.name)")
                self.selectedTheme = newTheme
            }
            
            replyHandler(["status": "success", "message": "Theme updated on Watch"])
        } else {
            replyHandler(["status": "ignored", "message": "Not a theme message"])
        }
    }
}
#endif
*/

