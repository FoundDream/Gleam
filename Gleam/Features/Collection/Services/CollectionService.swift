//
//  CollectionService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import Combine

/// 收藏服务
@MainActor
class CollectionService: ObservableObject {
    static let shared = CollectionService()

    @Published var collections: [CollectionItem] = []

    private init() {
        loadCollections()
    }

    /// 添加收藏
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

    /// 删除收藏
    func deleteCollection(id: UUID) {
        collections.removeAll { $0.id == id }
        saveCollections()
    }

    /// 搜索收藏
    func search(query: String) -> [CollectionItem] {
        guard !query.isEmpty else { return collections }

        return collections.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            item.content.localizedCaseInsensitiveContains(query) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    /// 按标签过滤
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
        // TODO: 从数据库加载
    }

    private func saveCollections() {
        // TODO: 保存到数据库
    }
}

/// 收藏项
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

/// 收藏类型
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
        case .text: return "文本"
        case .link: return "链接"
        case .image: return "图片"
        case .file: return "文件"
        }
    }
}
