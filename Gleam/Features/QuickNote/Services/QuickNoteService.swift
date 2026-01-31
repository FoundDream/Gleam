//
//  QuickNoteService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import Combine

/// 随手记数据模型
struct QuickNote: Identifiable {
    let id: UUID
    var content: String
    let createdAt: Date
    var updatedAt: Date
}

/// 随手记服务
@MainActor
class QuickNoteService: ObservableObject {
    static let shared = QuickNoteService()

    @Published var notes: [QuickNote] = []

    private init() {
        loadNotes()
    }

    /// 添加笔记
    func addNote(content: String) -> QuickNote {
        let note = QuickNote(
            id: UUID(),
            content: content,
            createdAt: Date(),
            updatedAt: Date()
        )

        notes.insert(note, at: 0)
        saveNotes()

        return note
    }

    /// 更新笔记
    func updateNote(id: UUID, content: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].content = content
            notes[index].updatedAt = Date()
            saveNotes()
        }
    }

    /// 删除笔记
    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        saveNotes()
    }

    /// 搜索笔记
    func search(query: String) -> [QuickNote] {
        guard !query.isEmpty else { return notes }

        return notes.filter { note in
            note.content.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Private

    private func loadNotes() {
        // 从数据库加载
    }

    private func saveNotes() {
        // 保存到数据库
    }
}
