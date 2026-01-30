//
//  AccessibilityService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import AppKit
import ApplicationServices
import Carbon.HIToolbox

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
        // 保存当前剪贴板内容
        let pasteboard = NSPasteboard.general
        let oldChangeCount = pasteboard.changeCount
        let oldContent = pasteboard.string(forType: .string)

        // 模拟 Cmd+C 复制
        simulateCopy()

        // 等待剪贴板更新
        usleep(150000) // 150ms

        // 检查剪贴板是否有变化
        if pasteboard.changeCount != oldChangeCount {
            if let newContent = pasteboard.string(forType: .string), !newContent.isEmpty {
                // 延迟恢复剪贴板
                if let old = oldContent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pasteboard.clearContents()
                        pasteboard.setString(old, forType: .string)
                    }
                }
                return newContent
            }
        }

        // 剪贴板没变化，尝试通过 Accessibility API
        if let text = getSelectedTextViaAccessibility(), !text.isEmpty {
            return text
        }

        return nil
    }

    // MARK: - Private

    private func simulateCopy() {
        // 使用 CGEvent 模拟 Cmd+C
        let source = CGEventSource(stateID: .hidSystemState)

        // Cmd down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
        cmdDown?.flags = .maskCommand

        // C down
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        cDown?.flags = .maskCommand

        // C up
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        cUp?.flags = .maskCommand

        // Cmd up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: false)

        // 发送事件
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }

    private func getSelectedTextViaAccessibility() -> String? {
        guard hasAccessibilityPermission else {
            print("没有辅助功能权限")
            return nil
        }

        guard let focusedApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let pid = focusedApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else {
            return nil
        }

        var selectedText: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
              let text = selectedText as? String else {
            return nil
        }

        return text
    }
}
