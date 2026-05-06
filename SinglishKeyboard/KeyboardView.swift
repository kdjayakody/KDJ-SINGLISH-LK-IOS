import SwiftUI

enum KeyboardMode {
    case english
    case sinhala
    case emoji
}

let sinhalaKeyMap: [String: String] = [
    "q": "ඣ", "w": "ව", "e": "එ", "r": "ර", "t": "ට", "y": "ය", "u": "උ", "i": "ඉ", "o": "ඔ", "p": "ප",
    "a": "අ", "s": "ස", "d": "ඩ", "f": "ෆ", "g": "ග", "h": "හ", "j": "ජ", "k": "ක", "l": "ල",
    "z": "ං", "x": "ං", "c": "ච", "v": "ව", "b": "බ", "n": "න", "m": "ම"
]

let longPressMap: [String: [String]] = [
    "a": ["ආ", "ඇ", "ඈ", "@", "a"],
    "e": ["ඒ", "ඓ", "එ", "e"],
    "i": ["ඊ", "ී", "i"],
    "o": ["ඕ", "ෝ", "o"],
    "u": ["ඌ", "ූ", "u"],
    "k": ["ඛ", "ක", "k"],
    "g": ["ඝ", "ග", "g"],
    "c": ["ඡ", "ඡ", "c"],
    "t": ["ඨ", "ත", "t"],
    "d": ["ඪ", "ධ", "ද", "d"],
    "n": ["ණ", "න", "n"],
    "l": ["ළ", "ල", "l"],
    "s": ["ශ", "ෂ", "ස", "s"],
    "h": ["හ", "h"],
    "r": ["ඍ", "ර", "r"],
    "p": ["ඵ", "ප", "p"],
    "b": ["භ", "බ", "b"],
    "m": ["ම", "m"],
    "y": ["ය", "y"],
    "w": ["ව", "w"],
    "f": ["ෆ", "f"],
    "v": ["ව", "v"]
]

// Emoji keyboard data
let emojiCategories: [(icon: String, emoji: [String])] = [
    ("😀", ["😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","😉","😊","😇","🥰","😍","🤩","😘","😗","😚","😙","🥲","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔","🤐","🤨","😐","😑","😶","😏","😒","🙄","😬","🤥"]),
    ("👋", ["👋","🤚","🖐️","✋","🖖","🫱","🫲","🤝","🙏","✌️","🤞","🤟","🤘","🤙","👈","👉","👆","🖕","👇","☝️","👍","👎","✊","👊","🤛","🤜","👏","🙌","👐","🤲","🙏"]),
    ("❤️", ["❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟","♥️"]),
    ("🎉", ["🎉","🎊","🎈","🎁","🎀","🏆","🥇","🥈","🥉","🏅","🎖️","🎗️","🎫","🎟️","🧧","✉️","📩","📨","📧","💌","📥","📤","📦","🏷️","📪","📫","📬","📭","📮"]),
    ("😂", ["😂","😭","😢","🥲","😤","😠","😡","🤬","😤","😈","👿","💀","☠️","💩","🤡","👹","👺","👻","👽","👾","🤖"]),
    ("🌏", ["🇱🇰","🇺🇸","🇬🇧","🇮🇳","🇯🇵","🇨🇳","🇰🇷","🇦🇪","🇸🇦","🇫🇷","🇩🇪","🇮🇹","🇪🇸","🇵🇹","🇷🇺","🇧🇷","🇮🇩","🇹🇭","🇲🇾","🇸🇬"]),
]

struct KeyboardView: View {
    var insertText: (String) -> Void
    var deleteBackward: () -> Void
    var insertSuggestion: (String) -> Void
    var toggleShift: () -> Void
    var advanceToNextInputMode: () -> Void
    var switchMode: (KeyboardMode) -> Void
    var openApp: () -> Void
    var openSettings: () -> Void
    var isOpenAccessGranted: Bool
    var suggestions: [String]
    var isShifted: Bool
    var mode: KeyboardMode

    @ObservedObject var settings = KeyboardSettings.shared

    let numberRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    let rows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    @State private var pressedKey: String? = nil
    @State private var keyTouchStart: Date? = nil
    @State private var selectedEmojiCategory: Int = 0

    var accentColor: Color {
        settings.accentColor.swiftUIColor
    }

