//
//  FontsListView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 07/08/2025.
//

import SwiftUI

struct FontsListView: View {
    @StateObject private var fontManager = CustomFontManager.shared
    @State private var syncStatus: String = ""
    @State private var showingSyncStatus = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Sync status banner
            if showingSyncStatus && !syncStatus.isEmpty {
                HStack {
                    Image(systemName: "iphone")
                        .foregroundColor(.blue)
                    Text(syncStatus)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.2))
            }
            
            List {
                if fontManager.customFonts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "textformat")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Custom Fonts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Import fonts using the iPhone app")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(fontManager.customFonts) { font in
                        FontRowViewWatch(font: font)
                    }
                }
            }
        }
        .navigationTitle("Custom Fonts")
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            setupSyncStatusObserver()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func setupSyncStatusObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("FontSyncCompleted"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let syncedCount = userInfo["syncedCount"] as? Int,
               let totalCount = userInfo["totalCount"] as? Int {
                
                if syncedCount == totalCount {
                    syncStatus = "✅ \(syncedCount) fonts synced from iPhone"
                } else {
                    syncStatus = "⚠️ \(syncedCount)/\(totalCount) fonts synced"
                }
                
                showingSyncStatus = true
                
                // Hide status after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation {
                        showingSyncStatus = false
                    }
                }
            }
        }
    }
}

struct FontRowViewWatch: View {
    let font: CustomFont
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(font.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            // Font preview with numbers 0-9
            if let customFont = Font.customFont(font, size: 12, weight: .regular) {
                Text("0123456789")
                    .font(customFont)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                Text("0123456789")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        FontsListView()
    }
}
