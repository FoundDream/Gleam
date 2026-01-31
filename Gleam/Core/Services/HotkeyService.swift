//
//  HotkeyService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import Carbon.HIToolbox
import AppKit

/// Global Hotkey Service
class HotkeyService {
    static let shared = HotkeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Hotkey callbacks
    var onTranslationHotkey: (() -> Void)?
    var onScreenshotHotkey: (() -> Void)?
    var onQuickNoteHotkey: (() -> Void)?  // 随手记快捷键

    private init() {}

    /// Register all hotkeys
    func registerHotkeys() {
        // Register translation hotkey (Option + T)
        registerHotkey(
            id: 1,
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(optionKey)
        )

        // Register screenshot hotkey (Option + S)
        registerHotkey(
            id: 2,
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(optionKey)
        )

        // Register quick note hotkey (Option + C) 随手记
        registerHotkey(
            id: 3,
            keyCode: UInt32(kVK_ANSI_C),
            modifiers: UInt32(optionKey)
        )

        setupEventHandler()
    }

    /// Unregister all hotkeys
    func unregisterHotkeys() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    // MARK: - Private

    private func registerHotkey(id: UInt32, keyCode: UInt32, modifiers: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("GLAM".utf8.reduce(0) { ($0 << 8) + UInt32($1) })
        hotKeyID.id = id

        var carbonModifiers: UInt32 = 0
        if modifiers & UInt32(optionKey) != 0 { carbonModifiers |= UInt32(optionKey) }
        if modifiers & UInt32(cmdKey) != 0 { carbonModifiers |= UInt32(cmdKey) }
        if modifiers & UInt32(shiftKey) != 0 { carbonModifiers |= UInt32(shiftKey) }
        if modifiers & UInt32(controlKey) != 0 { carbonModifiers |= UInt32(controlKey) }

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr {
            print("Hotkey \(id) registered successfully")
        } else {
            print("Failed to register hotkey \(id): \(status)")
        }
    }

    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            DispatchQueue.main.async {
                switch hotKeyID.id {
                case 1:
                    HotkeyService.shared.onTranslationHotkey?()
                case 2:
                    HotkeyService.shared.onScreenshotHotkey?()
                case 3:
                    HotkeyService.shared.onQuickNoteHotkey?()  // 随手记
                default:
                    break
                }
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }
}
