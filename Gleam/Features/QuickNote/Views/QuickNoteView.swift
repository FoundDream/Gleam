//
//  QuickNoteView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// 随手记悬浮窗
struct QuickNoteView: View {
    var onSave: ((String) -> Void)?
    var onClose: (() -> Void)?

    @State private var content: String = ""
    @State private var isSaved: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                Text("随手记")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if isSaved {
                // 保存成功状态
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("已保存")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                Divider()

                // 内容输入区
                TextEditor(text: $content)
                    .font(.body)
                    .frame(minHeight: 100, maxHeight: 200)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .focused($isFocused)

                // 底部提示和按钮
                HStack {
                    Text("⌘↩ 保存")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("取消") {
                        onClose?()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("保存") {
                        saveNote()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(16)
        .frame(width: 360)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            isFocused = true
        }
    }

    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        onSave?(trimmedContent)

        // 显示成功状态
        withAnimation {
            isSaved = true
        }

        // 1秒后自动关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onClose?()
        }
    }
}

#Preview {
    QuickNoteView()
        .padding()
}
