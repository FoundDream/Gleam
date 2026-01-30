//
//  MenuBarView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// 菜单栏弹出视图
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            headerSection

            Divider()
                .padding(.vertical, 8)

            // 功能模块
            featureModules

            Divider()
                .padding(.vertical, 8)

            // 底部操作
            bottomSection
        }
        .padding(12)
        .frame(width: 280)
    }

    // MARK: - 头部区域

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

            // 翻译引擎选择
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

    // MARK: - 功能模块

    private var featureModules: some View {
        VStack(spacing: 4) {
            // 划词翻译
            FeatureRow(
                icon: "character.book.closed",
                iconColor: .blue,
                title: "划词翻译",
                subtitle: "⌥T 触发",
                action: {}
            )

            // 截图 OCR
            FeatureRow(
                icon: "camera.viewfinder",
                iconColor: .orange,
                title: "截图 OCR",
                subtitle: "\(appState.screenshots.count) 张截图",
                action: {
                    Task {
                        await appState.captureScreenshot()
                    }
                }
            )

            // 收藏管理
            FeatureRow(
                icon: "star.fill",
                iconColor: .yellow,
                title: "收藏管理",
                subtitle: "\(appState.collections.count) 个收藏",
                action: {
                    NSApp.activate(ignoringOtherApps: true)
                }
            )
        }
    }

    // MARK: - 底部区域

    private var bottomSection: some View {
        HStack {
            Button("设置...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

// MARK: - 功能行组件

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
