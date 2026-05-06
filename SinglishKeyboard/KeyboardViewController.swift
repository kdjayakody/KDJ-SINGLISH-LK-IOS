import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?
    private let appSettingsURL = URL(string: "singlishlk://settings")!
    private let keyboardSettingsURL = URL(string: "prefs:root=General&path=Keyboard")!
    private let engine = SinglishEngine()
    private let settings = KeyboardSettings.shared
    private var isShifted = false
    private var currentMode: KeyboardMode = .sinhala
    private var previousDeleteCount: Int = 0
    private var lastSpaceTime: Date = .distantPast
    private var isOpenAccessGranted = false
    private var toastView: KeyboardToastView?

    override func viewDidLoad() {
        super.viewDidLoad()
        isOpenAccessGranted = self.hasFullAccess
        settings.refreshFromSharedStore()
        setupKeyboard()
        updateSuggestions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isOpenAccessGranted = self.hasFullAccess
        settings.refreshFromSharedStore()
        updateSuggestions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        commitCurrent()
    }

    private func setupKeyboard() {
        let keyboardView = makeKeyboardView()
        let host = UIHostingController(rootView: keyboardView)
        view.backgroundColor = UIColor(red: 0.18, green: 0.22, blue: 0.25, alpha: 1)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = UIColor(red: 0.18, green: 0.22, blue: 0.25, alpha: 1)

        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        hostingController = host
    }

    private func makeKeyboardView() -> KeyboardView {
        KeyboardView(
            insertText: { [weak self] text in
                self?.handleKeyPress(text)
            },
            deleteBackward: { [weak self] in
                self?.handleDelete()
            },
            insertSuggestion: { [weak self] suggestion in
                self?.handleSuggestion(suggestion)
            },
            toggleShift: { [weak self] in
                self?.toggleShiftAndUpdate()
            },
            advanceToNextInputMode: { [weak self] in
                self?.advanceToNextInputMode()
            },
            switchMode: { [weak self] mode in
                self?.switchToMode(mode)
            },
            openApp: { [weak self] in
                self?.openContainerApp()
            },
            openSettings: { [weak self] in
                self?.openAppSettings()
            },
            isOpenAccessGranted: isOpenAccessGranted,
            suggestions: [],
            isShifted: isShifted,
            mode: currentMode
        )
    }

    private func switchToMode(_ mode: KeyboardMode) {
        commitCurrent()
        currentMode = mode
        updateSuggestions()
    }

    private func toggleShiftAndUpdate() {
        isShifted.toggle()
        updateSuggestions()
    }

    private func handleKeyPress(_ text: String) {
        guard !text.isEmpty else { return }

        if currentMode == .english {
            handleEnglishKeyPress(text)
            return
        }

        if shouldInsertDirectly(text) {
            commitCurrent()
            textDocumentProxy.insertText(text)
            if settings.enableLearning {
                LearnedWords.shared.record(input: text, output: text)
            }
            updateSuggestions()
            return
        }

        if text == "\n" {
            commitCurrent()
            textDocumentProxy.insertText("\n")
            updateSuggestions()
            return
        }

        if text == " " {
            let now = Date()
            if settings.doubleSpacePeriod && now.timeIntervalSince(lastSpaceTime) < 0.5 {
                let context = textDocumentProxy.documentContextBeforeInput ?? ""
                if context.hasSuffix(" ") {
                    textDocumentProxy.deleteBackward()
                    commitCurrent()
                    textDocumentProxy.insertText(". ")
                    lastSpaceTime = .distantPast
                    updateSuggestions()
                    return
                }
            }
            lastSpaceTime = now
            commitCurrent()
            textDocumentProxy.insertText(" ")
            updateSuggestions()
            return
        }

        if text == "." || text == "," || text == "?" || text == "!" {
            commitCurrent()
            textDocumentProxy.insertText(text)
            if settings.autoSpaceAfterPunctuation {
                textDocumentProxy.insertText(" ")
            }
            updateSuggestions()
            return
        }

        if text.count > 1 {
            for char in text.lowercased() {
                engine.append(char)
            }
        } else if let char = text.lowercased().first {
            engine.append(char)
        }

        if isShifted {
            isShifted = false
        }

        let sinhala = engine.displayText
        replaceCurrentSinhala(with: sinhala)
        updateSuggestions()
    }

    private func handleEnglishKeyPress(_ text: String) {
        if settings.doubleSpacePeriod && text == " " {
            let now = Date()
            if now.timeIntervalSince(lastSpaceTime) < 0.5 {
                let context = textDocumentProxy.documentContextBeforeInput ?? ""
                if context.hasSuffix(" ") {
                    textDocumentProxy.deleteBackward()
                    textDocumentProxy.insertText(". ")
                    lastSpaceTime = .distantPast
                    updateSuggestions()
                    return
                }
            }
            lastSpaceTime = Date()
        }

        if settings.autoSpaceAfterPunctuation && (text == "." || text == "," || text == "?" || text == "!") {
            textDocumentProxy.insertText(text)
            textDocumentProxy.insertText(" ")
            if isShifted { isShifted = false }
            updateSuggestions()
            return
        }

        if isShifted { isShifted = false }
        textDocumentProxy.insertText(text)
        updateSuggestions()
    }

    private func handleDelete() {
        if currentMode == .english {
            textDocumentProxy.deleteBackward()
            updateSuggestions()
            return
        }

        // In Sinhala mode, delete behavior depends on state:
        // 1. If typing in progress (engine buffer not empty): delete from buffer
        // 2. If buffer empty but we just committed text: delete the committed Sinhala
        // 3. Otherwise: normal delete
        if !engine.englishBuffer.isEmpty {
            engine.deleteBackward()
            let sinhala = engine.displayText
            replaceCurrentSinhala(with: sinhala)
        } else if previousDeleteCount > 0 {
            deleteBackwardByCount(previousDeleteCount)
            previousDeleteCount = 0
        } else {
            textDocumentProxy.deleteBackward()
        }
        updateSuggestions()
    }

    private func handleSuggestion(_ suggestion: String) {
        let inputPrefix = engine.englishBuffer
        if previousDeleteCount > 0 {
            deleteBackwardByCount(previousDeleteCount)
            previousDeleteCount = 0
        }

        let textToInsert = suggestion
        textDocumentProxy.insertText(textToInsert)

        if settings.enableLearning {
            LearnedWords.shared.record(input: inputPrefix, output: textToInsert)
        }

        engine.reset()
        updateSuggestions()
    }

    private func commitCurrent() {
        guard !engine.englishBuffer.isEmpty else { return }

        if settings.enableLearning {
            let output = engine.displayText
            if !output.isEmpty {
                LearnedWords.shared.record(input: engine.englishBuffer, output: output)
            }
        }

        previousDeleteCount = 0
        engine.reset()
    }

    private func replaceCurrentSinhala(with sinhala: String) {
        if previousDeleteCount > 0 {
            deleteBackwardByCount(previousDeleteCount)
        }

        if !sinhala.isEmpty {
            textDocumentProxy.insertText(sinhala)
        }

        previousDeleteCount = deletionCount(for: sinhala)
    }

    private func deletionCount(for text: String) -> Int {
        SinhalaComposition.deletionCount(for: text)
    }

    private func deleteBackwardByCount(_ count: Int) {
        for _ in 0..<count {
            textDocumentProxy.deleteBackward()
        }
    }

    private func shouldInsertDirectly(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0D80...0x0DFF).contains(scalar.value)
        }
    }

    private func updateSuggestions() {
        var suggestedWords: [String] = []

        if settings.enableSuggestions {
            if currentMode == .sinhala {
                suggestedWords = engine.suggestions

                if settings.enableLearning {
                    let learned = LearnedWords.shared.suggestions(forInputPrefix: engine.englishBuffer, limit: 3)
                    for word in learned {
                        if !word.isEmpty && !suggestedWords.contains(word) {
                            suggestedWords.append(word)
                        }
                    }
                }
            } else if settings.enableLearning {
                // English mode suggestions
                let context = textDocumentProxy.documentContextBeforeInput ?? ""
                if let lastWord = context.components(separatedBy: .whitespacesAndNewlines).last {
                    let learned = LearnedWords.shared.suggestions(for: lastWord, limit: 3)
                    suggestedWords = learned
                }
            }

            if suggestedWords.count > 3 {
                suggestedWords = Array(suggestedWords.prefix(3))
            }
        }

        let currentIsShifted = isShifted
        let currentModeSnapshot = currentMode
        hostingController?.rootView = KeyboardView(
            insertText: { [weak self] text in
                self?.handleKeyPress(text)
            },
            deleteBackward: { [weak self] in
                self?.handleDelete()
            },
            insertSuggestion: { [weak self] suggestion in
                self?.handleSuggestion(suggestion)
            },
            toggleShift: { [weak self] in
                self?.toggleShiftAndUpdate()
            },
            advanceToNextInputMode: { [weak self] in
                self?.advanceToNextInputMode()
            },
            switchMode: { [weak self] mode in
                self?.switchToMode(mode)
            },
            openApp: { [weak self] in
                self?.openContainerApp()
            },
            openSettings: { [weak self] in
                self?.openAppSettings()
            },
            isOpenAccessGranted: isOpenAccessGranted,
            suggestions: suggestedWords,
            isShifted: currentIsShifted,
            mode: currentModeSnapshot
        )
    }

    private func openAppSettings() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        extensionContext?.open(keyboardSettingsURL) { [weak self] success in
            guard success else {
                DispatchQueue.main.async {
                    self?.showToast(message: "Open Settings → General → Keyboard")
                }
                return
            }
        }
    }

    private func openContainerApp() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        extensionContext?.open(appSettingsURL) { [weak self] success in
            guard let self else { return }
            if success {
                return
            }

            self.extensionContext?.open(self.keyboardSettingsURL) { settingsSuccess in
                guard !settingsSuccess else { return }
                DispatchQueue.main.async {
                    self.showToast(message: "Open Singlish LK app from Home Screen")
                }
            }
        }
    }
    
    private func showToast(message: String) {
        toastView?.removeFromSuperview()
        
        let toast = KeyboardToastView(message: message)
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.topAnchor, constant: -10)
        ])
        
        toastView = toast
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
            toast.transform = .identity
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 0
                toast.transform = CGAffineTransform(translationX: 0, y: 20)
            }) { _ in
                toast.removeFromSuperview()
                if self.toastView === toast {
                    self.toastView = nil
                }
            }
        }
    }
}

// MARK: - Toast View for Keyboard Extension
class KeyboardToastView: UIView {
    private let messageLabel = UILabel()
    
    init(message: String) {
        super.init(frame: .zero)
        setup(message: message)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setup(message: String) {
        backgroundColor = UIColor(white: 0.1, alpha: 0.95)
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 5
        
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        messageLabel.textAlignment = .center
        addSubview(messageLabel)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}
