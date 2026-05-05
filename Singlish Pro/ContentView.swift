import SwiftUI
import UIKit
import StoreKit

struct SinglishTextField: UIViewRepresentable {
    @Binding var text: String
    var onTextChange: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = "e.g. oya kohomada?"
        tf.font = UIFont.systemFont(ofSize: 18)
        tf.textColor = .white
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.spellCheckingType = .no
        tf.smartQuotesType = .no
        tf.smartDashesType = .no
        tf.smartInsertDeleteType = .no
        tf.keyboardType = .asciiCapable
        tf.returnKeyType = .done
        tf.tintColor = .white
        tf.attributedPlaceholder = NSAttributedString(
            string: "e.g. oya kohomada?",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.35)]
        )
        tf.setContentHuggingPriority(.defaultLow, for: .vertical)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        tf.delegate = context.coordinator
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            let selectedRange = uiView.selectedTextRange
            uiView.text = text
            uiView.selectedTextRange = selectedRange
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SinglishTextField

        init(_ parent: SinglishTextField) {
            self.parent = parent
        }

        @objc func textChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
            parent.onTextChange(tf.text ?? "")
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

struct SetupStep: Identifiable {
    let id: Int
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
}

class RecentStore: ObservableObject {
    static let shared = RecentStore()
    @Published var phrases: [String] = []
    private let maxPhrases = 12
    private let suite = UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard
    private let key = "recentPhrases"

    init() {
        phrases = suite.stringArray(forKey: key) ?? []
    }

    func add(_ sinhala: String) {
        guard !sinhala.isEmpty else { return }
        phrases.removeAll { $0 == sinhala }
        phrases.insert(sinhala, at: 0)
        if phrases.count > maxPhrases { phrases = Array(phrases.prefix(maxPhrases)) }
        suite.set(phrases, forKey: key)
    }
}

class UseCounter: ObservableObject {
    static let shared = UseCounter()
    @Published var count: Int = 0
    @Published var hasRated: Bool = false
    private let suite = UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard

    init() {
        count = suite.integer(forKey: "useCount")
        hasRated = suite.bool(forKey: "hasRated")
    }

    func increment() {
        count += 1
        suite.set(count, forKey: "useCount")
    }

