//
//  AccessibilityService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import AppKit
import ApplicationServices

/// 辅助功能服务 - 用于获取选中文本
class AccessibilityService {
    static let shared = AccessibilityService()

    private init() {}

    /// 检查辅助功能权限
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// 请求辅助功能权限
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// 获取当前选中的文本
    func getSelectedText() -> String? {
        // 首先尝试从剪贴板获取（通过模拟 Cmd+C）
        let pasteboard = NSPasteboard.general
        let oldContent = pasteboard.string(forType: .string)

        // 模拟 Cmd+C
        simulateCommandC()

        // 等待剪贴板更新
        Thread.sleep(forTimeInterval: 0.1)

        let newContent = pasteboard.string(forType: .string)

        // 恢复剪贴板内容
        if let old = oldContent, old != newContent {
            // 延迟恢复，以便我们先获取到选中的文本
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                pasteboard.setString(old, forType: .string)
            }
        }

        // 如果内容有变化，返回新内容
        if newContent != oldContent {
            return newContent
        }

        // 如果剪贴板没变化，尝试通过辅助功能 API 获取
        return getSelectedTextViaAccessibility()
    }

    // MARK: - Private

    private func simulateCommandC() {
        let source = CGEventSource(stateID: .combinedSessionState)

        // 按下 Cmd
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand

        // 按下 C
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cDown?.flags = .maskCommand

        // 释放 C
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand

        // 释放 Cmd
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        let location = CGEventTapLocation.cghidEventTap
        cmdDown?.post(tap: location)
        cDown?.post(tap: location)
        cUp?.post(tap: location)
        cmdUp?.post(tap: location)
    }

    private func getSelectedTextViaAccessibility() -> String? {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else { return nil }

        let pid = focusedApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard result == .success, let element = focusedElement else { return nil }

        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)

        guard textResult == .success, let text = selectedText as? String else { return nil }

        return text.isEmpty ? nil : text
    }
}
