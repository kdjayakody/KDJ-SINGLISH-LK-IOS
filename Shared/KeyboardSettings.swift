import Foundation
import UIKit
import SwiftUI

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

final class KeyboardSettings: ObservableObject {
    static let shared = KeyboardSettings()
    private let suite: UserDefaults
    private var isReloadingFromSuite = false

    @Published var showNumberRow: Bool {
        didSet { persist(showNumberRow, forKey: "showNumberRow") }
    }
    @Published var autoSpaceAfterPunctuation: Bool {
        didSet { persist(autoSpaceAfterPunctuation, forKey: "autoSpaceAfterPunctuation") }
    }
    @Published var hapticFeedback: Bool {
        didSet { persist(hapticFeedback, forKey: "hapticFeedback") }
    }
    @Published var keyPreview: Bool {
        didSet { persist(keyPreview, forKey: "keyPreview") }
    }
    @Published var doubleSpacePeriod: Bool {
        didSet { persist(doubleSpacePeriod, forKey: "doubleSpacePeriod") }
    }
    @Published var showClipboardPaste: Bool {
        didSet { persist(showClipboardPaste, forKey: "showClipboardPaste") }
    }
    @Published var accentColor: KeyboardAccent {
        didSet { persist(accentColor.rawValue, forKey: "accentColor") }
    }
    @Published var enableSuggestions: Bool {
        didSet { persist(enableSuggestions, forKey: "enableSuggestions") }
    }
    @Published var enableLearning: Bool {
        didSet { persist(enableLearning, forKey: "enableLearning") }
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

    private func persist(_ value: Any, forKey key: String) {
        guard !isReloadingFromSuite else { return }
        suite.set(value, forKey: key)
    }

    private func reloadFromSuite() {
        isReloadingFromSuite = true
        showNumberRow = suite.object(forKey: "showNumberRow") as? Bool ?? true
        autoSpaceAfterPunctuation = suite.object(forKey: "autoSpaceAfterPunctuation") as? Bool ?? true
        hapticFeedback = suite.object(forKey: "hapticFeedback") as? Bool ?? true
        keyPreview = suite.object(forKey: "keyPreview") as? Bool ?? true
        doubleSpacePeriod = suite.object(forKey: "doubleSpacePeriod") as? Bool ?? true
        showClipboardPaste = suite.object(forKey: "showClipboardPaste") as? Bool ?? true
        enableSuggestions = suite.object(forKey: "enableSuggestions") as? Bool ?? true
        enableLearning = suite.object(forKey: "enableLearning") as? Bool ?? true
        accentColor = KeyboardAccent(rawValue: suite.string(forKey: "accentColor") ?? "") ?? .black
        isReloadingFromSuite = false
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

    struct Entry: Codable {
        let input: String
        let output: String
        var count: Int
    }

    private init() {
        suite = UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard
    }

    private func normalizedKey(input: String, output: String) -> String {
        "\(input.lowercased())\u{001F}\(output)"
    }

    private func load() -> [String: Entry] {
        if let data = suite.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) {
            return decoded
        }

        // Migrate legacy payloads that stored only a single string key.
        if let legacy = suite.dictionary(forKey: key) as? [String: Int] {
            var migrated: [String: Entry] = [:]
            for (word, count) in legacy {
                let key = normalizedKey(input: word, output: word)
                migrated[key] = Entry(input: word, output: word, count: count)
            }
            save(migrated)
            return migrated
        }

        return [:]
    }

    private func save(_ entries: [String: Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        suite.set(data, forKey: key)
    }

    private func deduplicate(_ words: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for word in words where seen.insert(word).inserted {
            result.append(word)
            if result.count == limit {
                break
            }
        }

        return result
    }

    func record(input: String, output: String) {
        let cleanedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedOutput.isEmpty else { return }

        let key = normalizedKey(input: cleanedInput.isEmpty ? cleanedOutput : cleanedInput, output: cleanedOutput)
        var entries = load()
        if var entry = entries[key] {
            entry.count += 1
            entries[key] = entry
        } else {
            entries[key] = Entry(
                input: cleanedInput.isEmpty ? cleanedOutput : cleanedInput,
                output: cleanedOutput,
                count: 1
            )
        }
        save(entries)
    }

    func record(_ word: String) {
        record(input: word, output: word)
    }

    func suggestions(forInputPrefix prefix: String, limit: Int = 3) -> [String] {
        let lower = prefix.lowercased()
        guard !lower.isEmpty else { return [] }

        let matches = load().values
            .filter { $0.input.lowercased().hasPrefix(lower) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.output < rhs.output
                }
                return lhs.count > rhs.count
            }
            .map(\.output)

        return deduplicate(matches, limit: limit)
    }

    func suggestions(for prefix: String, limit: Int = 3) -> [String] {
        let lower = prefix.lowercased()
        guard !lower.isEmpty else { return [] }

        let matches = load().values
            .filter { $0.output.lowercased().hasPrefix(lower) || $0.input.lowercased().hasPrefix(lower) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.output < rhs.output
                }
                return lhs.count > rhs.count
            }
            .map(\.output)

        return deduplicate(matches, limit: limit)
    }

    func resetForTests() {
        suite.removeObject(forKey: key)
    }
}
