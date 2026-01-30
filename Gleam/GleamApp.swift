//
//  GleamApp.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

@main
struct GleamApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        // 主窗口
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1000, height: 700)
        .commands {
            // 自定义菜单命令
            CommandGroup(after: .newItem) {
                Button("新建收藏") {
                    appState.showNewCollectionSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("截图") {
                    Task {
                        await appState.captureScreenshot()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        // 菜单栏图标
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: "sparkles")
        }
        .menuBarExtraStyle(.window)

        // 设置窗口
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