    private let keyboardBackground = Color(red: 0.18, green: 0.22, blue: 0.25)
    private let barBackground = Color(red: 0.14, green: 0.17, blue: 0.20)
    private let barSegment = Color(red: 0.19, green: 0.23, blue: 0.27)
    private let keyColor = Color(red: 0.34, green: 0.37, blue: 0.41)
    private let utilityKeyColor = Color(red: 0.23, green: 0.27, blue: 0.31)
    private let primaryLabel = Color.white.opacity(0.96)
    private let secondaryLabel = Color.white.opacity(0.72)
    private let tertiaryLabel = Color.white.opacity(0.56)

    var body: some View {
        VStack(spacing: 0) {
            topBar

            if mode == .emoji {
                emojiKeyboard
            } else {
                regularKeyboard
            }
        }
        .background(keyboardBackground)
    }

    private var regularKeyboard: some View {
        VStack(spacing: 8) {
            if settings.showNumberRow {
                HStack(spacing: 6) {
                    ForEach(numberRow, id: \.self) { key in
                        keyButton(key, display: key, width: 34, height: 44, background: keyColor)
                    }
                }
            }

            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    if rowIndex == 2 {
                        Button(action: {
                            settings.performHaptic()
                            toggleShift()
                        }) {
                            Image(systemName: isShifted ? "shift.fill" : "shift")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 47, height: 46)
                                .keyboardKeyStyle(background: utilityKeyColor, foreground: primaryLabel)
                        }
                    }

                    ForEach(rows[rowIndex], id: \.self) { key in
                        let characterToSend = mode == .sinhala ? key : (isShifted ? key.uppercased() : key)
                        let sinhalaLabel = mode == .sinhala ? sinhalaKeyMap[key] : nil
                        ZStack {
                            keyBody(key: key, characterToSend: characterToSend, sinhalaLabel: sinhalaLabel, rowIndex: rowIndex)

                            if settings.keyPreview && pressedKey == key {
                                keyPopup(key: key, sinhalaLabel: sinhalaLabel)
                            }
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if pressedKey != key {
                                        pressedKey = key
                                        keyTouchStart = Date()
                                    }
                                }
                                .onEnded { _ in
                                    let duration = Date().timeIntervalSince(keyTouchStart ?? Date())
                                    settings.performHaptic()

                                    if duration >= 0.4 {
                                        handleLongPress(key: key)
                                    } else {
                                        insertText(characterToSend)
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        pressedKey = nil
                                    }
                                    keyTouchStart = nil
                                }
                        )
                    }

