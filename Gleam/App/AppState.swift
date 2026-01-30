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

    // MARK: - Collection Module
    @Published var collections: [CollectionItem] = []

    // MARK: - UI State
    @Published var selectedTab: SidebarTab = .collections
    @Published var searchText: String = ""
    @Published var showNewCollectionSheet: Bool = false
    @Published var selectedCollectionId: UUID?
    @Published var selectedScreenshotId: UUID?

    private let db = DatabaseManager.shared

    init() {
        loadData()
    }

    // MARK: - Data Loading

    private func loadData() {
        // Load data from database
        collections = db.fetchAllCollections()
        screenshots = db.fetchAllScreenshots()
        translationHistory = db.fetchAllTranslations()

        print("Loaded \(collections.count) collections, \(screenshots.count) screenshots, \(translationHistory.count) translation records")
    }

    // MARK: - Collection Operations

    func addCollection(type: CollectionType, title: String, content: String, url: String? = nil, tags: [String] = []) {
        let item = CollectionItem(
            id: UUID(),
            type: type,
            title: title,
            content: content,
            url: url,
            tags: tags,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Save to database
        if db.insertCollection(item) {
            collections.insert(item, at: 0)
            print("Collection saved: \(title)")
        } else {
            print("Failed to save collection: \(title)")
        }
    }

    func deleteCollection(id: UUID) {
        if db.deleteCollection(id: id) {
            collections.removeAll { $0.id == id }
            print("Collection deleted")
        }
    }

    func updateCollection(_ item: CollectionItem) {
        if db.updateCollection(item) {
            if let index = collections.firstIndex(where: { $0.id == item.id }) {
                var updated = item
                updated.updatedAt = Date()
                collections[index] = updated
            }
            print("Collection updated: \(item.title)")
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

    var filteredCollections: [CollectionItem] {
        if searchText.isEmpty {
            return collections
        }
        return collections.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            item.content.localizedCaseInsensitiveContains(searchText) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
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
    case collections = "Collections"
    case screenshots = "Screenshots"
    case translationHistory = "Translation History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .collections: return "star.fill"
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
