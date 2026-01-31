//
//  DatabaseManager.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import SQLite3

/// Database Manager
class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    let dbPath: String

    private init() {
        // Get application support directory
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let gleamDir = appSupport.appendingPathComponent("Gleam")

        // Create directory
        try? fileManager.createDirectory(at: gleamDir, withIntermediateDirectories: true)

        dbPath = gleamDir.appendingPathComponent("gleam.db").path
        openDatabase()
        createTables()

        print("Database path: \(dbPath)")
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Failed to open database: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    private func createTables() {
        let tables = [
            // 随手记
            """
            CREATE TABLE IF NOT EXISTS quick_notes (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            )
            """,

            // Screenshots
            """
            CREATE TABLE IF NOT EXISTS screenshots (
                id TEXT PRIMARY KEY,
                image_path TEXT NOT NULL,
                tags TEXT,
                created_at REAL NOT NULL
            )
            """,

            // Translation history
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
                    print("Failed to create table: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
            sqlite3_finalize(statement)
        }
    }

    // MARK: - QuickNote CRUD

    func insertQuickNote(_ note: QuickNote) -> Bool {
        let sql = """
            INSERT INTO quick_notes (id, content, created_at, updated_at)
            VALUES (?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare statement: \(String(cString: sqlite3_errmsg(db)))")
            return false
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, note.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, note.content, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(statement, 3, note.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 4, note.updatedAt.timeIntervalSince1970)

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func updateQuickNote(_ note: QuickNote) -> Bool {
        let sql = """
            UPDATE quick_notes SET content = ?, updated_at = ?
            WHERE id = ?
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, note.content, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)
        sqlite3_bind_text(statement, 3, note.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func deleteQuickNote(id: UUID) -> Bool {
        let sql = "DELETE FROM quick_notes WHERE id = ?"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        return sqlite3_step(statement) == SQLITE_DONE
    }

    func fetchAllQuickNotes() -> [QuickNote] {
        let sql = "SELECT * FROM quick_notes ORDER BY updated_at DESC"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        var notes: [QuickNote] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            if let note = parseQuickNote(statement: statement) {
                notes.append(note)
            }
        }

        return notes
    }

    private func parseQuickNote(statement: OpaquePointer?) -> QuickNote? {
        guard let statement = statement else { return nil }

        guard let idStr = sqlite3_column_text(statement, 0),
              let id = UUID(uuidString: String(cString: idStr)),
              let contentStr = sqlite3_column_text(statement, 1) else {
            return nil
        }

        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
        let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))

        return QuickNote(
            id: id,
            content: String(cString: contentStr),
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
