//
//  TranslationService.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import Foundation
import Combine

/// Translation Service Protocol
protocol TranslationServiceProtocol {
    func translate(text: String, from: Language, to: Language) async throws -> TranslationResult
}

/// Translation Result
struct TranslationResult {
    let originalText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let engine: TranslationEngine
    let timestamp: Date
}

/// Supported Languages
enum Language: String, CaseIterable, Identifiable {
    case auto = "auto"
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto Detect"
        case .english: return "English"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .french: return "French"
        case .german: return "German"
        case .spanish: return "Spanish"
        }
    }

    var nativeName: String {
        switch self {
        case .auto: return "Auto"
        case .english: return "English"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .french: return "French"
        case .german: return "German"
        case .spanish: return "Spanish"
        }
    }
}

/// Translation Error
enum TranslationError: Error, LocalizedError {
    case noApiKey
    case networkError(String)
    case apiError(String)
    case invalidResponse
    case unsupportedEngine

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "Please configure API Key in Settings first"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidResponse:
            return "Invalid response"
        case .unsupportedEngine:
            return "This translation engine is not supported yet"
        }
    }
}

/// Translation Service Manager
@MainActor
class TranslationServiceManager: ObservableObject {
    static let shared = TranslationServiceManager()

    @Published var currentEngine: TranslationEngine = .deepSeek

    // API Keys (loaded from UserDefaults)
    @Published var deepSeekApiKey: String {
        didSet { UserDefaults.standard.set(deepSeekApiKey, forKey: "deepSeekApiKey") }
    }
    @Published var openAIApiKey: String {
        didSet { UserDefaults.standard.set(openAIApiKey, forKey: "openAIApiKey") }
    }
    @Published var deepLApiKey: String {
        didSet { UserDefaults.standard.set(deepLApiKey, forKey: "deepLApiKey") }
    }

    // Target language setting
    @Published var targetLanguage: Language {
        didSet { UserDefaults.standard.set(targetLanguage.rawValue, forKey: "targetLanguage") }
    }

    private init() {
        self.deepSeekApiKey = UserDefaults.standard.string(forKey: "deepSeekApiKey") ?? ""
        self.openAIApiKey = UserDefaults.standard.string(forKey: "openAIApiKey") ?? ""
        self.deepLApiKey = UserDefaults.standard.string(forKey: "deepLApiKey") ?? ""
        self.targetLanguage = Language(rawValue: UserDefaults.standard.string(forKey: "targetLanguage") ?? "zh") ?? .chinese

        if let savedEngine = UserDefaults.standard.string(forKey: "translationEngine"),
           let engine = TranslationEngine(rawValue: savedEngine) {
            self.currentEngine = engine
        }
    }

    func setEngine(_ engine: TranslationEngine) {
        currentEngine = engine
        UserDefaults.standard.set(engine.rawValue, forKey: "translationEngine")
    }

    func translate(text: String, from: Language = .auto, to: Language? = nil) async throws -> TranslationResult {
        let targetLang = to ?? targetLanguage

        switch currentEngine {
        case .deepSeek:
            return try await translateWithDeepSeek(text: text, from: from, to: targetLang)
        case .openAI:
            return try await translateWithOpenAI(text: text, from: from, to: targetLang)
        case .deepL:
            return try await translateWithDeepL(text: text, from: from, to: targetLang)
        case .google:
            throw TranslationError.unsupportedEngine
        }
    }

    // MARK: - DeepSeek Translation

    private func translateWithDeepSeek(text: String, from: Language, to: Language) async throws -> TranslationResult {
        guard !deepSeekApiKey.isEmpty else {
            throw TranslationError.noApiKey
        }

        let prompt = buildTranslationPrompt(text: text, from: from, to: to)

        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "You are a professional translator. Translate the given text accurately and naturally. Only output the translation, nothing else."],
                ["role": "user", "content": prompt]
            ],
        ]

        let translatedText = try await callOpenAICompatibleAPI(
            url: "https://api.deepseek.com/chat/completions",
            apiKey: deepSeekApiKey,
            body: requestBody
        )

        return TranslationResult(
            originalText: text,
            translatedText: translatedText,
            sourceLanguage: from,
            targetLanguage: to,
            engine: .deepSeek,
            timestamp: Date()
        )
    }

    // MARK: - OpenAI Translation

    private func translateWithOpenAI(text: String, from: Language, to: Language) async throws -> TranslationResult {
        guard !openAIApiKey.isEmpty else {
            throw TranslationError.noApiKey
        }

        let prompt = buildTranslationPrompt(text: text, from: from, to: to)

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a professional translator. Translate the given text accurately and naturally. Only output the translation, nothing else."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 2000
        ]

        let translatedText = try await callOpenAICompatibleAPI(
            url: "https://api.openai.com/v1/chat/completions",
            apiKey: openAIApiKey,
            body: requestBody
        )

        return TranslationResult(
            originalText: text,
            translatedText: translatedText,
            sourceLanguage: from,
            targetLanguage: to,
            engine: .openAI,
            timestamp: Date()
        )
    }

    // MARK: - DeepL Translation

    private func translateWithDeepL(text: String, from: Language, to: Language) async throws -> TranslationResult {
        guard !deepLApiKey.isEmpty else {
            throw TranslationError.noApiKey
        }

        // DeepL API
        let url = URL(string: "https://api-free.deepl.com/v2/translate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(deepLApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "text": [text],
            "target_lang": to == .chinese ? "ZH" : to.rawValue.uppercased()
        ]

        if from != .auto {
            body["source_lang"] = from.rawValue.uppercased()
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranslationError.apiError(errorMessage)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translations = json["translations"] as? [[String: Any]],
              let firstTranslation = translations.first,
              let translatedText = firstTranslation["text"] as? String else {
            throw TranslationError.invalidResponse
        }

        return TranslationResult(
            originalText: text,
            translatedText: translatedText,
            sourceLanguage: from,
            targetLanguage: to,
            engine: .deepL,
            timestamp: Date()
        )
    }

    // MARK: - Helpers

    private func buildTranslationPrompt(text: String, from: Language, to: Language) -> String {
        let fromLang = from == .auto ? "the source language" : from.nativeName
        let toLang = to.nativeName

        return "Translate the following text from \(fromLang) to \(toLang):\n\n\(text)"
    }

    private func callOpenAICompatibleAPI(url: String, apiKey: String, body: [String: Any]) async throws -> String {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw TranslationError.apiError(message)
            }
            throw TranslationError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw TranslationError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
