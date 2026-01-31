//
//  TranslationPopoverView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// Translation Popover View
struct TranslationPopoverView: View {
    let originalText: String
    var onTranslationComplete: ((String, String, TranslationEngine) -> Void)?
    var onClose: (() -> Void)?

    @ObservedObject private var translationManager = TranslationServiceManager.shared
    @State private var translatedText: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Text("翻译")
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

            Divider()
                .padding(.horizontal, 12)

            // 内容区域 - 使用 ScrollView 支持长文本
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // 原文
                    VStack(alignment: .leading, spacing: 6) {
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
                        }

                        Text(originalText)
                            .font(.body)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.3))
                    .cornerRadius(8)

                    // 译文
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("译文")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Engine selection
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
                                        .font(.caption2)
                                    Text(translationManager.currentEngine.rawValue)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(5)
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
                        }

                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("翻译中...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .frame(minHeight: 40)
                        } else if let error = errorMessage {
                            VStack(alignment: .leading, spacing: 6) {
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
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding(12)
            }
            .frame(maxHeight: 350)

            Divider()
                .padding(.horizontal, 12)

            // Footer
            HStack {
                Text("→ \(translationManager.targetLanguage.displayName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if !isLoading {
                    Button {
                        Task {
                            await performTranslation()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("重试")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 380)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
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

            // Notify translation complete (for saving history)
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
    TranslationPopoverView(originalText: "Hello, this is a test sentence for translation.\nThis is another line.\nAnd a third line to test multi-line support.")
        .padding()
}
