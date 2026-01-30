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
        // 保持 Dock 图标可见
        NSApp.setActivationPolicy(.regular)

        // 检查辅助功能权限
        checkAccessibilityPermission()

        // 初始化数据库
        _ = DatabaseManager.shared

        // 注册全局快捷键
        setupHotkeys()

        print("Gleam 启动完成")
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyService.shared.unregisterHotkeys()
    }

    // MARK: - 权限检查

    private func checkAccessibilityPermission() {
        if !AccessibilityService.shared.hasAccessibilityPermission {
            AccessibilityService.shared.requestAccessibilityPermission()
        }
    }

    // MARK: - 快捷键设置

    private func setupHotkeys() {
        let hotkeyService = HotkeyService.shared

        // 划词翻译 ⌥T
        hotkeyService.onTranslationHotkey = { [weak self] in
            self?.handleTranslationHotkey()
        }

        // 截图 OCR ⌥S
        hotkeyService.onScreenshotHotkey = {
            Task { @MainActor in
                await AppState.shared.captureScreenshot()
            }
        }

        // 快速收藏 ⌥C
        hotkeyService.onCollectionHotkey = { [weak self] in
            self?.handleCollectionHotkey()
        }

        hotkeyService.registerHotkeys()
    }

    // MARK: - 翻译处理

    private func handleTranslationHotkey() {
        guard let selectedText = AccessibilityService.shared.getSelectedText(),
              !selectedText.isEmpty else {
            print("没有选中文本")
            return
        }

        showTranslationPanel(for: selectedText)
    }

    private func showTranslationPanel(for text: String) {
        // 关闭现有面板
        translationPanel?.close()
        translationPanel = nil

        // 创建翻译视图
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

        // 创建浮窗
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

    // MARK: - 收藏处理

    private func handleCollectionHotkey() {
        guard let selectedText = AccessibilityService.shared.getSelectedText(),
              !selectedText.isEmpty else {
            print("没有选中文本")
            return
        }

        showCollectionPanel(for: selectedText)
    }

    private func showCollectionPanel(for text: String) {
        // 关闭现有面板
        collectionPanel?.close()
        collectionPanel = nil

        // 创建收藏视图
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

        // 创建浮窗
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

    // MARK: - 辅助方法

    private func positionPanel(_ panel: NSPanel, width: CGFloat, height: CGFloat) {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        var x = mouseLocation.x - width / 2
        var y = mouseLocation.y - height - 20

        // 确保窗口不超出屏幕
        x = max(screenFrame.minX + 10, min(x, screenFrame.maxX - width - 10))
        y = max(screenFrame.minY + 10, min(y, screenFrame.maxY - height - 10))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - 自定义面板

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
