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
        // Main window
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1000, height: 700)
        .commands {
            // Custom menu commands
            CommandGroup(after: .newItem) {
                Button("New Collection") {
                    appState.showNewCollectionSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("Screenshot") {
                    Task {
                        await appState.captureScreenshot()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        // Menu bar icon
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: "sparkles")
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
