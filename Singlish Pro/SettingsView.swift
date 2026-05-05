import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = KeyboardSettings.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    keyboardSection
                    typingSection
                    suggestionsSection
                    appearanceSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image("KeyboardLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.top, 20)
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private func toggleRow(title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var keyboardSection: some View {
        sectionCard(title: "Keyboard", icon: "keyboard") {
            toggleRow(title: "Number Row", subtitle: "Show number keys above the keyboard", isOn: $settings.showNumberRow)
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            toggleRow(title: "Haptic Feedback", subtitle: "Vibrate on key press", isOn: $settings.hapticFeedback)
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            toggleRow(title: "Key Preview", subtitle: "Show enlarged letter while pressing", isOn: $settings.keyPreview)
        }
    }

    private var typingSection: some View {
        sectionCard(title: "Typing", icon: "text.cursor") {
            toggleRow(title: "Auto-Space After Punctuation", subtitle: "Add space after . , ? !", isOn: $settings.autoSpaceAfterPunctuation)
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            toggleRow(title: "Double-Space Period", subtitle: "Tap space twice to insert a period", isOn: $settings.doubleSpacePeriod)
        }
    }

    private var suggestionsSection: some View {
        sectionCard(title: "Suggestions", icon: "text.bubble") {
            toggleRow(title: "Word Suggestions", subtitle: "Show word predictions while typing", isOn: $settings.enableSuggestions)
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            toggleRow(title: "Learn From Typing", subtitle: "Prioritize words you use frequently", isOn: $settings.enableLearning)
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            toggleRow(title: "Clipboard Paste", subtitle: "Show paste button in suggestion bar", isOn: $settings.showClipboardPaste)
        }
    }

    private var appearanceSection: some View {
        sectionCard(title: "Appearance", icon: "paintbrush") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Accent Color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    ForEach(KeyboardAccent.allCases, id: \.self) { accent in
                        Button(action: {
                            settings.accentColor = accent
                        }) {
                            Circle()
                                .fill(accent.swiftUIColor)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: settings.accentColor == accent ? 3 : 0)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(settings.accentColor == accent ? 1 : 0)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }

    private var aboutSection: some View {
        sectionCard(title: "About", icon: "info.circle") {
            VStack(spacing: 0) {
                HStack {
                    Text("Version")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(VersionConfig.marketingVersion)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)

                HStack {
                    Text("Language")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("Sinhala (සිංහල)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

#Preview {
    SettingsView()
}
