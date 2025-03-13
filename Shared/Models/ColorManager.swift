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
    // Static method to use SharedDefaults
    static func getCurrentThemeColor() -> Color {
        let theme = SharedDefaults.getTheme()
        return Color(hex: theme.rawValue)
    }
    
    @Published var selectedTheme: ColorTheme {
        didSet {
            SharedDefaults.saveTheme(selectedTheme)
            #if os(watchOS)
            sendToPhone()
            #endif
        }
    }
    
    // Queue for message sending
    private let queue = DispatchQueue(label: "com.heart.astrolabe.colormanager")
    
    override init() {
        // Use SharedDefaults for initialization
        self.selectedTheme = SharedDefaults.getTheme()
        super.init()
        
        #if os(iOS)
        setupWatchConnection()
        #elseif os(watchOS)
        setupPhoneConnection()
        #endif
    }
    
#if os(watchOS)
    private func setupPhoneConnection() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    private func sendToPhone() {
        guard WCSession.default.activationState == .activated else {
            print("⌚️ Phone session not activated, can't send theme")
            return
        }
        
        queue.async {
            let message: [String: Any] = [
                "messageType": "theme_update",
                "selectedTheme": self.selectedTheme.rawValue
            ]
            
            if WCSession.default.isReachable {
                // Use sendMessage with reply handler
                WCSession.default.sendMessage(message, replyHandler: { reply in
                    print("⌚️ Theme sent successfully to phone: \(reply)")
                }) { error in
                    print("⌚️ Error sending theme to phone: \(error.localizedDescription)")
                    
                    // Fall back to application context if messaging fails
                    do {
                        try WCSession.default.updateApplicationContext(message)
                        print("⌚️ Theme sent via application context as fallback")
                    } catch {
                        print("⌚️ Failed to send theme via application context: \(error.localizedDescription)")
                    }
                }
            } else {
                // Fall back to application context if not reachable
                do {
                    try WCSession.default.updateApplicationContext(message)
                    print("⌚️ Phone not reachable, sent theme via application context")
                } catch {
                    print("⌚️ Failed to send theme via application context: \(error.localizedDescription)")
                }
            }
        }
    }
#endif

#if os(iOS)
    private func setupWatchConnection() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
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

#if os(iOS)
extension ColorManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("📱 WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("📱 WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WCSession deactivated - reactivating")
        WCSession.default.activate()
    }
    
    // Handle incoming theme messages from watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let messageType = message["messageType"] as? String, messageType == "theme_update",
           let themeString = message["selectedTheme"] as? String,
           let newTheme = ColorTheme(rawValue: themeString) {
            
            DispatchQueue.main.async {
                print("📱 Received theme update from watch: \(newTheme.name)")
                self.selectedTheme = newTheme
            }
            
            replyHandler(["status": "success", "message": "Theme updated on iPhone"])
        } else {
            replyHandler(["status": "ignored", "message": "Not a theme message"])
        }
    }
    
    // Keep application context as a fallback
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let messageType = applicationContext["messageType"] as? String, messageType == "theme_update",
           let themeString = applicationContext["selectedTheme"] as? String,
           let newTheme = ColorTheme(rawValue: themeString) {
            
            DispatchQueue.main.async {
                print("📱 Received theme update via application context: \(newTheme.name)")
                self.selectedTheme = newTheme
            }
        }
    }
}
#endif

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
