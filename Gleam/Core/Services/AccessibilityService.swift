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

/// Accessibility Service - for getting selected text
class AccessibilityService {
    static let shared = AccessibilityService()

    private init() {}

    /// Check accessibility permission
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Request accessibility permission
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Get currently selected text
    func getSelectedText() -> String? {
        // Save current clipboard content
        let pasteboard = NSPasteboard.general
        let oldChangeCount = pasteboard.changeCount
        let oldContent = pasteboard.string(forType: .string)

        // Simulate Cmd+C copy
        simulateCopy()

        // Wait for clipboard update
        usleep(150000) // 150ms

        // Check if clipboard has changed
        if pasteboard.changeCount != oldChangeCount {
            if let newContent = pasteboard.string(forType: .string), !newContent.isEmpty {
                // Restore clipboard after delay
                if let old = oldContent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pasteboard.clearContents()
                        pasteboard.setString(old, forType: .string)
                    }
                }
                return newContent
            }
        }

        // Clipboard unchanged, try via Accessibility API
        if let text = getSelectedTextViaAccessibility(), !text.isEmpty {
            return text
        }

        return nil
    }

    // MARK: - Private

    private func simulateCopy() {
        // Use CGEvent to simulate Cmd+C
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

        // Post events
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }

    private func getSelectedTextViaAccessibility() -> String? {
        guard hasAccessibilityPermission else {
            print("No accessibility permission")
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
