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

        // 划词翻译
        hotkeyService.onTranslationHotkey = { [weak self] in
            self?.handleTranslationHotkey()
        }

        // 截图 OCR
        hotkeyService.onScreenshotHotkey = {
            Task {
                do {
                    let item = try await ScreenshotService.shared.captureScreenshot()
                    print("截图成功，OCR 文字: \(item.ocrText)")
                } catch {
                    print("截图失败: \(error)")
                }
            }
        }

        // 快速收藏
        hotkeyService.onCollectionHotkey = {
            // TODO: 显示快速收藏面板
            print("快速收藏快捷键触发")
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

        // 创建翻译视图，带回调保存历史和关闭功能
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
        let panel = TranslationPanel(
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

        // 设置关闭回调
        panel.onClose = { [weak self] in
            self?.translationPanel = nil
        }

        // 定位到鼠标位置
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        var x = mouseLocation.x - 190
        var y = mouseLocation.y - 240

        // 确保窗口不超出屏幕
        x = max(screenFrame.minX, min(x, screenFrame.maxX - 380))
        y = max(screenFrame.minY, min(y, screenFrame.maxY - 220))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.makeKeyAndOrderFront(nil)
        translationPanel = panel
    }

    func closeTranslationPanel() {
        translationPanel?.close()
        translationPanel = nil
    }
}

// MARK: - 自定义翻译面板

class TranslationPanel: NSPanel {
    var onClose: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        // ESC 键关闭
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
