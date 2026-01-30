//
//  DatabaseManager.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import SQLite3

/// 数据库管理器
class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    let dbPath: String

    private init() {
        // 获取应用支持目录
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let gleamDir = appSupport.appendingPathComponent("Gleam")

        // 创建目录
        try? fileManager.createDirectory(at: gleamDir, withIntermediateDirectories: true)

        dbPath = gleamDir.appendingPathComponent("gleam.db").path
        openDatabase()
        createTables()

        print("数据库路径: \(dbPath)")
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("无法打开数据库: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    private func createTables() {
        let tables = [
            // 收藏
            """
            CREATE TABLE IF NOT EXISTS collections (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                url TEXT,
                tags TEXT,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            )
            """,

            // 截图
            """
            CREATE TABLE IF NOT EXISTS screenshots (
                id TEXT PRIMARY KEY,
                image_path TEXT NOT NULL,
                tags TEXT,
                created_at REAL NOT NULL
            )
            """,

            // 翻译历史
            """
            CREATE TABLE IF NOT EXISTS translation_history (
                id TEXT PRIMARY KEY,
                original_text TEXT NOT NULL,
                translated_text TEXT NOT NULL,
                engine TEXT NOT NULL,
                created_at REAL NOT NULL
            )
            """
        ]

        for sql in tables {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("创建表失败: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
            sqlite3_finalize(statement)
        }
    }

    // MARK: - Collection CRUD

    func insertCollection(_ item: CollectionItem) -> Bool {
        let sql = """
            INSERT INTO collections (id, type, title, content, url, tags, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("准备语句失败: \(String(cString: sqlite3_errmsg(db)))")
            return false
        }

        defer { sqlite3_finalize(statement) }

        let tagsJson = (try? JSONEncoder().encode(item.tags)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        sqlite3_bind_text(statement, 1, item.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, item.type.rawValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 3, item.title, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 4, item.content, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 5, item.url, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 6, tagsJson, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(statement, 7, item.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 8, item.updatedAt.timeIntervalSince1970)

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func updateCollection(_ item: CollectionItem) -> Bool {
        let sql = """
            UPDATE collections SET type = ?, title = ?, content = ?, url = ?, tags = ?, updated_at = ?
            WHERE id = ?
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }

        let tagsJson = (try? JSONEncoder().encode(item.tags)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        sqlite3_bind_text(statement, 1, item.type.rawValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, item.title, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 3, item.content, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 4, item.url, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 5, tagsJson, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(statement, 6, Date().timeIntervalSince1970)
        sqlite3_bind_text(statement, 7, item.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func deleteCollection(id: UUID) -> Bool {
        let sql = "DELETE FROM collections WHERE id = ?"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func fetchAllCollections() -> [CollectionItem] {
        let sql = "SELECT * FROM collections ORDER BY updated_at DESC"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        var items: [CollectionItem] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            if let item = parseCollection(statement: statement) {
                items.append(item)
            }
        }

        return items
    }

    private func parseCollection(statement: OpaquePointer?) -> CollectionItem? {
        guard let statement = statement else { return nil }

        guard let idStr = sqlite3_column_text(statement, 0),
              let id = UUID(uuidString: String(cString: idStr)),
              let typeStr = sqlite3_column_text(statement, 1),
              let type = CollectionType(rawValue: String(cString: typeStr)),
              let titleStr = sqlite3_column_text(statement, 2),
              let contentStr = sqlite3_column_text(statement, 3) else {
            return nil
        }

        let url = sqlite3_column_text(statement, 4).map { String(cString: $0) }
        let tagsJson = sqlite3_column_text(statement, 5).map { String(cString: $0) } ?? "[]"
        let tags = (try? JSONDecoder().decode([String].self, from: tagsJson.data(using: .utf8)!)) ?? []
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
        let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))

        return CollectionItem(
            id: id,
            type: type,
            title: String(cString: titleStr),
            content: String(cString: contentStr),
            url: url,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Screenshot CRUD

    func insertScreenshot(_ item: ScreenshotItem) -> Bool {
        let sql = """
            INSERT INTO screenshots (id, image_path, tags, created_at)
            VALUES (?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }

        let tagsJson = (try? JSONEncoder().encode(item.tags)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        sqlite3_bind_text(statement, 1, item.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, item.imagePath, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 3, tagsJson, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(statement, 4, item.timestamp.timeIntervalSince1970)

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func deleteScreenshot(id: UUID) -> Bool {
        let sql = "DELETE FROM screenshots WHERE id = ?"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func fetchAllScreenshots() -> [ScreenshotItem] {
        let sql = "SELECT * FROM screenshots ORDER BY created_at DESC"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        var items: [ScreenshotItem] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            if let item = parseScreenshot(statement: statement) {
                items.append(item)
            }
        }

        return items
    }

    private func parseScreenshot(statement: OpaquePointer?) -> ScreenshotItem? {
        guard let statement = statement else { return nil }

        guard let idStr = sqlite3_column_text(statement, 0),
              let id = UUID(uuidString: String(cString: idStr)),
              let imagePathStr = sqlite3_column_text(statement, 1) else {
            return nil
        }

        let tagsJson = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? "[]"
        let tags = (try? JSONDecoder().decode([String].self, from: tagsJson.data(using: .utf8)!)) ?? []
        let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))

        return ScreenshotItem(
            id: id,
            timestamp: timestamp,
            imagePath: String(cString: imagePathStr),
            tags: tags
        )
    }

    // MARK: - Translation History CRUD

    func insertTranslation(_ record: TranslationRecord) -> Bool {
        let sql = """
            INSERT INTO translation_history (id, original_text, translated_text, engine, created_at)
            VALUES (?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, record.originalText, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 3, record.translatedText, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 4, record.engine.rawValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(statement, 5, record.timestamp.timeIntervalSince1970)

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func fetchAllTranslations() -> [TranslationRecord] {
        let sql = "SELECT * FROM translation_history ORDER BY created_at DESC LIMIT 100"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        var items: [TranslationRecord] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idStr = sqlite3_column_text(statement, 0),
                  let id = UUID(uuidString: String(cString: idStr)),
                  let originalStr = sqlite3_column_text(statement, 1),
                  let translatedStr = sqlite3_column_text(statement, 2),
                  let engineStr = sqlite3_column_text(statement, 3),
                  let engine = TranslationEngine(rawValue: String(cString: engineStr)) else {
                continue
            }

            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))

            items.append(TranslationRecord(
                id: id,
                originalText: String(cString: originalStr),
                translatedText: String(cString: translatedStr),
                engine: engine,
                timestamp: timestamp
            ))
        }

        return items
    }

    func clearTranslationHistory() -> Bool {
        let sql = "DELETE FROM translation_history"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }
        return sqlite3_step(statement) == SQLITE_DONE
    }
}
