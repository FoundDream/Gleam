//
//  AppState.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI
import Combine

/// 全局应用状态管理
@MainActor
class AppState: ObservableObject {
    /// 全局共享实例
    static let shared = AppState()

    // MARK: - 翻译模块
    @Published var selectedTranslationEngine: TranslationEngine = .deepSeek
    @Published var isTranslating: Bool = false
    @Published var translationHistory: [TranslationRecord] = []

    // MARK: - 截图模块
    @Published var screenshots: [ScreenshotItem] = []

    // MARK: - 收藏模块
    @Published var collections: [CollectionItem] = []

    // MARK: - UI 状态
    @Published var selectedTab: SidebarTab = .collections
    @Published var searchText: String = ""
    @Published var showNewCollectionSheet: Bool = false
    @Published var selectedCollectionId: UUID?
    @Published var selectedScreenshotId: UUID?

    private let db = DatabaseManager.shared

    init() {
        loadData()
    }

    // MARK: - 数据加载

    private func loadData() {
        // 从数据库加载数据
        collections = db.fetchAllCollections()
        screenshots = db.fetchAllScreenshots()
        translationHistory = db.fetchAllTranslations()

        print("已加载 \(collections.count) 个收藏, \(screenshots.count) 张截图, \(translationHistory.count) 条翻译记录")
    }

    // MARK: - 收藏操作

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

        // 保存到数据库
        if db.insertCollection(item) {
            collections.insert(item, at: 0)
            print("收藏已保存: \(title)")
        } else {
            print("保存收藏失败: \(title)")
        }
    }

    func deleteCollection(id: UUID) {
        if db.deleteCollection(id: id) {
            collections.removeAll { $0.id == id }
            print("收藏已删除")
        }
    }

    func updateCollection(_ item: CollectionItem) {
        if db.updateCollection(item) {
            if let index = collections.firstIndex(where: { $0.id == item.id }) {
                var updated = item
                updated.updatedAt = Date()
                collections[index] = updated
            }
            print("收藏已更新: \(item.title)")
        }
    }

    // MARK: - 截图操作

    func captureScreenshot() async {
        do {
            let item = try await ScreenshotService.shared.captureScreenshot()

            // 保存到数据库
            if db.insertScreenshot(item) {
                screenshots.insert(item, at: 0)
                print("截图已保存，OCR 文字: \(item.ocrText.prefix(50))...")
            }
        } catch {
            print("截图失败: \(error)")
        }
    }

    func deleteScreenshot(id: UUID) {
        // 获取图片路径用于删除文件
        if let item = screenshots.first(where: { $0.id == id }) {
            // 删除图片文件
            if !item.imagePath.isEmpty {
                try? FileManager.default.removeItem(atPath: item.imagePath)
            }
        }

        if db.deleteScreenshot(id: id) {
            screenshots.removeAll { $0.id == id }
            print("截图已删除")
        }
    }

    // MARK: - 翻译历史操作

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
            // 保持最多 100 条记录
            if translationHistory.count > 100 {
                translationHistory = Array(translationHistory.prefix(100))
            }
        }
    }

    func clearTranslationHistory() {
        if db.clearTranslationHistory() {
            translationHistory.removeAll()
            print("翻译历史已清空")
        }
    }

    // MARK: - 搜索

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
            item.ocrText.localizedCaseInsensitiveContains(searchText) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

// MARK: - 侧边栏选项

enum SidebarTab: String, CaseIterable, Identifiable {
    case collections = "收藏"
    case screenshots = "截图"
    case translationHistory = "翻译历史"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .collections: return "star.fill"
        case .screenshots: return "photo.on.rectangle"
        case .translationHistory: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - 翻译记录

struct TranslationRecord: Identifiable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let engine: TranslationEngine
    let timestamp: Date
}

// MARK: - 翻译引擎枚举

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
