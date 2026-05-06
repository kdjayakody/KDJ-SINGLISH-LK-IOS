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
    private static let appGroupIdentifier = "group.KDJ.Singlish-Pro"
    private static let settingsFileName = "KeyboardSettings.plist"

    private let suite: UserDefaults
    private let settingsFileURL: URL?
    private let canWriteSettings: Bool
    private var settingsCache: [String: Any]
    private var isReloadingFromSuite = false
    
    // Darwin notification for cross-process communication
    private static let settingsChangedNotification = "com.kdj.singlish.settingsChanged" as CFString

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
        suite = UserDefaults(suiteName: Self.appGroupIdentifier) ?? .standard
        settingsFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)?
            .appendingPathComponent(Self.settingsFileName)
        canWriteSettings = !Self.isRunningInKeyboardExtension
        settingsCache = Self.loadSettings(from: settingsFileURL)

        showNumberRow = Self.boolValue(forKey: "showNumberRow", cache: settingsCache, suite: suite, defaultValue: true)
        autoSpaceAfterPunctuation = Self.boolValue(forKey: "autoSpaceAfterPunctuation", cache: settingsCache, suite: suite, defaultValue: true)
        hapticFeedback = Self.boolValue(forKey: "hapticFeedback", cache: settingsCache, suite: suite, defaultValue: true)
        keyPreview = Self.boolValue(forKey: "keyPreview", cache: settingsCache, suite: suite, defaultValue: true)
        doubleSpacePeriod = Self.boolValue(forKey: "doubleSpacePeriod", cache: settingsCache, suite: suite, defaultValue: true)
        showClipboardPaste = Self.boolValue(forKey: "showClipboardPaste", cache: settingsCache, suite: suite, defaultValue: true)
        enableSuggestions = Self.boolValue(forKey: "enableSuggestions", cache: settingsCache, suite: suite, defaultValue: true)
        enableLearning = Self.boolValue(forKey: "enableLearning", cache: settingsCache, suite: suite, defaultValue: true)
        accentColor = KeyboardAccent(rawValue: Self.stringValue(forKey: "accentColor", cache: settingsCache, suite: suite) ?? "") ?? .black

        settingsCache = currentSettingsDictionary()
        saveSettingsCache()

        hapticGenerator.prepare()
        
        // Listen for changes from other processes (Darwin notifications)
        registerForCrossProcessNotifications()
    }
    
    private func registerForCrossProcessNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let settings = Unmanaged<KeyboardSettings>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    settings.reloadFromSuite()
                }
            },
            Self.settingsChangedNotification,
            nil,
            .deliverImmediately
        )
    }

    private static func loadSettings(from url: URL?) -> [String: Any] {
        guard let url,
              let dictionary = NSDictionary(contentsOf: url) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }

    private static var isRunningInKeyboardExtension: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
    }

    private static func boolValue(forKey key: String, cache: [String: Any], suite: UserDefaults, defaultValue: Bool) -> Bool {
        if let value = cache[key] as? Bool {
            return value
        }
        return suite.object(forKey: key) as? Bool ?? defaultValue
    }

    private static func stringValue(forKey key: String, cache: [String: Any], suite: UserDefaults) -> String? {
        if let value = cache[key] as? String {
            return value
        }
        return suite.string(forKey: key)
    }

    private func currentSettingsDictionary() -> [String: Any] {
        [
            "showNumberRow": showNumberRow,
            "autoSpaceAfterPunctuation": autoSpaceAfterPunctuation,
            "hapticFeedback": hapticFeedback,
            "keyPreview": keyPreview,
            "doubleSpacePeriod": doubleSpacePeriod,
            "showClipboardPaste": showClipboardPaste,
            "accentColor": accentColor.rawValue,
            "enableSuggestions": enableSuggestions,
            "enableLearning": enableLearning
        ]
    }

    private func saveSettingsCache() {
        guard canWriteSettings, let settingsFileURL else { return }
        try? FileManager.default.createDirectory(
            at: settingsFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        NSDictionary(dictionary: settingsCache).write(to: settingsFileURL, atomically: true)
    }
    
    private func postSettingsChangedNotification() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(Self.settingsChangedNotification),
            nil,
            nil,
            true
        )
    }

    private func persist(_ value: Any, forKey key: String) {
        guard !isReloadingFromSuite, canWriteSettings else { return }
        settingsCache[key] = value
        saveSettingsCache()
        suite.set(value, forKey: key)
        suite.synchronize()
        // Notify other processes (keyboard extension)
        postSettingsChangedNotification()
    }

    private func reloadFromSuite() {
        isReloadingFromSuite = true
        settingsCache = Self.loadSettings(from: settingsFileURL)
        showNumberRow = Self.boolValue(forKey: "showNumberRow", cache: settingsCache, suite: suite, defaultValue: true)
        autoSpaceAfterPunctuation = Self.boolValue(forKey: "autoSpaceAfterPunctuation", cache: settingsCache, suite: suite, defaultValue: true)
        hapticFeedback = Self.boolValue(forKey: "hapticFeedback", cache: settingsCache, suite: suite, defaultValue: true)
        keyPreview = Self.boolValue(forKey: "keyPreview", cache: settingsCache, suite: suite, defaultValue: true)
        doubleSpacePeriod = Self.boolValue(forKey: "doubleSpacePeriod", cache: settingsCache, suite: suite, defaultValue: true)
        showClipboardPaste = Self.boolValue(forKey: "showClipboardPaste", cache: settingsCache, suite: suite, defaultValue: true)
        enableSuggestions = Self.boolValue(forKey: "enableSuggestions", cache: settingsCache, suite: suite, defaultValue: true)
        enableLearning = Self.boolValue(forKey: "enableLearning", cache: settingsCache, suite: suite, defaultValue: true)
        accentColor = KeyboardAccent(rawValue: Self.stringValue(forKey: "accentColor", cache: settingsCache, suite: suite) ?? "") ?? .black
        settingsCache = currentSettingsDictionary()
        saveSettingsCache()
        isReloadingFromSuite = false
    }

    func refreshFromSharedStore() {
        reloadFromSuite()
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
