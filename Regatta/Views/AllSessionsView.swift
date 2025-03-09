//
//  AllSessionsView.swift
//  Regatta
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation
import SwiftUI
import CoreLocation

struct AllSessionsView: View {
    @ObservedObject private var sessionStore = iOSSessionStore.shared
    @State private var isLoading = false
    
    private func groupedSessions() -> [String: [RaceSession]] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return Dictionary(grouping: sessionStore.sessions) { session in
            formatter.string(from: session.date)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("All Race Sessions")
                    .font(.system(.headline, design: .rounded))
                
                Spacer()
                
                Text("\(sessionStore.sessions.count) total")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if isLoading {
                ProgressView("Loading all sessions...")
                    .padding()
            } else if sessionStore.sessions.isEmpty {
                VStack {
                    Text("No archived sessions found")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                List {
                    ForEach(groupedSessions().keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(date)) {
                            ForEach(groupedSessions()[date]!.sorted(by: { $0.date > $1.date }), id: \.date) { session in
                                SessionRowView(session: session)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            refreshData()
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        isLoading = true
        
        // Load sessions from the store
        Task { @MainActor in
            sessionStore.loadSessions()
            
            // Update isLoading after a short delay to ensure UI updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        AllSessionsView()
    }
}
