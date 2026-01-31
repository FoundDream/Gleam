//
//  AppState.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI
import Combine

/// Global App State Management
@MainActor
class AppState: ObservableObject {
    /// Global shared instance
    static let shared = AppState()

    // MARK: - Translation Module
    @Published var selectedTranslationEngine: TranslationEngine = .deepSeek
    @Published var isTranslating: Bool = false
    @Published var translationHistory: [TranslationRecord] = []

    // MARK: - Screenshot Module
    @Published var screenshots: [ScreenshotItem] = []

    // MARK: - QuickNote Module (随手记)
    @Published var quickNotes: [QuickNote] = []

    // MARK: - UI State
    @Published var selectedTab: SidebarTab = .quickNotes
    @Published var searchText: String = ""
    @Published var showQuickNoteWindow: Bool = false
    @Published var selectedNoteId: UUID?
    @Published var selectedScreenshotId: UUID?

    private let db = DatabaseManager.shared

    init() {
        loadData()
    }

    // MARK: - Data Loading

    private func loadData() {
        // Load data from database
        quickNotes = db.fetchAllQuickNotes()
        screenshots = db.fetchAllScreenshots()
        translationHistory = db.fetchAllTranslations()

        print("Loaded \(quickNotes.count) notes, \(screenshots.count) screenshots, \(translationHistory.count) translation records")
    }

    // MARK: - QuickNote Operations (随手记)

    func addQuickNote(content: String) {
        let note = QuickNote(
            id: UUID(),
            content: content,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Save to database
        if db.insertQuickNote(note) {
            quickNotes.insert(note, at: 0)
            print("Note saved")
        } else {
            print("Failed to save note")
        }
    }

    func deleteQuickNote(id: UUID) {
        if db.deleteQuickNote(id: id) {
            quickNotes.removeAll { $0.id == id }
            print("Note deleted")
        }
    }

    func updateQuickNote(_ note: QuickNote) {
        if db.updateQuickNote(note) {
            if let index = quickNotes.firstIndex(where: { $0.id == note.id }) {
                var updated = note
                updated.updatedAt = Date()
                quickNotes[index] = updated
            }
            print("Note updated")
        }
    }

    // MARK: - Screenshot Operations

    func captureScreenshot() async {
        do {
            let item = try await ScreenshotService.shared.captureScreenshot()

            // Save to database
            if db.insertScreenshot(item) {
                screenshots.insert(item, at: 0)
                print("Screenshot saved: \(item.imagePath)")
            }
        } catch {
            print("Screenshot failed: \(error)")
        }
    }

    func deleteScreenshot(id: UUID) {
        // Get image path for file deletion
        if let item = screenshots.first(where: { $0.id == id }) {
            // Delete image file
            if !item.imagePath.isEmpty {
                try? FileManager.default.removeItem(atPath: item.imagePath)
            }
        }

        if db.deleteScreenshot(id: id) {
            screenshots.removeAll { $0.id == id }
            print("Screenshot deleted")
        }
    }

    // MARK: - Translation History Operations

    func addTranslationRecord(original: String, translated: String, engine: TranslationEngine) {
        let record = TranslationRecord(
            id: UUID(),
            originalText: original,
            translatedText: translated,
            engine: engine,
            timestamp: Date()
        )

        if db.insertTranslation(record) {
            translationHistory.insert(record, at: 0)
            // Keep max 100 records
            if translationHistory.count > 100 {
                translationHistory = Array(translationHistory.prefix(100))
            }
        }
    }

    func clearTranslationHistory() {
        if db.clearTranslationHistory() {
            translationHistory.removeAll()
            print("Translation history cleared")
        }
    }

    // MARK: - Search

    var filteredQuickNotes: [QuickNote] {
        if searchText.isEmpty {
            return quickNotes
        }
        return quickNotes.filter { note in
            note.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredScreenshots: [ScreenshotItem] {
        if searchText.isEmpty {
            return screenshots
        }
        return screenshots.filter { item in
            item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

// MARK: - Sidebar Options

enum SidebarTab: String, CaseIterable, Identifiable {
    case quickNotes = "随手记"
    case screenshots = "截图"
    case translationHistory = "翻译历史"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .quickNotes: return "note.text"
        case .screenshots: return "photo.on.rectangle"
        case .translationHistory: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Translation Record

struct TranslationRecord: Identifiable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let engine: TranslationEngine
    let timestamp: Date
}

// MARK: - Translation Engine Enum

enum TranslationEngine: String, CaseIterable, Identifiable {
    case deepSeek = "DeepSeek"
    case openAI = "OpenAI"
    case deepL = "DeepL"
    case google = "Google"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .deepSeek: return "sparkle"
        case .openAI: return "brain.head.profile"
        case .deepL: return "d.circle.fill"
        case .google: return "g.circle.fill"
        }
    }
}
