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
        VStack(spacing: 0) {
            // 标题栏
            HStack(spacing: 8) {
                Image(systemName: "pencil.and.scribble")
                    .font(.title3)
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text("随手记")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            if isSaved {
                // 保存成功状态
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.linearGradient(
                            colors: [.green, .mint],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    Text("已保存")
                        .font(.headline)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            } else {
                // 内容输入区
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("记点什么...")
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }

                    TextEditor(text: $content)
                        .font(.system(size: 14))
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                }
                .padding(12)
                .frame(height: 120)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .cornerRadius(10)
                .padding(.horizontal, 12)

                // 底部按钮区
                HStack(spacing: 12) {
                    Text("\(content.count) 字")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()

                    Spacer()

                    Button("取消") {
                        onClose?()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .keyboardShortcut(.cancelAction)

                    Button {
                        saveNote()
                    } label: {
                        Text("保存")
                            .font(.body.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                          ? Color.orange.opacity(0.3)
                                          : Color.orange)
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        .onAppear {
            isFocused = true
        }
    }

    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        onSave?(trimmedContent)

        // 显示成功状态
        withAnimation(.easeInOut(duration: 0.2)) {
            isSaved = true
        }

        // 自动关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onClose?()
        }
    }
}

#Preview {
    QuickNoteView()
        .padding(40)
        .background(Color.gray.opacity(0.3))
}
