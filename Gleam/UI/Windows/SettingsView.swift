//
//  SettingsView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            TranslationSettingsView()
                .tabItem {
                    Label("Translation", systemImage: "character.book.closed")
                }

            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            StorageSettingsView()
                .tabItem {
                    Label("Storage", systemImage: "externaldrive")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showDockIcon") private var showDockIcon = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show Dock Icon", isOn: $showDockIcon)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Translation Settings

struct TranslationSettingsView: View {
    @ObservedObject private var translationManager = TranslationServiceManager.shared
    @State private var showApiKey = false

    var body: some View {
        Form {
            Section("Default Translation Engine") {
                Picker("Engine", selection: Binding(
                    get: { translationManager.currentEngine },
                    set: { translationManager.setEngine($0) }
                )) {
                    ForEach(TranslationEngine.allCases) { engine in
                        Label(engine.rawValue, systemImage: engine.iconName).tag(engine)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Target Language") {
                Picker("Translate to", selection: $translationManager.targetLanguage) {
                    ForEach(Language.allCases.filter { $0 != .auto }) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }

            Section("API Keys") {
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

                Text("API Keys are stored securely on your device and never uploaded to any server")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Link("Get DeepSeek API Key", destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                Link("Get OpenAI API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                Link("Get DeepL API Key", destination: URL(string: "https://www.deepl.com/pro-api")!)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Global Shortcuts") {
                HStack {
                    Text("Translate Selection")
                    Spacer()
                    Text("⌥T")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                HStack {
                    Text("Screenshot OCR")
                    Spacer()
                    Text("⌥S")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                HStack {
                    Text("Quick Collect")
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

// MARK: - Storage Settings

struct StorageSettingsView: View {
    var body: some View {
        Form {
            Section("Data Storage") {
                HStack {
                    Text("Screenshot Location")
                    Spacer()
                    Text("~/Pictures/Gleam")
                        .foregroundColor(.secondary)
                    Button("Change...") {}
                }

                HStack {
                    Text("Database Size")
                    Spacer()
                    Text("0 MB")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("Clear Cache") {}
                Button("Export Data...") {}
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About

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

            Text("Version 1.0.0")
                .foregroundColor(.secondary)

            Text("An elegant macOS productivity tool")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()
                .frame(width: 200)

            Text("划词翻译 · 截图 OCR · 随手记")
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