                    if rowIndex == 2 {
                        Button(action: {
                            settings.performHaptic()
                            deleteBackward()
                        }) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 47, height: 46)
                                .keyboardKeyStyle(background: utilityKeyColor, foreground: primaryLabel)
                        }
                    }
                }
                .padding(.leading, rowIndex == 1 ? 19 : 0)
            }

            bottomRow
        }
        .padding(.horizontal, 6)
        .padding(.top, 7)
        .padding(.bottom, 9)
        .background(keyboardBackground)
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            topBarSegment(width: 48) {
                Button(action: openApp) {
                    Image("KeyboardLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26, height: 26)
                }
            }

            topBarModeButton(title: "En", isActive: mode == .english) {
                switchMode(.english)
            }

            topBarModeButton(title: "සිං", isActive: mode == .sinhala) {
                switchMode(.sinhala)
            }

            topBarIconButton(icon: "😀", isActive: mode == .emoji) {
                switchMode(.emoji)
            }

            Spacer(minLength: 0)

            if settings.showClipboardPaste && isOpenAccessGranted {
                topBarIconButton(systemName: "doc.on.clipboard") {
                    if let clipboard = UIPasteboard.general.string, !clipboard.isEmpty {
                        insertText(clipboard)
                    }
                }
            }

            topBarIconButton(systemName: "gearshape.fill", action: openSettings)
        }
        .padding(.horizontal, 0)
        .frame(height: 58)
        .background(barBackground)
    }

    private func keyButton(_ key: String, display: String, width: CGFloat, height: CGFloat, background: Color) -> some View {
        Button(action: {
            settings.performHaptic()
            insertText(display)
        }) {
            Text(display)
                .font(.system(size: 17, weight: .regular))
                .frame(width: width, height: height)
                .keyboardKeyStyle(background: background, foreground: primaryLabel)
        }
    }

    private func keyBody(key: String, characterToSend: String, sinhalaLabel: String?, rowIndex: Int) -> some View {
        ZStack {
            if let label = sinhalaLabel, !label.isEmpty, mode == .sinhala {
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(tertiaryLabel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 5)
                    .padding(.trailing, 6)
            }

            Text(isShifted && mode != .sinhala ? key.uppercased() : key)
                .font(.system(size: 21, weight: .regular))
                .foregroundColor(primaryLabel)
                .offset(y: 3)
        }
        .frame(width: rowIndex == 1 ? 38 : 35, height: 46)
        .keyboardKeyStyle(background: keyColor, foreground: primaryLabel)
    }

    private func keyPopup(key: String, sinhalaLabel: String?) -> some View {
        VStack(spacing: 1) {
            if let label = sinhalaLabel, !label.isEmpty, mode == .sinhala {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(secondaryLabel)
            }
            Text(isShifted && mode != .sinhala ? key.uppercased() : key)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(primaryLabel)
        }
        .frame(width: 46, height: 60)
        .background(keyColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
        .offset(y: -44)
        .zIndex(10)
    }

    private func handleLongPress(key: String) {
        guard mode == .sinhala, let alternatives = longPressMap[key], !alternatives.isEmpty else {
            return
        }
        // Insert the first alternative (long press character)
        let alternative = alternatives[0]
        if !alternative.isEmpty {
            insertText(alternative)
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 6) {
            Button(action: {
                settings.performHaptic()
            }) {
                Text("123")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 52, height: 46)
                    .keyboardKeyStyle(background: utilityKeyColor, foreground: primaryLabel)
            }

            Button(action: {
                settings.performHaptic()
                advanceToNextInputMode()
            }) {
                Image(systemName: "globe")
                    .font(.system(size: 22, weight: .regular))
                    .frame(width: 52, height: 46)
                    .keyboardKeyStyle(background: utilityKeyColor, foreground: primaryLabel)
            }

            Button(action: {
                settings.performHaptic()
                insertText(".")
            }) {
                Text(".")
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 47, height: 46)
                    .keyboardKeyStyle(background: keyColor, foreground: primaryLabel)
            }

            SpaceBarView(mode: mode, onSwipe: {
                settings.performHaptic()
                switchMode(mode == .sinhala ? .english : .sinhala)
            }, onTap: { insertText(" ") })

            Button(action: {
                settings.performHaptic()
                insertText("\n")
            }) {
                Text("return")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 108, height: 46)
                    .keyboardKeyStyle(background: accentColor, foreground: primaryLabel)
            }
        }
    }

    private func topBarSegment<Content: View>(width: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            content()
        }
        .frame(width: width, height: 58)
        .background(barSegment)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.035))
                .frame(width: 1)
        }
    }

    private func topBarModeButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isActive ? .semibold : .medium))
                .foregroundColor(primaryLabel)
                .frame(width: 52, height: 58)
                .background(isActive ? accentColor : barBackground)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.035))
                .frame(width: 1)
        }
    }

    private func topBarIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(secondaryLabel)
                .frame(width: 44, height: 58)
        }
    }

    private func topBarIconButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(icon)
                .font(.system(size: 22))
                .frame(width: 44, height: 58)
                .background(isActive ? accentColor : barBackground)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.035))
                .frame(width: 1)
        }
    }

    private var emojiKeyboard: some View {
        VStack(spacing: 8) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<emojiCategories.count, id: \.self) { index in
                        Button(action: {
                            settings.performHaptic()
                            selectedEmojiCategory = index
                        }) {
                            Text(emojiCategories[index].icon)
                                .font(.system(size: 22))
                                .frame(width: 44, height: 38)
                                .background(selectedEmojiCategory == index ? barSegment : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 44)

            // Emoji grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(emojiCategories[selectedEmojiCategory].emoji, id: \.self) { emoji in
                        Button(action: {
                            settings.performHaptic()
                            insertText(emoji)
                        }) {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            // Bottom bar
            HStack(spacing: 6) {
                Button(action: {
                    settings.performHaptic()
                    advanceToNextInputMode()
                }) {
                    Image(systemName: "globe")
                        .font(.system(size: 22, weight: .regular))
                        .frame(width: 52, height: 46)
                        .keyboardKeyStyle(background: utilityKeyColor, foreground: primaryLabel)
                }

                Button(action: {
                    settings.performHaptic()
                    switchMode(.sinhala)
                }) {
                    Text("abc")
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 80, height: 46)
                        .keyboardKeyStyle(background: utilityKeyColor, foreground: primaryLabel)
                }

                Spacer()

                Button(action: {
                    settings.performHaptic()
                    deleteBackward()
                }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 52, height: 46)
                        .keyboardKeyStyle(background: utilityKeyColor, foreground: primaryLabel)
                }
            }
            .padding(.horizontal, 6)
        }
        .padding(.top, 7)
        .padding(.bottom, 9)
    }
}

