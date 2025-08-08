//
//  WatchSessionManager+FontSync.swift
//  Regatta
//
//  Created by Chikai Lai on 07/08/2025.
//

import Foundation
import WatchConnectivity

#if os(iOS)
// MARK: - Font Sync Extension for iOS
extension WatchSessionManager {
    
    // MARK: - Font Sync Status
    enum FontSyncStatus {
        case idle
        case syncing(currentFont: Int, totalFonts: Int, fontName: String)
        case success(syncedCount: Int)
        case error(String)
        case partialSuccess(syncedCount: Int, totalCount: Int, failedFonts: [String])
    }
    
    // Computed property to safely access the session
    private var wcSession: WCSession? {
        return WCSession.default
    }
    
    // MARK: - Font Sync Public Methods
    func syncFontsToWatch() {
        guard let session = wcSession, session.activationState == .activated else {
            notifyFontSyncStatus(.error("Watch session not activated"))
            return
        }
        
        let fonts = CustomFontManager.shared.customFonts
        guard !fonts.isEmpty else {
            notifyFontSyncStatus(.error("No fonts to sync"))
            return
        }
        
        print("📱 Starting font sync to watch: \(fonts.count) fonts")
        notifyFontSyncStatus(.syncing(currentFont: 0, totalFonts: fonts.count, fontName: "Preparing..."))
        
        // Use background queue for font transfer
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.transferFontsToWatch(fonts, session: session)
        }
    }
    
    // MARK: - Private Font Transfer Methods
    private func transferFontsToWatch(_ fonts: [CustomFont], session wcSession: WCSession) {
        var syncedFonts: [String] = []
        var failedFonts: [String] = []
        
        // First, send font list metadata
        sendFontListMetadata(fonts, session: wcSession)
        
        // Then transfer each font
        for (index, font) in fonts.enumerated() {
            autoreleasepool {
                DispatchQueue.main.async {
                    self.notifyFontSyncStatus(.syncing(
                        currentFont: index + 1,
                        totalFonts: fonts.count,
                        fontName: font.displayName
                    ))
                }
                
                let result = transferSingleFont(font, index: index, total: fonts.count, session: wcSession)
                
                switch result {
                case .success:
                    syncedFonts.append(font.displayName)
                    print("✅ Successfully synced font: \(font.displayName)")
                case .failure(let error):
                    failedFonts.append(font.displayName)
                    print("❌ Failed to sync font \(font.displayName): \(error)")
                }
                
                // Small delay between transfers
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        
        // Send completion message
        sendFontSyncCompletion(syncedCount: syncedFonts.count, totalCount: fonts.count, session: wcSession)
        
        // Notify final status
        DispatchQueue.main.async {
            if failedFonts.isEmpty {
                self.notifyFontSyncStatus(.success(syncedCount: syncedFonts.count))
            } else {
                self.notifyFontSyncStatus(.partialSuccess(
                    syncedCount: syncedFonts.count,
                    totalCount: fonts.count,
                    failedFonts: failedFonts
                ))
            }
        }
    }
    
    private func sendFontListMetadata(_ fonts: [CustomFont], session wcSession: WCSession) {
        let fontMetadata = fonts.map { font in
            return [
                "id": font.id.uuidString,
                "fontNumber": font.fontNumber,
                "fileName": font.fileName,
                "displayName": font.displayName,
                "dateAdded": font.dateAdded.timeIntervalSince1970
            ]
        }
        
        let message: [String: Any] = [
            "messageType": "font_list_metadata",
            "fonts": fontMetadata,
            "totalFonts": fonts.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if wcSession.isReachable {
            wcSession.sendMessage(message, replyHandler: { reply in
                print("📱 Font list metadata sent successfully: \(reply)")
            }, errorHandler: { error in
                print("📱 Failed to send font list metadata: \(error)")
                wcSession.transferUserInfo(message)
            })
        } else {
            wcSession.transferUserInfo(message)
        }
    }
    
    // Replace the transferSingleFont method in WatchSessionManager+FontSync.swift

    private func transferSingleFont(_ font: CustomFont, index: Int, total: Int, session wcSession: WCSession) -> Result<Void, Error> {
        do {
            // Use font data directly instead of reading from file
            let fontData = font.fontData
            
            // Transfer in chunks (same strategy as session data)
            let chunkSize = 8192 // 8KB chunks for font data
            let totalChunks = Int(ceil(Double(fontData.count) / Double(chunkSize)))
            
            print("📱 Transferring font \(font.displayName) in \(totalChunks) chunks")
            
            for chunkIndex in 0..<totalChunks {
                let startIndex = chunkIndex * chunkSize
                let endIndex = min(startIndex + chunkSize, fontData.count)
                let chunkData = fontData.subdata(in: startIndex..<endIndex)
                
                let message: [String: Any] = [
                    "messageType": "font_data_chunk",
                    "fontId": font.id.uuidString,
                    "fontNumber": font.fontNumber,
                    "fileName": font.fileName,
                    "displayName": font.displayName,
                    "chunkIndex": chunkIndex,
                    "totalChunks": totalChunks,
                    "chunkData": chunkData,
                    "fontIndex": index,
                    "totalFonts": total,
                    "isLastChunk": chunkIndex == totalChunks - 1
                ]
                
                // Send chunk with timeout
                let semaphore = DispatchSemaphore(value: 0)
                var sendSuccess = false
                
                if wcSession.isReachable {
                    wcSession.sendMessage(message, replyHandler: { reply in
                        sendSuccess = true
                        semaphore.signal()
                    }, errorHandler: { error in
                        print("📱 Failed to send font chunk \(chunkIndex): \(error)")
                        semaphore.signal()
                    })
                    
                    let result = semaphore.wait(timeout: .now() + 10.0)
                    
                    if result == .timedOut || !sendSuccess {
                        // Fallback to UserInfo for this chunk
                        wcSession.transferUserInfo(message)
                        Thread.sleep(forTimeInterval: 1.0) // Longer delay for UserInfo
                    }
                } else {
                    wcSession.transferUserInfo(message)
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
            
            return .success(())
            
        } catch {
            return .failure(error)
        }
    }
    
    private func sendFontSyncCompletion(syncedCount: Int, totalCount: Int, session wcSession: WCSession) {
        let message: [String: Any] = [
            "messageType": "font_sync_complete",
            "syncedCount": syncedCount,
            "totalCount": totalCount,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if wcSession.isReachable {
            wcSession.sendMessage(message, replyHandler: { reply in
                print("📱 Font sync completion sent: \(reply)")
            }, errorHandler: { error in
                print("📱 Failed to send font sync completion: \(error)")
                wcSession.transferUserInfo(message)
            })
        } else {
            wcSession.transferUserInfo(message)
        }
    }
    
    private func notifyFontSyncStatus(_ status: FontSyncStatus) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("FontSyncStatusUpdate"),
                object: status
            )
        }
    }
}

// MARK: - Font Sync Error
enum FontSyncError: LocalizedError {
    case sessionNotAvailable
    case fontFileNotFound
    case transferFailed
    
    var errorDescription: String? {
        switch self {
        case .sessionNotAvailable:
            return "Watch session not available"
        case .fontFileNotFound:
            return "Font file not found"
        case .transferFailed:
            return "Font transfer failed"
        }
    }
}

#else

// MARK: - Font Sync Extension for watchOS
extension WatchSessionManager {
    
    // MARK: - Font Reception Data
    private struct ReceivingFontData {
        var metadata: [String: Any]
        var chunks: [Int: Data]
        var totalChunks: Int
        var receivedChunks: Set<Int>
        
        var isComplete: Bool {
            return receivedChunks.count == totalChunks
        }
        
        var completeData: Data? {
            guard isComplete else { return nil }
            
            var combinedData = Data()
            for i in 0..<totalChunks {
                if let chunkData = chunks[i] {
                    combinedData.append(chunkData)
                }
            }
            return combinedData
        }
    }
    
    // Track receiving fonts
    private static var receivingFonts: [String: ReceivingFontData] = [:]
    
    // Process font messages from iOS
    func processFontMessage(_ message: [String: Any]) {
        guard let messageType = message["messageType"] as? String else { return }
        
        switch messageType {
        case "font_list_metadata":
            processFontListMetadata(message)
        case "font_data_chunk":
            processFontDataChunk(message)
        case "font_sync_complete":
            processFontSyncComplete(message)
        default:
            break
        }
    }
    
    private func processFontListMetadata(_ message: [String: Any]) {
        guard let fontsArray = message["fonts"] as? [[String: Any]],
              let totalFonts = message["totalFonts"] as? Int else {
            print("⌚️ Invalid font list metadata")
            return
        }
        
        print("⌚️ Received font list metadata for \(totalFonts) fonts")
        
        // Clear existing receiving data
        Self.receivingFonts.removeAll()
        
        // Prepare for receiving fonts
        for fontDict in fontsArray {
            if let fontId = fontDict["id"] as? String {
                Self.receivingFonts[fontId] = ReceivingFontData(
                    metadata: fontDict,
                    chunks: [:],
                    totalChunks: 0,
                    receivedChunks: Set<Int>()
                )
            }
        }
        
        print("⌚️ Prepared to receive \(Self.receivingFonts.count) fonts")
    }
    
    private func processFontDataChunk(_ message: [String: Any]) {
        guard let fontId = message["fontId"] as? String,
              let chunkIndex = message["chunkIndex"] as? Int,
              let totalChunks = message["totalChunks"] as? Int,
              let chunkData = message["chunkData"] as? Data,
              let isLastChunk = message["isLastChunk"] as? Bool else {
            print("⌚️ Invalid font data chunk message")
            return
        }
        
        // Get or create receiving font data
        if Self.receivingFonts[fontId] == nil {
            // Create minimal metadata if not received yet
            Self.receivingFonts[fontId] = ReceivingFontData(
                metadata: message,
                chunks: [:],
                totalChunks: totalChunks,
                receivedChunks: Set<Int>()
            )
        }
        
        var fontData = Self.receivingFonts[fontId]!
        fontData.totalChunks = totalChunks
        fontData.chunks[chunkIndex] = chunkData
        fontData.receivedChunks.insert(chunkIndex)
        Self.receivingFonts[fontId] = fontData
        
        print("⌚️ Received chunk \(chunkIndex + 1)/\(totalChunks) for font \(fontId)")
        
        // If this is the last chunk or font is complete, try to save it
        if isLastChunk || fontData.isComplete {
            saveFontIfComplete(fontId: fontId)
        }
    }
    
    private func saveFontIfComplete(fontId: String) {
        guard let fontData = Self.receivingFonts[fontId],
              fontData.isComplete,
              let completeData = fontData.completeData else {
            return
        }
        
        let metadata = fontData.metadata
        
        guard let fontNumber = metadata["fontNumber"] as? Int,
              let fileName = metadata["fileName"] as? String else {
            print("⌚️ Missing font metadata for \(fontId)")
            return
        }
        
        do {
            // Save font using CustomFontManager
            let fontManager = CustomFontManager.shared
            let result = fontManager.saveFontData(
                completeData,
                fontNumber: fontNumber,
                fileName: fileName,
                fontId: fontId
            )
            
            switch result {
            case .success(let customFont):
                print("✅ Successfully saved font: \(customFont.displayName)")
                
                // Remove from receiving data
                Self.receivingFonts.removeValue(forKey: fontId)
                
            case .failure(let error):
                print("❌ Failed to save font \(fileName): \(error)")
            }
            
        } catch {
            print("❌ Error saving font \(fileName): \(error)")
        }
    }
    
    private func processFontSyncComplete(_ message: [String: Any]) {
        guard let syncedCount = message["syncedCount"] as? Int,
              let totalCount = message["totalCount"] as? Int else {
            return
        }
        
        print("⌚️ Font sync complete: \(syncedCount)/\(totalCount) fonts synced")
        
        // Save any remaining incomplete fonts
        for (fontId, _) in Self.receivingFonts {
            saveFontIfComplete(fontId: fontId)
        }
        
        // Clear receiving data
        Self.receivingFonts.removeAll()
        
        // Notify completion
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("FontSyncCompleted"),
                object: nil,
                userInfo: [
                    "syncedCount": syncedCount,
                    "totalCount": totalCount
                ]
            )
        }
    }
}

#endif
