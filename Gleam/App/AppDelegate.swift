//
//  AppDelegate.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {

    private var translationPanel: NSPanel?
    private var collectionPanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep Dock icon visible
        NSApp.setActivationPolicy(.regular)

        // Check accessibility permission
        checkAccessibilityPermission()

        // Initialize database
        _ = DatabaseManager.shared

        // Register global hotkeys
        setupHotkeys()

        print("Gleam launched successfully")
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyService.shared.unregisterHotkeys()
    }

    // MARK: - Permission Check

    private func checkAccessibilityPermission() {
        if !AccessibilityService.shared.hasAccessibilityPermission {
            AccessibilityService.shared.requestAccessibilityPermission()
        }
    }

    // MARK: - Hotkey Setup

    private func setupHotkeys() {
        let hotkeyService = HotkeyService.shared

        // Translate selection ⌥T
        hotkeyService.onTranslationHotkey = { [weak self] in
            self?.handleTranslationHotkey()
        }

        // Screenshot OCR ⌥S
        hotkeyService.onScreenshotHotkey = {
            Task { @MainActor in
                await AppState.shared.captureScreenshot()
            }
        }

        // Quick collect ⌥C
        hotkeyService.onCollectionHotkey = { [weak self] in
            self?.handleCollectionHotkey()
        }

        hotkeyService.registerHotkeys()
    }

    // MARK: - Translation Handling

    private func handleTranslationHotkey() {
        guard let selectedText = AccessibilityService.shared.getSelectedText(),
              !selectedText.isEmpty else {
            print("No text selected")
            return
        }

        showTranslationPanel(for: selectedText)
    }

    private func showTranslationPanel(for text: String) {
        // Close existing panel
        translationPanel?.close()
        translationPanel = nil

        // Create translation view
        let contentView = TranslationPopoverView(
            originalText: text,
            onTranslationComplete: { original, translated, engine in
                Task { @MainActor in
                    AppState.shared.addTranslationRecord(original: original, translated: translated, engine: engine)
                }
            },
            onClose: { [weak self] in
                self?.closeTranslationPanel()
            }
        )
        let hostingView = NSHostingView(rootView: contentView)

        // Create floating panel
        let panel = GleamPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 220),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        panel.onClose = { [weak self] in
            self?.translationPanel = nil
        }

        positionPanel(panel, width: 380, height: 220)
        panel.makeKeyAndOrderFront(nil)
        translationPanel = panel
    }

    func closeTranslationPanel() {
        translationPanel?.close()
        translationPanel = nil
    }

    // MARK: - Collection Handling

    private func handleCollectionHotkey() {
        guard let selectedText = AccessibilityService.shared.getSelectedText(),
              !selectedText.isEmpty else {
            print("No text selected")
            return
        }

        showCollectionPanel(for: selectedText)
    }

    private func showCollectionPanel(for text: String) {
        // Close existing panel
        collectionPanel?.close()
        collectionPanel = nil

        // Create collection view
        let contentView = QuickCollectView(
            initialText: text,
            onSave: { title, content, tags in
                Task { @MainActor in
                    AppState.shared.addCollection(
                        type: .text,
                        title: title,
                        content: content,
                        tags: tags
                    )
                }
            },
            onClose: { [weak self] in
                self?.closeCollectionPanel()
            }
        )
        let hostingView = NSHostingView(rootView: contentView)

        // Create floating panel
        let panel = GleamPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 280),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        panel.onClose = { [weak self] in
            self?.collectionPanel = nil
        }

        positionPanel(panel, width: 340, height: 280)
        panel.makeKeyAndOrderFront(nil)
        collectionPanel = panel
    }

    func closeCollectionPanel() {
        collectionPanel?.close()
        collectionPanel = nil
    }

    // MARK: - Helper Methods

    private func positionPanel(_ panel: NSPanel, width: CGFloat, height: CGFloat) {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        var x = mouseLocation.x - width / 2
        var y = mouseLocation.y - height - 20

        // Ensure window doesn't exceed screen bounds
        x = max(screenFrame.minX + 10, min(x, screenFrame.maxX - width - 10))
        y = max(screenFrame.minY + 10, min(y, screenFrame.maxY - height - 10))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - Custom Panel

class GleamPanel: NSPanel {
    var onClose: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func close() {
        super.close()
        onClose?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            close()
        } else {
            super.keyDown(with: event)
        }
    }
}