private extension View {
    func keyboardKeyStyle(background: Color, foreground: Color) -> some View {
        self
            .background(background)
            .foregroundColor(foreground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
            )
    }
}

struct SpaceBarView: UIViewRepresentable {
    let mode: KeyboardMode
    let onSwipe: () -> Void
    let onTap: () -> Void

    func makeUIView(context: Context) -> SpaceBarUIView {
        let view = SpaceBarUIView(mode: mode, onSwipe: onSwipe, onTap: onTap)
        return view
    }

    func updateUIView(_ uiView: SpaceBarUIView, context: Context) {
        uiView.mode = mode
        uiView.onSwipe = onSwipe
        uiView.onTap = onTap
        uiView.updateLabel()
    }
}

class SpaceBarUIView: UIView {
    var mode: KeyboardMode
    var onSwipe: () -> Void
    var onTap: () -> Void

    private let label = UILabel()
    private let indicatorLabel = UILabel()
    private var hasSwiped = false

    init(mode: KeyboardMode, onSwipe: @escaping () -> Void, onTap: @escaping () -> Void) {
        self.mode = mode
        self.onSwipe = onSwipe
        self.onTap = onTap
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        self.mode = .sinhala
        self.onSwipe = {}
        self.onTap = {}
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor(red: 0.34, green: 0.37, blue: 0.41, alpha: 1)
        layer.cornerRadius = 8
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.96)
        updateLabel()
        addSubview(label)

        indicatorLabel.textAlignment = .center
        indicatorLabel.font = .systemFont(ofSize: 22, weight: .bold)
        indicatorLabel.textColor = .white
        indicatorLabel.backgroundColor = UIColor(red: 0.20, green: 0.24, blue: 0.28, alpha: 1)
        indicatorLabel.layer.cornerRadius = 10
        indicatorLabel.clipsToBounds = true
        indicatorLabel.alpha = 0
        indicatorLabel.isHidden = true
        addSubview(indicatorLabel)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)

        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        tapGesture.require(toFail: swipeGesture)
        addGestureRecognizer(swipeGesture)
    }

    func updateLabel() {
        label.text = mode == .sinhala ? "සිංහල" : "English"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
        indicatorLabel.sizeToFit()
        indicatorLabel.frame.size = CGSize(width: indicatorLabel.frame.width + 24, height: indicatorLabel.frame.height + 12)
        indicatorLabel.center = CGPoint(x: bounds.midX, y: -30)
    }

    @objc private func handleTap() { onTap() }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        switch gesture.state {
        case .began:
            hasSwiped = false
        case .changed:
            if abs(translation.x) > 30 && !hasSwiped {
                hasSwiped = true
                showIndicator(swipeRight: translation.x > 0)
                onSwipe()
            }
        case .ended, .cancelled:
            hideIndicator()
        default: break
        }
    }

    private func showIndicator(swipeRight: Bool) {
        let targetText = swipeRight ? "සිං" : "En"
        indicatorLabel.text = targetText
        indicatorLabel.isHidden = false
        indicatorLabel.sizeToFit()
        indicatorLabel.frame.size = CGSize(width: indicatorLabel.frame.width + 24, height: indicatorLabel.frame.height + 12)
        indicatorLabel.center = CGPoint(x: bounds.midX, y: -30)
        UIView.animate(withDuration: 0.15) { self.indicatorLabel.alpha = 1 }
    }

    private func hideIndicator() {
        UIView.animate(withDuration: 0.15, animations: { self.indicatorLabel.alpha = 0 }) { _ in self.indicatorLabel.isHidden = true }
    }
}
