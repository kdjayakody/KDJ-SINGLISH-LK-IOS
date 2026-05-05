# Singlish LK

A custom iOS keyboard that converts Singlish (English phonetic) typing to Sinhala script in real-time.

## Features

- **Real-time Conversion**: Type in English letters and get Sinhala instantly
- **Custom Keyboard**: Full keyboard extension with Sinhala phonetic labels
- **Smart Suggestions**: Word suggestions that learn your typing patterns
- **Language Toggle**: Easy switching between English and Sinhala
- **Offline First**: No internet connection required
- **Privacy Focused**: All processing happens on-device

## Project Structure

```
Singlish Pro/
├── Singlish Pro/                    # Main app container
│   ├── Singlish_ProApp.swift       # App entry point
│   ├── ContentView.swift           # Main UI with converter
│   └── SettingsView.swift          # Settings interface
├── SinglishKeyboard/               # Keyboard extension
│   ├── KeyboardViewController.swift # Keyboard controller
│   ├── KeyboardView.swift          # SwiftUI keyboard UI
│   └── Info.plist                  # Extension configuration
├── Shared/                         # Shared code between targets
│   ├── SinglishEngine.swift        # Core conversion engine
│   ├── KeyboardSettings.swift      # User preferences
│   └── VersionConfig.swift         # Centralized version management
└── Singlish ProTests/              # Unit tests
```

## Version Management

Version information is centralized in `Shared/VersionConfig.swift`:

```swift
enum VersionConfig {
    static let marketingVersion = "1.0"
    static let currentProjectVersion = 1
    static let appDisplayName = "Singlish LK"
    // ... other configuration
}
```

When updating versions:
1. Update `marketingVersion` for user-facing version (e.g., "1.0" → "1.1")
2. Increment `currentProjectVersion` for each build
3. Xcode project file is updated automatically during build

## Build & Release

### Prerequisites
- Xcode 16.4+
- iOS 18.5+ deployment target
- Apple Developer account
- Valid code signing identity

### Quick Start
1. Open `Singlish Pro.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on simulator or device

### Release Build
```bash
# Run release readiness checks
./check-release.sh

# Build and archive for App Store
./build-release.sh
```

### App Store Submission
See `AppStoreMetadata.md` for detailed submission requirements and metadata.

## Configuration

### Bundle Identifiers
- Main App: `KDJ.Singlish-Pro`
- Keyboard Extension: `KDJ.Singlish-Pro.SinglishKeyboard`

### App Groups
- Group ID: `group.KDJ.Singlish-Pro`
- Used for sharing data between container and keyboard extension

### Entitlements
- Application Groups: For shared UserDefaults
- Full Access: Required for clipboard paste and enhanced features

## Testing

Run unit tests:
```bash
xcodebuild test -project "Singlish Pro.xcodeproj" \
    -scheme "Singlish Pro" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Company Information

- **Company**: KDJ Lanka (Pvt) Ltd
- **Contact**: hello@kdj.lk
- **Website**: https://singlish.lk
- **Privacy Policy**: https://singlish.lk/privacy

## License

Copyright © 2026 KDJ Lanka (Pvt) Ltd. All rights reserved.
