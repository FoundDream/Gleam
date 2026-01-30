//
//  TranslationPopoverView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// 翻译浮窗视图
struct TranslationPopoverView: View {
    let originalText: String
    var onTranslationComplete: ((String, String, TranslationEngine) -> Void)?
    var onClose: (() -> Void)?

    @StateObject private var translationManager = TranslationServiceManager.shared
    @State private var translatedText: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部带关闭按钮
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Text("Gleam 翻译")
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
                .help("关闭 (ESC)")
            }

            Divider()

            // 原文
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("原文")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        copyToClipboard(originalText)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("复制原文")
                }

                Text(originalText)
                    .font(.body)
                    .textSelection(.enabled)
                    .lineLimit(5)
            }

            Divider()

            // 译文
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("译文")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // 引擎选择
                    Menu {
                        ForEach(TranslationEngine.allCases) { engine in
                            Button {
                                translationManager.setEngine(engine)
                                Task {
                                    await performTranslation()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: engine.iconName)
                                    Text(engine.rawValue)
                                    if translationManager.currentEngine == engine {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: translationManager.currentEngine.iconName)
                            Text(translationManager.currentEngine.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)

                    Button {
                        copyToClipboard(translatedText)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .disabled(isLoading || translatedText.isEmpty)
                    .help("复制译文")
                }

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("正在使用 \(translationManager.currentEngine.rawValue) 翻译...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(minHeight: 40)
                } else if let error = errorMessage {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }

                        if error.contains("API Key") || error.contains("hostname") {
                            Button("打开设置") {
                                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                                onClose?()
                            }
                            .font(.caption)
                        }
                    }
                    .frame(minHeight: 40)
                } else {
                    Text(translatedText)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }

            // 底部：目标语言和重试按钮
            HStack {
                Text("→ \(translationManager.targetLanguage.displayName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                // 重新翻译按钮
                if !isLoading {
                    Button {
                        Task {
                            await performTranslation()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("重新翻译")
                }
            }
        }
        .padding(16)
        .frame(width: 380, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .task {
            await performTranslation()
        }
    }

    private func performTranslation() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await translationManager.translate(text: originalText)
            translatedText = result.translatedText

            // 通知翻译完成（用于保存历史记录）
            onTranslationComplete?(originalText, translatedText, result.engine)
        } catch {
            errorMessage = error.localizedDescription
            translatedText = ""
        }

        isLoading = false
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#Preview {
    TranslationPopoverView(originalText: "Hello, this is a test sentence for translation.")
        .padding()
}
