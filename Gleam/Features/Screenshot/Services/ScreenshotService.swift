//
//  ScreenshotService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import AppKit
import Combine

/// Screenshot Service
@MainActor
class ScreenshotService: ObservableObject {
    static let shared = ScreenshotService()

    /// Screenshot storage directory
    let screenshotDirectory: URL

    private init() {
        // Create screenshot storage directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        screenshotDirectory = appSupport.appendingPathComponent("Gleam/Screenshots")
        try? FileManager.default.createDirectory(at: screenshotDirectory, withIntermediateDirectories: true)
    }

    /// Capture screenshot
    func captureScreenshot() async throws -> ScreenshotItem {
        // Call system screenshot
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"] // Interactive screenshot to clipboard

        try task.run()
        task.waitUntilExit()

        // Wait for clipboard update
        try await Task.sleep(nanoseconds: 200_000_000)

        // Get image from clipboard
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            throw ScreenshotError.noImageInClipboard
        }

        // Generate ID and path
        let id = UUID()
        let imagePath = screenshotDirectory.appendingPathComponent("\(id.uuidString).png").path

        // Save image to disk
        try saveImage(image, to: imagePath)

        return ScreenshotItem(
            id: id,
            timestamp: Date(),
            imagePath: imagePath,
            tags: []
        )
    }

    /// Save image to disk
    private func saveImage(_ image: NSImage, to path: String) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.saveFailed
        }

        try pngData.write(to: URL(fileURLWithPath: path))
        print("Screenshot saved to: \(path)")
    }

    /// Load screenshot image
    func loadImage(for item: ScreenshotItem) -> NSImage? {
        guard !item.imagePath.isEmpty else { return nil }
        return NSImage(contentsOfFile: item.imagePath)
    }

    /// Calculate total screenshot size
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

/// Screenshot Item
struct ScreenshotItem: Identifiable {
    let id: UUID
    let timestamp: Date
    let imagePath: String
    var tags: [String]
}

/// Screenshot Error
enum ScreenshotError: Error, LocalizedError {
    case noImageInClipboard
    case invalidImage
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .noImageInClipboard:
            return "No image in clipboard (screenshot may have been cancelled)"
        case .invalidImage:
            return "Invalid image"
        case .saveFailed:
            return "Save failed"
        }
    }
}
