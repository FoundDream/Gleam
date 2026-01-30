//
//  QuickCollectView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// 快速收藏浮窗
struct QuickCollectView: View {
    let initialText: String
    var onSave: ((String, String, [String]) -> Void)?
    var onClose: (() -> Void)?

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var tagsInput: String = ""
    @State private var isSaved: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("快速收藏")
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
                    Text("已收藏")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                Divider()

                // 标题
                TextField("标题（可选）", text: $title)
                    .textFieldStyle(.plain)
                    .font(.body)

                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    Text("内容")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $content)
                        .font(.body)
                        .frame(minHeight: 60, maxHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                }

                // 标签
                TextField("标签（用逗号分隔）", text: $tagsInput)
                    .textFieldStyle(.plain)
                    .font(.caption)

                Divider()

                // 按钮
                HStack {
                    Button("取消") {
                        onClose?()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("收藏") {
                        saveCollection()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .onAppear {
            content = initialText
            // 自动生成标题
            let firstLine = initialText.components(separatedBy: .newlines).first ?? initialText
            if firstLine.count > 30 {
                title = String(firstLine.prefix(30)) + "..."
            } else {
                title = firstLine
            }
        }
    }

    private func saveCollection() {
        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let finalTitle = title.isEmpty ? "未命名收藏" : title

        onSave?(finalTitle, content, tags)

        // 显示成功状态
        withAnimation {
            isSaved = true
        }

        // 1秒后自动关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onClose?()
        }
    }
}

#Preview {
    QuickCollectView(initialText: "这是一段要收藏的文字内容")
        .padding()
}
