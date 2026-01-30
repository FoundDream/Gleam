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
        VStack(alignment: .leading, spacing: 12) {
            // Header with close button
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Text("Gleam Translation")
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
                .help("Close (ESC)")
            }

            Divider()

            // Original text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Original")
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
                    .help("Copy original")
                }

                Text(originalText)
                    .font(.body)
                    .textSelection(.enabled)
                    .lineLimit(5)
            }

            Divider()

            // Translated text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Translation")
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
                    .help("Copy translation")
                }

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Translating with \(translationManager.currentEngine.rawValue)...")
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
                            Button("Open Settings") {
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

            // Footer: target language and retry button
            HStack {
                Text("→ \(translationManager.targetLanguage.displayName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                // Retry translation button
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
                    .help("Retry translation")
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
    TranslationPopoverView(originalText: "Hello, this is a test sentence for translation.")
        .padding()
}
