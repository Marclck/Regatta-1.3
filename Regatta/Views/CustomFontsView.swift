//
//  CustomFontsView.swift
//  Regatta
//
//  Created by Chikai Lai on 07/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomFontsView: View {
    @StateObject private var fontManager = CustomFontManager.shared
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var colorManager: ColorManager
    
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var fontSyncStatus: WatchSessionManager.FontSyncStatus = .idle
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background matching the app theme
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: colorManager.selectedTheme.rawValue), location: 0.0),
                        .init(color: Color.black, location: 0.3),
                        .init(color: Color.black, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sync Status Bar
                    if case .syncing = fontSyncStatus {
                        syncStatusView
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                    
                    if fontManager.customFonts.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "textformat")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text("No Custom Fonts")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Tap + to import TTF or OTF font files")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))

                                Text("Maximum file size: 300 KB")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                    } else {
                        // Font list
                        List {
                            ForEach(fontManager.customFonts) { font in
                                FontRowView(font: font)
                            }
                            .onDelete(perform: deleteFont)
                            .listRowBackground(Color.clear.background(.ultraThinMaterial))
                            .environment(\.colorScheme, .dark)
                            
                            // Warning section at the end of the list
                            Section {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16))
                                    
                                    Text("Not all fonts are supported on Watch by Apple")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.clear.background(.ultraThinMaterial))
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("Custom Fonts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Sync to Watch button
                        if !fontManager.customFonts.isEmpty {
                            Button(action: syncToWatch) {
                                HStack(spacing: 4) {
                                    if case .syncing = fontSyncStatus {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "applewatch")
                                    }
                                    Text("Sync")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.2))
                                )
                            }
                            .disabled(isSyncing)
                        }
                        
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker { result in
                handleFileImport(result: result)
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            setupFontSyncObserver()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // MARK: - Sync Status View
    private var syncStatusView: some View {
        VStack(spacing: 4) {
            if case .syncing(let currentFont, let totalFonts, let fontName) = fontSyncStatus {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Syncing to Apple Watch")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Font \(currentFont)/\(totalFonts): \(fontName)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                Text("Keep your Apple Watch on and nearby")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                    .italic()
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Properties
    private var isSyncing: Bool {
        if case .syncing = fontSyncStatus {
            return true
        }
        return false
    }
    
    // MARK: - Font Sync Methods
    private func syncToWatch() {
        WatchSessionManager.shared.syncFontsToWatch()
    }
    
    private func setupFontSyncObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("FontSyncStatusUpdate"),
            object: nil,
            queue: .main
        ) { notification in
            if let status = notification.object as? WatchSessionManager.FontSyncStatus {
                fontSyncStatus = status
                
                // Show alerts for final status
                switch status {
                case .success(let syncedCount):
                    showAlert(title: "Sync Complete", message: "Successfully synced \(syncedCount) fonts to Apple Watch")
                case .error(let error):
                    showAlert(title: "Sync Failed", message: error)
                case .partialSuccess(let syncedCount, let totalCount, let failedFonts):
                    let failedList = failedFonts.joined(separator: ", ")
                    showAlert(title: "Partial Sync", message: "Synced \(syncedCount)/\(totalCount) fonts. Failed: \(failedList)")
                default:
                    break
                }
            }
        }
    }
    
    private func deleteFont(at offsets: IndexSet) {
        for index in offsets {
            let font = fontManager.customFonts[index]
            fontManager.deleteFont(font)
        }
    }
    
    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let importResult = fontManager.importFont(from: url)
            
            DispatchQueue.main.async {
                switch importResult {
                case .success(let font):
                    showAlert(title: "Success", message: "Font \(font.fontNumber) imported successfully!")
                case .failure(let error):
                    showAlert(title: "Import Failed", message: error.localizedDescription)
                }
            }
            
        case .failure(let error):
            DispatchQueue.main.async {
                showAlert(title: "File Selection Failed", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Font Row View
struct FontRowView: View {
    let font: CustomFont
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(font.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatFileSize())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Font preview with numbers 0-9
            if let customFont = Font.customFont(font, size: 16, weight: .regular) {
                Text("0123456789")
                    .font(customFont)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, 4)
            } else {
                Text("0123456789")
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.vertical, 4)
            }
            
            Text("Added: \(formatDate(font.dateAdded))")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    private func formatFileSize() -> String {
        let fileSize = font.fontData.count
        let kb = Double(fileSize) / 1024.0
        return String(format: "%.1f KB", kb)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (Result<URL, Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Support both TTF and OTF types
        let ttfType = UTType(filenameExtension: "ttf") ?? UTType.data
        let otfType = UTType(filenameExtension: "otf") ?? UTType.data
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [ttfType, otfType], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("📁 Document picker selected URLs: \(urls)")
            
            guard let url = urls.first else {
                print("❌ No URL selected")
                parent.onDocumentPicked(.failure(DocumentPickerError.noFileSelected))
                return
            }
            
            print("📁 Selected file: \(url.lastPathComponent)")
            print("📁 File path: \(url.path)")
            print("📁 Is security scoped: \(url.hasDirectoryPath)")
            
            parent.onDocumentPicked(.success(url))
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onDocumentPicked(.failure(DocumentPickerError.cancelled))
        }
    }
}

enum DocumentPickerError: LocalizedError {
    case noFileSelected
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "No file was selected"
        case .cancelled:
            return "File selection was cancelled"
        }
    }
}
