//
//  SettingsView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// 设置视图
struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            TranslationSettingsView()
                .tabItem {
                    Label("翻译", systemImage: "character.book.closed")
                }

            ShortcutsSettingsView()
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }

            StorageSettingsView()
                .tabItem {
                    Label("存储", systemImage: "externaldrive")
                }

            AboutSettingsView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}

// MARK: - 通用设置

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showDockIcon") private var showDockIcon = false

    var body: some View {
        Form {
            Section {
                Toggle("开机自启动", isOn: $launchAtLogin)
                Toggle("显示 Dock 图标", isOn: $showDockIcon)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 翻译设置

struct TranslationSettingsView: View {
    @ObservedObject private var translationManager = TranslationServiceManager.shared
    @State private var showApiKey = false

    var body: some View {
        Form {
            Section("默认翻译引擎") {
                Picker("引擎", selection: Binding(
                    get: { translationManager.currentEngine },
                    set: { translationManager.setEngine($0) }
                )) {
                    ForEach(TranslationEngine.allCases) { engine in
                        Label(engine.rawValue, systemImage: engine.iconName).tag(engine)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("目标语言") {
                Picker("翻译为", selection: $translationManager.targetLanguage) {
                    ForEach(Language.allCases.filter { $0 != .auto }) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }

            Section("API 密钥") {
                HStack {
                    if showApiKey {
                        TextField("DeepSeek API Key", text: $translationManager.deepSeekApiKey)
                    } else {
                        SecureField("DeepSeek API Key", text: $translationManager.deepSeekApiKey)
                    }
                    Button {
                        showApiKey.toggle()
                    } label: {
                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                SecureField("OpenAI API Key", text: $translationManager.openAIApiKey)
                SecureField("DeepL API Key", text: $translationManager.deepLApiKey)

                Text("API Key 安全地存储在本地，不会上传到任何服务器")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Link("获取 DeepSeek API Key", destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                Link("获取 OpenAI API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                Link("获取 DeepL API Key", destination: URL(string: "https://www.deepl.com/pro-api")!)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 快捷键设置

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("全局快捷键") {
                HStack {
                    Text("划词翻译")
                    Spacer()
                    Text("⌥T")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                HStack {
                    Text("截图 OCR")
                    Spacer()
                    Text("⌥S")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                HStack {
                    Text("快速收藏")
                    Spacer()
                    Text("⌥C")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 存储设置

struct StorageSettingsView: View {
    var body: some View {
        Form {
            Section("数据存储") {
                HStack {
                    Text("截图存储位置")
                    Spacer()
                    Text("~/Pictures/Gleam")
                        .foregroundColor(.secondary)
                    Button("更改...") {}
                }

                HStack {
                    Text("数据库大小")
                    Spacer()
                    Text("0 MB")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("清理缓存") {}
                Button("导出数据...") {}
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 关于

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Gleam")
                .font(.title)
                .fontWeight(.bold)

            Text("版本 1.0.0")
                .foregroundColor(.secondary)

            Text("一款优雅的 macOS 效率工具")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()
                .frame(width: 200)

            Text("划词翻译 · 截图 OCR · 收藏管理")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
