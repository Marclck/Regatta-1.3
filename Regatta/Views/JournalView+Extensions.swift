//
//  JournalView+Extensions.swift
//  Regatta
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation
import SwiftUI

extension JournalView {
    // Add a method to display archive statistics - takes sessionStore as a parameter
    func archiveStats(sessionStore: iOSSessionStore) -> some View {
        let archiveCount = sessionStore.sessions.count
        
        return HStack {
            Spacer()
            VStack(spacing: 2) {
                Text("Archive")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text("\(archiveCount) sessions")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// This modifier adds archive support to the JournalView
struct ArchiveViewModifier: ViewModifier {
    @ObservedObject var sessionStore: iOSSessionStore
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Perform migration if it hasn't been done yet
                if !DataMigrationUtility.shared.isMigrationCompleted {
                    DataMigrationUtility.shared.performInitialMigration()
                }
                
                // Load sessions from archive
                sessionStore.loadSessions()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ArchiveUpdated"))) { _ in
                // Reload sessions when archive is updated
                sessionStore.loadSessions()
            }
    }
}

extension View {
    func withArchiveSupport(sessionStore: iOSSessionStore) -> some View {
        self.modifier(ArchiveViewModifier(sessionStore: sessionStore))
    }
}
