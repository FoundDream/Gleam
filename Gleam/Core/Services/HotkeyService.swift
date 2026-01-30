//
//  HotkeyService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import Carbon.HIToolbox
import AppKit

/// 全局快捷键服务
class HotkeyService {
    static let shared = HotkeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // 快捷键回调
    var onTranslationHotkey: (() -> Void)?
    var onScreenshotHotkey: (() -> Void)?
    var onCollectionHotkey: (() -> Void)?

    private init() {}

    /// 注册所有快捷键
    func registerHotkeys() {
        // 注册翻译快捷键 (Option + T)
        registerHotkey(
            id: 1,
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(optionKey)
        )

        // 注册截图快捷键 (Option + S)
        registerHotkey(
            id: 2,
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(optionKey)
        )

        // 注册收藏快捷键 (Option + C)
        registerHotkey(
            id: 3,
            keyCode: UInt32(kVK_ANSI_C),
            modifiers: UInt32(optionKey)
        )

        setupEventHandler()
    }

    /// 注销所有快捷键
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
            print("快捷键 \(id) 注册成功")
        } else {
            print("快捷键 \(id) 注册失败: \(status)")
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
                    HotkeyService.shared.onCollectionHotkey?()
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
