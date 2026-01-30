//
//  CollectionService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import Combine

/// Collection Service
@MainActor
class CollectionService: ObservableObject {
    static let shared = CollectionService()

    @Published var collections: [CollectionItem] = []

    private init() {
        loadCollections()
    }

    /// Add collection
    func addCollection(type: CollectionType, content: String, title: String? = nil, url: String? = nil) -> CollectionItem {
        let item = CollectionItem(
            id: UUID(),
            type: type,
            title: title ?? generateTitle(from: content),
            content: content,
            url: url,
            tags: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        collections.insert(item, at: 0)
        saveCollections()

        return item
    }

    /// Delete collection
    func deleteCollection(id: UUID) {
        collections.removeAll { $0.id == id }
        saveCollections()
    }

    /// Search collections
    func search(query: String) -> [CollectionItem] {
        guard !query.isEmpty else { return collections }

        return collections.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            item.content.localizedCaseInsensitiveContains(query) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    /// Filter by tag
    func filterByTag(_ tag: String) -> [CollectionItem] {
        collections.filter { $0.tags.contains(tag) }
    }

    // MARK: - Private

    private func generateTitle(from content: String) -> String {
        let maxLength = 50
        let firstLine = content.components(separatedBy: .newlines).first ?? content
        if firstLine.count <= maxLength {
            return firstLine
        }
        return String(firstLine.prefix(maxLength)) + "..."
    }

    private func loadCollections() {
        // TODO: Load from database
    }

    private func saveCollections() {
        // TODO: Save to database
    }
}

/// Collection Item
struct CollectionItem: Identifiable {
    let id: UUID
    let type: CollectionType
    var title: String
    var content: String
    var url: String?
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
}

/// Collection Type
enum CollectionType: String, CaseIterable {
    case text = "text"
    case link = "link"
    case image = "image"
    case file = "file"

    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .link: return "link"
        case .image: return "photo"
        case .file: return "doc"
        }
    }

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .link: return "Link"
        case .image: return "Image"
        case .file: return "File"
        }
    }
}
