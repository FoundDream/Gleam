//
//  ScreenshotService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import AppKit
import Vision
import Combine

/// 截图服务
@MainActor
class ScreenshotService: ObservableObject {
    static let shared = ScreenshotService()

    /// 截图存储目录
    private let screenshotDirectory: URL

    private init() {
        // 创建截图存储目录
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        screenshotDirectory = appSupport.appendingPathComponent("Gleam/Screenshots")
        try? FileManager.default.createDirectory(at: screenshotDirectory, withIntermediateDirectories: true)
    }

    /// 触发截图
    func captureScreenshot() async throws -> ScreenshotItem {
        // 调用系统截图
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"] // 交互式截图到剪贴板

        try task.run()
        task.waitUntilExit()

        // 等待剪贴板更新
        try await Task.sleep(nanoseconds: 100_000_000)

        // 从剪贴板获取图片
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            throw ScreenshotError.noImageInClipboard
        }

        // 生成 ID 和路径
        let id = UUID()
        let imagePath = screenshotDirectory.appendingPathComponent("\(id.uuidString).png").path

        // 保存图片到磁盘
        try saveImage(image, to: imagePath)

        // 进行 OCR
        let ocrText = try await performOCR(on: image)

        return ScreenshotItem(
            id: id,
            timestamp: Date(),
            imagePath: imagePath,
            ocrText: ocrText,
            tags: []
        )
    }

    /// 保存图片到磁盘
    private func saveImage(_ image: NSImage, to path: String) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.saveFailed
        }

        try pngData.write(to: URL(fileURLWithPath: path))
        print("截图已保存到: \(path)")
    }

    /// 执行 OCR
    private func performOCR(on image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ScreenshotError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "ja", "ko"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// 加载截图图片
    func loadImage(for item: ScreenshotItem) -> NSImage? {
        guard !item.imagePath.isEmpty else { return nil }
        return NSImage(contentsOfFile: item.imagePath)
    }

    /// 获取截图存储目录
    var storageDirectory: URL {
        screenshotDirectory
    }

    /// 计算截图总大小
    func calculateTotalSize() -> Int64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: screenshotDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
}

/// 截图项
struct ScreenshotItem: Identifiable {
    let id: UUID
    let timestamp: Date
    let imagePath: String
    let ocrText: String
    var tags: [String]
}

/// 截图错误
enum ScreenshotError: Error, LocalizedError {
    case noImageInClipboard
    case invalidImage
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .noImageInClipboard:
            return "剪贴板中没有图片（可能取消了截图）"
        case .invalidImage:
            return "无效的图片"
        case .saveFailed:
            return "保存失败"
        }
    }
}
