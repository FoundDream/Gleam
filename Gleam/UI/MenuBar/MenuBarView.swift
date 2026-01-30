//
//  MenuBarView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// Menu Bar Popover View
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()
                .padding(.vertical, 8)

            // Feature modules
            featureModules

            Divider()
                .padding(.vertical, 8)

            // Bottom section
            bottomSection
        }
        .padding(12)
        .frame(width: 280)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Gleam")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Translation engine selection
            Menu {
                ForEach(TranslationEngine.allCases) { engine in
                    Button {
                        appState.selectedTranslationEngine = engine
                    } label: {
                        HStack {
                            Image(systemName: engine.iconName)
                            Text(engine.rawValue)
                            if appState.selectedTranslationEngine == engine {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
    }

    // MARK: - Feature Modules

    private var featureModules: some View {
        VStack(spacing: 4) {
            // Translate selection
            FeatureRow(
                icon: "character.book.closed",
                iconColor: .blue,
                title: "Translate Selection",
                subtitle: "⌥T to trigger",
                action: {}
            )

            // Screenshot OCR
            FeatureRow(
                icon: "camera.viewfinder",
                iconColor: .orange,
                title: "Screenshot OCR",
                subtitle: "\(appState.screenshots.count) screenshots",
                action: {
                    Task {
                        await appState.captureScreenshot()
                    }
                }
            )

            // Collection management
            FeatureRow(
                icon: "star.fill",
                iconColor: .yellow,
                title: "Collections",
                subtitle: "\(appState.collections.count) items",
                action: {
                    NSApp.activate(ignoringOtherApps: true)
                }
            )
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        HStack {
            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState())
}
