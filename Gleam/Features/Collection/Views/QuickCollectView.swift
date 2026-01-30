//
//  QuickCollectView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// Quick Collect Popover
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
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Quick Collect")
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
                // Save success state
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("Saved")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                Divider()

                // Title
                TextField("Title (optional)", text: $title)
                    .textFieldStyle(.plain)
                    .font(.body)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Content")
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

                // Tags
                TextField("Tags (comma separated)", text: $tagsInput)
                    .textFieldStyle(.plain)
                    .font(.caption)

                Divider()

                // Buttons
                HStack {
                    Button("Cancel") {
                        onClose?()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Save") {
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
            // Auto-generate title
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

        let finalTitle = title.isEmpty ? "Untitled Collection" : title

        onSave?(finalTitle, content, tags)

        // Show success state
        withAnimation {
            isSaved = true
        }

        // Auto-close after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onClose?()
        }
    }
}

#Preview {
    QuickCollectView(initialText: "This is some text content to collect")
        .padding()
}
