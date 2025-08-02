//
//  SessionArchiveManager.swift
//  Regatta
//
//  Created by Chikai Lai on 09/03/2025.
//

import Foundation
import MessageUI

class SessionArchiveManager {
    static let shared = SessionArchiveManager()
    
    private let fileManager = FileManager.default
    private var archiveURL: URL? {
        try? fileManager.url(for: .documentDirectory,
                          in: .userDomainMask,
                          appropriateFor: nil,
                          create: true)
            .appendingPathComponent("sessionArchive.json")
    }
    
    private init() {
        print("🗄️ Archive Manager: Initializing")
        // Create archive file if it doesn't exist
        createArchiveIfNeeded()
    }
    
    // MARK: - Archive Operations
    
    /// Create archive file if it doesn't exist
    private func createArchiveIfNeeded() {
        guard let url = archiveURL else {
            print("🗄️ Archive Manager: Failed to get archive URL")
            return
        }
        
        if !fileManager.fileExists(atPath: url.path) {
            print("🗄️ Archive Manager: Creating new archive file")
            // Create empty archive
            do {
                let emptyArchive: [RaceSession] = []
                let data = try JSONEncoder().encode(emptyArchive)
                try data.write(to: url)
                print("🗄️ Archive Manager: Created empty archive file at \(url.path)")
            } catch {
                print("🗄️ Archive Manager: Failed to create archive file - \(error.localizedDescription)")
            }
        } else {
            print("🗄️ Archive Manager: Archive file already exists at \(url.path)")
        }
    }
    
    /// Load all sessions from archive
    func loadArchivedSessions() -> [RaceSession] {
        guard let url = archiveURL else {
            print("🗄️ Archive Manager: Failed to get archive URL")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let sessions = try JSONDecoder().decode([RaceSession].self, from: data)
            print("🗄️ Archive Manager: Loaded \(sessions.count) sessions from archive")
            return sessions
        } catch {
            print("🗄️ Archive Manager: Failed to load archive - \(error.localizedDescription)")
            return []
        }
    }
    
    /// Save sessions to archive, avoiding duplicates
    func saveSessionsToArchive(_ sessions: [RaceSession]) {
        guard let url = archiveURL else {
            print("🗄️ Archive Manager: Failed to get archive URL")
            return
        }
        
        do {
            // Load existing archive
            let existingArchive = loadArchivedSessions()
            
            // Merge new sessions with existing ones, avoiding duplicates
            let mergedSessions = mergeSessions(existing: existingArchive, new: sessions)
            
            // Sort by date (newest first)
            let sortedSessions = mergedSessions.sorted(by: { $0.date > $1.date })
            
            // Save to file
            let data = try JSONEncoder().encode(sortedSessions)
            try data.write(to: url)
            print("🗄️ Archive Manager: Saved \(sortedSessions.count) sessions to archive")
        } catch {
            print("🗄️ Archive Manager: Failed to save archive - \(error.localizedDescription)")
        }
    }
    
    /// Merge sessions avoiding duplicates (using session date as unique identifier)
    private func mergeSessions(existing: [RaceSession], new: [RaceSession]) -> [RaceSession] {
        var sessionMap: [String: RaceSession] = [:]
        
        // Add existing sessions to map
        for session in existing {
            sessionMap[session.id] = session
        }
        
        // Add new sessions, overwriting if they exist
        for session in new {
            sessionMap[session.id] = session
        }
        
        // Convert map back to array
        return Array(sessionMap.values)
    }
    
    /// Migrate all sessions from UserDefaults to archive
    func migrateExistingSessionsToArchive() {
        print("🗄️ Archive Manager: Starting migration of existing sessions")
        
        // Load from SharedDefaults
        if let existingSessions = SharedDefaults.loadSessionsFromContainer() {
            print("🗄️ Archive Manager: Found \(existingSessions.count) sessions to migrate")
            
            // Save to archive
            saveSessionsToArchive(existingSessions)
            print("🗄️ Archive Manager: Migration completed")
        } else {
            print("🗄️ Archive Manager: No sessions found to migrate")
        }
    }
    
