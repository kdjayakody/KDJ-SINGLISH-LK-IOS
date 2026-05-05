import SwiftUI

enum KeyboardMode {
    case english
    case sinhala
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

struct KeyboardView: View {
    var insertText: (String) -> Void
    var deleteBackward: () -> Void
    var insertSuggestion: (String) -> Void
    var toggleShift: () -> Void
    var advanceToNextInputMode: () -> Void
    var switchMode: (KeyboardMode) -> Void
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

    var accentColor: Color {
        settings.accentColor.swiftUIColor
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Rectangle()
                .fill(Color(UIColor.systemGray4))
                .frame(height: 0.5)

            VStack(spacing: 5) {
                if settings.showNumberRow {
                    HStack(spacing: 5) {
                        ForEach(numberRow, id: \.self) { key in
                            keyButton(key, display: key, width: 32)
                        }
                    }
                }

                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 5) {
                        if rowIndex == 2 {
                            Button(action: {
                                settings.performHaptic()
                                toggleShift()
                            }) {
                                Image(systemName: isShifted ? "shift.fill" : "shift")
                                    .font(.system(size: 16))
                                    .frame(width: 44, height: 44)
                                    .background(Color(UIColor.systemGray4))
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
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
                                    .font(.system(size: 16))
                                    .frame(width: 44, height: 44)
                                    .background(Color(UIColor.systemGray4))
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                bottomRow
            }
            .padding(.horizontal, 4)
            .padding(.top, 5)
            .padding(.bottom, 10)
            .background(Color(UIColor.systemGray6))
        }
    }

    private var topBar: some View {
        HStack(spacing: 6) {
            Image("KeyboardLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack(spacing: 0) {
                Button(action: { switchMode(.english) }) {
                    Text("En")
                        .font(.system(size: 12, weight: mode == .english ? .bold : .medium))
                        .foregroundColor(mode == .english ? .white : .black)
                        .frame(width: 32, height: 24)
                        .background(mode == .english ? accentColor : Color(UIColor.systemGray5))
                        .cornerRadius(5)
                }

                Button(action: { switchMode(.sinhala) }) {
                    Text("සිං")
                        .font(.system(size: 12, weight: mode == .sinhala ? .bold : .medium))
                        .foregroundColor(mode == .sinhala ? .white : .black)
                        .frame(width: 32, height: 24)
                        .background(mode == .sinhala ? accentColor : Color(UIColor.systemGray5))
                        .cornerRadius(5)
                }
            }

            Spacer()

            if settings.showClipboardPaste && isOpenAccessGranted {
                Button(action: {
                    if let clipboard = UIPasteboard.general.string, !clipboard.isEmpty {
                        insertText(clipboard)
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                        .frame(width: 28, height: 24)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(5)
                }
            }

            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                            Button(action: {
                                insertSuggestion(suggestion)
                            }) {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white)
    }

    private func keyButton(_ key: String, display: String, width: CGFloat) -> some View {
        Button(action: {
            settings.performHaptic()
            insertText(display)
        }) {
            Text(display)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .frame(width: width, height: 36)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
        }
    }

    private func keyBody(key: String, characterToSend: String, sinhalaLabel: String?, rowIndex: Int) -> some View {
        VStack(spacing: 1) {
            if let label = sinhalaLabel, !label.isEmpty, mode == .sinhala {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            } else {
                Text("")
                    .font(.system(size: 9))
            }
            Text(isShifted && mode != .sinhala ? key.uppercased() : key)
                .font(.system(size: 20, weight: .regular, design: .rounded))
        }
        .frame(width: rowIndex == 1 ? 34 : 32, height: 44)
        .background(Color.white)
        .foregroundColor(.black)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
    }

    private func keyPopup(key: String, sinhalaLabel: String?) -> some View {
        VStack(spacing: 1) {
            if let label = sinhalaLabel, !label.isEmpty, mode == .sinhala {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.black)
            }
            Text(isShifted && mode != .sinhala ? key.uppercased() : key)
                .font(.system(size: 28, weight: .semibold))
        }
        .frame(width: 48, height: 64)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .offset(y: -48)
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
        HStack(spacing: 5) {
            Button(action: {
                settings.performHaptic()
                advanceToNextInputMode()
            }) {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }

            Button(action: {
                settings.performHaptic()
                insertText(",")
            }) {
                Text(",")
                    .font(.system(size: 22, design: .rounded))
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }

            SpaceBarView(mode: mode, onSwipe: {
                settings.performHaptic()
                switchMode(mode == .sinhala ? .english : .sinhala)
            }, onTap: { insertText(" ") })

            Button(action: {
                settings.performHaptic()
                insertText(".")
            }) {
                Text(".")
                    .font(.system(size: 22, design: .rounded))
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }

            Button(action: {
                settings.performHaptic()
                insertText("\n")
            }) {
                Text("return")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .frame(width: 74, height: 44)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 4)
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
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1
        layer.shadowOpacity = 1

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .black
        updateLabel()
        addSubview(label)

        indicatorLabel.textAlignment = .center
        indicatorLabel.font = .systemFont(ofSize: 22, weight: .bold)
        indicatorLabel.textColor = .white
        indicatorLabel.backgroundColor = .black
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
