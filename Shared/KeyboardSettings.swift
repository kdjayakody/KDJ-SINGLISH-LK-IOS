import Foundation
import UIKit

enum KeyboardAccent: String, CaseIterable {
    case black = "black"
    case orange = "orange"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case red = "red"

    var displayName: String {
        switch self {
        case .black: return "Black"
        case .orange: return "Orange"
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        case .red: return "Red"
        }
    }

    var color: UIColor {
        switch self {
        case .black: return .black
        case .orange: return UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0)
        case .blue: return UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        case .green: return UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0)
        case .purple: return UIColor(red: 0.58, green: 0.29, blue: 0.85, alpha: 1.0)
        case .red: return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }

    var swiftUIColor: Color {
        Color(color)
    }
}

import SwiftUI

final class KeyboardSettings: ObservableObject {
    static let shared = KeyboardSettings()
    private let suite: UserDefaults

    @Published var showNumberRow: Bool {
        didSet { suite.set(showNumberRow, forKey: "showNumberRow") }
    }
    @Published var autoSpaceAfterPunctuation: Bool {
        didSet { suite.set(autoSpaceAfterPunctuation, forKey: "autoSpaceAfterPunctuation") }
    }
    @Published var hapticFeedback: Bool {
        didSet { suite.set(hapticFeedback, forKey: "hapticFeedback") }
    }
    @Published var keyPreview: Bool {
        didSet { suite.set(keyPreview, forKey: "keyPreview") }
    }
    @Published var doubleSpacePeriod: Bool {
        didSet { suite.set(doubleSpacePeriod, forKey: "doubleSpacePeriod") }
    }
    @Published var showClipboardPaste: Bool {
        didSet { suite.set(showClipboardPaste, forKey: "showClipboardPaste") }
    }
    @Published var accentColor: KeyboardAccent {
        didSet { suite.set(accentColor.rawValue, forKey: "accentColor") }
    }
    @Published var enableSuggestions: Bool {
        didSet { suite.set(enableSuggestions, forKey: "enableSuggestions") }
    }
    @Published var enableLearning: Bool {
        didSet { suite.set(enableLearning, forKey: "enableLearning") }
    }

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    private init() {
        suite = UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard
        showNumberRow = suite.object(forKey: "showNumberRow") as? Bool ?? true
        autoSpaceAfterPunctuation = suite.object(forKey: "autoSpaceAfterPunctuation") as? Bool ?? true
        hapticFeedback = suite.object(forKey: "hapticFeedback") as? Bool ?? true
        keyPreview = suite.object(forKey: "keyPreview") as? Bool ?? true
        doubleSpacePeriod = suite.object(forKey: "doubleSpacePeriod") as? Bool ?? true
        showClipboardPaste = suite.object(forKey: "showClipboardPaste") as? Bool ?? true
        enableSuggestions = suite.object(forKey: "enableSuggestions") as? Bool ?? true
        enableLearning = suite.object(forKey: "enableLearning") as? Bool ?? true
        accentColor = KeyboardAccent(rawValue: suite.string(forKey: "accentColor") ?? "") ?? .black

        hapticGenerator.prepare()

        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: suite,
            queue: .main
        ) { [weak self] _ in
            self?.reloadFromSuite()
        }
    }

    private func reloadFromSuite() {
        showNumberRow = suite.object(forKey: "showNumberRow") as? Bool ?? true
        autoSpaceAfterPunctuation = suite.object(forKey: "autoSpaceAfterPunctuation") as? Bool ?? true
        hapticFeedback = suite.object(forKey: "hapticFeedback") as? Bool ?? true
        keyPreview = suite.object(forKey: "keyPreview") as? Bool ?? true
        doubleSpacePeriod = suite.object(forKey: "doubleSpacePeriod") as? Bool ?? true
        showClipboardPaste = suite.object(forKey: "showClipboardPaste") as? Bool ?? true
        enableSuggestions = suite.object(forKey: "enableSuggestions") as? Bool ?? true
        enableLearning = suite.object(forKey: "enableLearning") as? Bool ?? true
        accentColor = KeyboardAccent(rawValue: suite.string(forKey: "accentColor") ?? "") ?? .black
    }

    func performHaptic() {
        guard hapticFeedback else { return }
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred()
    }
}

final class LearnedWords {
    static let shared = LearnedWords()
    private let suite: UserDefaults
    private let key = "learnedWordFrequencies"

    private init() {
        suite = UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard
    }

    private func load() -> [String: Int] {
        suite.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    func record(_ word: String) {
        let cleaned = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        var freq = load()
        freq[cleaned, default: 0] += 1
        suite.set(freq, forKey: key)
    }

    func suggestions(for prefix: String, limit: Int = 3) -> [String] {
        let freq = load()
        let lower = prefix.lowercased()
        let matches = freq
            .filter { $0.key.hasPrefix(lower) }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        return Array(matches)
    }
}