    func markRated() {
        hasRated = true
        suite.set(true, forKey: "hasRated")
    }
}

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var showSetup = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showOnboarding = false
    @ObservedObject private var recentStore = RecentStore.shared
    @ObservedObject private var useCounter = UseCounter.shared
    @State private var showRatePrompt = false

    private let engine = SinglishEngine()

    var sinhalaOutput: String {
        engine.convertToSinhala(inputText)
    }

    private let steps: [SetupStep] = [
        SetupStep(id: 1, number: 1, title: "Open Settings", subtitle: "Go to Settings → General → Keyboard", icon: "gear"),
        SetupStep(id: 2, number: 2, title: "Add New Keyboard", subtitle: "Tap Keyboards → Add New Keyboard", icon: "keyboard"),
        SetupStep(id: 3, number: 3, title: "Select Singlish LK", subtitle: "Find and tap Singlish LK from the list", icon: "checkmark.circle"),
        SetupStep(id: 4, number: 4, title: "Allow Full Access", subtitle: "Tap Singlish LK → enable Full Access", icon: "lock.open"),
        SetupStep(id: 5, number: 5, title: "Switch Once, Stays Forever", subtitle: "Tap the globe 🌐 icon to switch — iOS remembers it for all apps", icon: "arrow.triangle.swap"),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    converterCard
                    actionButtons
                    recentSection
                    setupButton
                    if showSetup {
                        setupSteps
                    }
                    Spacer(minLength: 40)
                    footer
                }
            }

            if showToast {
                toastView
            }

            if showRatePrompt {
                ratePromptView
            }
        }
        .onAppear {
            let hasSeenOnboarding = (UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard).bool(forKey: "hasSeenOnboarding")
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(dismiss: {
                showOnboarding = false
                (UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard).set(true, forKey: "hasSeenOnboarding")
            })
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image("KeyboardLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Singlish LK")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    private var converterCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Type English letters — Sinhala appears below")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 4)

                SinglishTextField(
                    text: $inputText,
                    onTextChange: { _ in }
                )
                .padding(16)
                .background(Color.white.opacity(0.08))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .frame(height: 52)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Sinhala output")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 4)
                    Spacer()
                    if !sinhalaOutput.isEmpty {
                        Button(action: copyToClipboard) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                Text("Copy")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.trailing, 4)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.06))

                    Text(sinhalaOutput.isEmpty ? "ඔබගේ සිංහල පෙළ මෙහි දිස්වේ" : sinhalaOutput)
                        .font(.title2)
                        .foregroundColor(sinhalaOutput.isEmpty ? .white.opacity(0.3) : .white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .frame(minHeight: 56)
                .onTapGesture {
                    if !sinhalaOutput.isEmpty {
                        copyToClipboard()
                    }
                }
            }

            if !inputText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.caption)
                    Text(inputText)
                        .font(.caption)
                        .lineLimit(1)
                    Text("›")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    Text(sinhalaOutput)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .cornerRadius(20)
            }

            if !inputText.isEmpty {
                Button(action: { inputText = "" }) {
                    Text("Clear")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if !sinhalaOutput.isEmpty {
                Button(action: copyToClipboard) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
                }

                Button(action: shareToWhatsApp) {
                    HStack(spacing: 6) {
                        Image(systemName: "message.fill")
                        Text("WhatsApp")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.18, green: 0.78, blue: 0.44))
                    .cornerRadius(10)
                }

                Button(action: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.top, 12)
    }

    private var recentSection: some View {
        Group {
            if !recentStore.phrases.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Button(action: {
                            recentStore.phrases = []
                            (UserDefaults(suiteName: "group.KDJ.Singlish-Pro") ?? .standard).removeObject(forKey: "recentPhrases")
                        }) {
                            Text("Clear")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(recentStore.phrases.enumerated()), id: \.offset) { _, phrase in
                                Button(action: {
                                    UIPasteboard.general.string = phrase
                                    toastMessage = "Copied!"
                                    showToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showToast = false }
                                }) {
                                    Text(phrase)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.top, 16)
                .padding(.horizontal, 20)
            }
        }
    }

    private var setupButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Open Settings")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
            }

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSetup.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16, weight: .semibold))
                    Text(showSetup ? "Hide Setup Guide" : "Show Setup Guide")
                        .font(.system(size: 14))
                    Image(systemName: showSetup ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.top, 16)
    }

    private var setupSteps: some View {
        VStack(spacing: 12) {
            ForEach(steps) { step in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                        Text("\(step.number)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(step.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: step.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }

            Text("Once you switch to Singlish LK, it stays — the keyboard will appear automatically in all apps.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 8)
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        Text("Singlish LK — Real-time Singlish to Sinhala")
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white.opacity(0.3))
            .padding(.bottom, 30)
    }

    private var toastView: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                Text(toastMessage)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
    }

    private var ratePromptView: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("KeyboardLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("Enjoying Singlish LK?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("A quick rating helps others discover this keyboard!")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button(action: {
                        useCounter.markRated()
                        showRatePrompt = false
                        if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                           let _ = windowScene.windows.first {
                            AppStore.requestReview(in: windowScene)
                        }
                    }) {
                        Text("⭐ Rate Now")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                    }

                    Button(action: { useCounter.markRated(); showRatePrompt = false }) {
                        Text("Maybe Later")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
            )
            .padding(.horizontal, 40)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = sinhalaOutput
        recentStore.add(sinhalaOutput)
        useCounter.increment()

        toastMessage = "Copied!"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showToast = false }
        }

        if useCounter.count >= 5 && !useCounter.hasRated {
            showRatePrompt = true
        }
    }

    private func shareToWhatsApp() {
        recentStore.add(sinhalaOutput)
        useCounter.increment()
        let text = sinhalaOutput.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "whatsapp://send?text=\(text)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                toastMessage = "WhatsApp not installed"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showToast = false }
                }
            }
        }
    }

    private func shareText() {
        recentStore.add(sinhalaOutput)
        useCounter.increment()
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let window = windowScene.windows.first else { return }
        let activityVC = UIActivityViewController(activityItems: [sinhalaOutput], applicationActivities: nil)
        window.rootViewController?.present(activityVC, animated: true)
    }
}

struct OnboardingView: View {
    let dismiss: () -> Void
    @State private var currentPage = 0

    private let pages: [(title: String, subtitle: String, icon: String)] = [
        ("Welcome to Singlish LK", "Type English letters and get Sinhala instantly. Simple, fast, and beautiful.", "keyboard.fill"),
        ("Singlish → Sinhala", "Type 'kohomada' and get 'කොහොමද'. Works with all common Sinhala mappings.", "text.magnifyingglass"),
        ("Set Once, Stays Forever", "Switch to Singlish LK once — it becomes your default keyboard across all apps.", "arrow.triangle.swap"),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Image(systemName: pages[currentPage].icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text(pages[currentPage].title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(pages[currentPage].subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        dismiss()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 32)
                }

                if currentPage > 0 {
                    Button(action: { withAnimation { currentPage -= 1 } }) {
                        Text("Back")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    Button(action: dismiss) {
                        Text("Skip")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer().frame(height: 20)
            }
        }
    }
}
