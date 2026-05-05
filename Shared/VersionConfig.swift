import Foundation

/// Centralized version configuration for Singlish LK
/// Update these values to change the app version across all targets
enum VersionConfig {
    /// Marketing version (e.g., "1.0", "1.1", "2.0")
    static let marketingVersion = "1.0"

    /// Build version (increment with each build)
    static let currentProjectVersion = 1

    /// App display name
    static let appDisplayName = "Singlish LK"

    /// Bundle identifier
    static let bundleIdentifier = "KDJ.Singlish-Pro"

    /// Keyboard extension bundle identifier
    static let keyboardBundleIdentifier = "KDJ.Singlish-Pro.SinglishKeyboard"

    /// Copyright notice
    static let copyright = "© 2026 KDJ Lanka (Pvt) Ltd"

    /// App group identifier for data sharing
    static let appGroupIdentifier = "group.KDJ.Singlish-Pro"
}