    // MARK: - Email Export
    
    /// Send all archived sessions via email
    /// - Parameters:
    ///   - viewController: The presenting view controller
    ///   - toEmail: Optional recipient email address
    ///   - completion: Completion handler with success/failure result
    func sendArchiveViaEmail(from viewController: UIViewController,
                           toEmail: String? = "normalappco@gmail.com",
                           completion: @escaping (Result<Void, Error>) -> Void) {
        
        // Check if mail is available
        guard MFMailComposeViewController.canSendMail() else {
            print("🗄️ Archive Manager: Mail services not available")
            completion(.failure(ArchiveError.mailNotAvailable))
            return
        }
        
        // Load archived sessions
        let sessions = loadArchivedSessions()
        
        guard !sessions.isEmpty else {
            print("🗄️ Archive Manager: No sessions to export")
            completion(.failure(ArchiveError.noDataToExport))
            return
        }
        
        // Create email data
        do {
            let emailData = try createEmailAttachmentData(sessions: sessions)
            
            // Create mail composer
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = EmailDelegate(completion: completion)
            
            // Set email properties
            if let toEmail = toEmail {
                mailComposer.setToRecipients([toEmail])
            }
            
            mailComposer.setSubject("Regatta Race Sessions Archive")
            mailComposer.setMessageBody(createEmailBody(sessionCount: sessions.count), isHTML: false)
            
            // Attach the data
            mailComposer.addAttachmentData(emailData.data,
                                         mimeType: "application/json",
                                         fileName: emailData.filename)
            
            // Present mail composer
            viewController.present(mailComposer, animated: true)
            print("🗄️ Archive Manager: Email composer presented with \(sessions.count) sessions")
            
        } catch {
            print("🗄️ Archive Manager: Failed to create email data - \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Create email attachment data from sessions
    private func createEmailAttachmentData(sessions: [RaceSession]) throws -> (data: Data, filename: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(sessions)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let filename = "regatta_sessions_\(timestamp).json"
        
        return (jsonData, filename)
    }
    
    /// Create email body text
    private func createEmailBody(sessionCount: Int) -> String {
        return """
        Regatta Race Sessions Archive
        
        This email contains an archive of your race sessions from the Regatta app.
        
        Archive Details:
        • Total Sessions: \(sessionCount)
        • Export Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))
        • Format: JSON
        
        The attached file contains all your race session data and can be used for analysis.

        """
    }
}

// MARK: - Email Delegate

private class EmailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    private let completion: (Result<Void, Error>) -> Void
    
    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                              didFinishWith result: MFMailComposeResult,
                              error: Error?) {
        controller.dismiss(animated: true) {
            if let error = error {
                print("🗄️ Archive Manager: Email failed with error - \(error.localizedDescription)")
                self.completion(.failure(error))
            } else {
                switch result {
                case .sent:
                    print("🗄️ Archive Manager: Email sent successfully")
                    self.completion(.success(()))
                case .cancelled:
                    print("🗄️ Archive Manager: Email cancelled by user")
                    self.completion(.failure(ArchiveError.emailCancelled))
                case .failed:
                    print("🗄️ Archive Manager: Email failed to send")
                    self.completion(.failure(ArchiveError.emailFailed))
                case .saved:
                    print("🗄️ Archive Manager: Email saved as draft")
                    self.completion(.success(()))
                @unknown default:
                    print("🗄️ Archive Manager: Unknown email result")
                    self.completion(.failure(ArchiveError.unknownError))
                }
            }
        }
    }
}

// MARK: - Error Types

enum ArchiveError: Error, LocalizedError {
    case mailNotAvailable
    case noDataToExport
    case emailCancelled
    case emailFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .mailNotAvailable:
            return "Mail services are not available on this device"
        case .noDataToExport:
            return "No race sessions found to export"
        case .emailCancelled:
            return "Email was cancelled by user"
        case .emailFailed:
            return "Failed to send email"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
