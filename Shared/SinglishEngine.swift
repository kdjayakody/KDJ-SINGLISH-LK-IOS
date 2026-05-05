import Foundation

enum SinhalaComposition {
    static func deletionCount(for text: String) -> Int {
        text.unicodeScalars.count
    }
}

final class SinglishEngine {
    private var buffer: String = ""

    private static let hal = "\u{0DCA}"
    private static let zwj = "\u{200D}"
    private static let rakaransha = "\u{0DCA}\u{200D}\u{0DBB}"

    private static let vowels: [(String, String, String)] = [
        ("oo", "ඕ", "ෝ"), ("o)", "ඕ", "ෝ"), ("oe", "ඕ", "ෝ"),
        ("aa", "ආ", "ා"), ("a)", "ආ", "ා"),
        ("Aa", "ඈ", ""), ("A)", "ඈ", "ෑ"), ("ae", "ඈ", "ෑ"),
        ("ii", "ඊ", "ී"), ("i)", "ඊ", "ී"), ("ie", "ඊ", "ී"),
        ("ee", "ඒ", "ේ"), ("ea", "ඒ", "ේ"), ("e)", "ඒ", "ේ"), ("ei", "ඒ", "ේ"),
        ("uu", "ඌ", "ූ"), ("u)", "ඌ", ""),
        ("au", "ඖ", "ෞ"), ("/a", "ඇ", "ැ"),
        ("a",  "අ", ""), ("A", "ඇ", "ැ"),
        ("i",  "ඉ", "ි"), ("e", "එ", "ෙ"),
        ("u",  "උ", "ු"), ("o", "ඔ", "ො"), ("I", "ඓ", "ෛ"),
    ]

    private static let consonants: [(String, String)] = [
        ("nnd", "ඬ"), ("nndh", "ඳ"), ("nng", "ඟ"),
        ("Th", "ථ"), ("Dh", "ධ"), ("gh", "ඝ"), ("Ch", "ඡ"),
        ("ph", "ඵ"), ("bh", "භ"), ("sh", "ශ"), ("Sh", "ෂ"),
        ("GN", "ඥ"), ("KN", "ඤ"), ("Lu", "ළු"),
        ("dh", "ද"), ("ch", "ච"), ("kh", "ඛ"), ("th", "ත"),
        ("t", "ට"), ("k", "ක"), ("d", "ඩ"), ("n", "න"),
        ("p", "ප"), ("b", "බ"), ("m", "ම"),
        ("\\y", zwj + "ය"), ("Y", zwj + "ය"), ("y", "ය"),
        ("j", "ජ"), ("l", "ල"), ("v", "ව"), ("w", "ව"),
        ("s", "ස"), ("h", "හ"), ("N", "ණ"), ("L", "ළ"),
        ("K", "ඛ"), ("G", "ඝ"), ("T", "ඨ"), ("D", "ඪ"),
        ("P", "ඵ"), ("B", "ඹ"), ("f", "ෆ"), ("q", "ඣ"),
        ("g", "ග"), ("r", "ර"),
    ]

    private static let specialConsonants: [(String, String)] = [
        ("\\n", "ං"), ("\\h", "ඃ"), ("\\N", "ඞ"),
        ("\\R", "ඍ"), ("R", "ර\u{0DCA}\u{200D}"),
        ("\\r", "ර\u{0DCA}\u{200D}"), ("x", "ං"),
    ]

    private static let specialChars: [(String, String)] = [
        ("ruu", "\u{0DF2}"), ("ru", "\u{0DD8}"),
    ]

    private static let wordSuggestions: [String: [String]] = [
        "kohomada": ["කොහොමද", "කොහොමද?"],
        "ayubowan": ["ආයුබෝවන්", "ආයුබෝවන්!"],
        "sthuthiyi": ["ස්තූතියි", "ස්තූතියි!"],
        "subha": ["සුභ", "සුභ උදෑසනක්", "සුභ රාත්‍රියක්"],
        "mama": ["මම", "මාමා"],
        "oya": ["ඔයා", "ඔයාගේ"],
        "mey": ["මේ", "මේයි"],
        "mokada": ["මොකද", "මොකද?"],
        "hondai": ["හොඳයි", "හොඳයි!"],
        "narakai": ["නරකයි", "නරකයි!"],
        "puluwan": ["පුළුවන්", "පුළුවන්!"],
        "behesvara": ["බෙහෙස්වර", "බෙහෙස්වර!"],
        "iyawada": ["ඉයවද", "ඉයවද?"],
        "gihilla": ["ගිහිල්ල", "ගිහිල්ලා"],
        "enawa": ["එනවා", "එනවා!"],
        "yanna": ["යන්න", "යන්නා"],
        "denna": ["දෙන්න", "දෙන්නා"],
        "karanawa": ["කරනවා", "කරනවා!"],
        "balanawa": ["බලනවා", "බලනවා!"],
        "kianawa": ["කියනවා", "කියනවා!"],
        "kenek": ["කෙනක්", "කෙනෙක්"],
        "eka": ["එක", "එකක්"],
        "deka": ["දෙක", "දෙකක්"],
        "thunak": ["තුනක්", "තුනක්!"],
    ]

    private static let phoneticMap: [String: String] = {
        var m: [String: String] = [:]
        for (lat, uni, _) in vowels { m[lat] = uni }
        for (lat, uni) in consonants where !lat.hasPrefix("\\") { m[lat] = uni + hal }
        for (cLat, cUni) in consonants { for (vLat, _, vMod) in vowels { m[cLat + vLat] = cUni + vMod } }
        for (cLat, cUni) in consonants { m[cLat + "r"] = cUni + rakaransha }
        for (cLat, cUni) in consonants { for (vLat, _, vMod) in vowels { m[cLat + "r" + vLat] = cUni + rakaransha + vMod } }
        for (cLat, cUni) in consonants { for (scLat, scUni) in specialChars { m[cLat + scLat] = cUni + scUni } }
        for (scLat, scUni) in specialConsonants { m[scLat] = scUni }
        return m
    }()

    private static let maxKeyLength: Int = phoneticMap.keys.map(\.count).max() ?? 0

    var englishBuffer: String { buffer }

    var displayText: String {
        convert(buffer)
    }

    var suggestions: [String] {
        guard !buffer.isEmpty else { return [] }
        let lower = buffer.lowercased()
        if let exact = Self.wordSuggestions[lower] {
            return exact
        }
        let matches = Self.wordSuggestions.keys.filter { $0.hasPrefix(lower) }.sorted { $0.count < $1.count }
        if !matches.isEmpty {
            let results = matches.prefix(3).flatMap { Self.wordSuggestions[$0] ?? [] }
            return Array(results.prefix(3))
        }
        let converted = displayText
        guard !converted.isEmpty else { return [] }
        var deduped: [String] = []
        if converted.contains(" ") {
            deduped.append(converted)
        } else {
            deduped.append(contentsOf: wordCompletionSuggestions(for: converted))
        }
        return deduped.isEmpty ? [converted] : deduped
    }

    func wordCompletionSuggestions(for word: String) -> [String] {
        let prefixes: [(String, String)] = [
            ("කොහො", "කොහොමද"),
            ("ආයු", "ආයුබෝවන්"),
            ("ස්තූ", "ස්තූතියි"),
            ("සුභ", "සුභ උදෑසනක්"),
            ("හො", "හොඳයි"),
            ("එන", "එනවා"),
            ("යන", "යන්න"),
            ("කර", "කරනවා"),
            ("බල", "බලනවා"),
            ("කිය", "කියනවා"),
        ]
        return prefixes.filter { word.hasPrefix($0.0) && word != $0.1 }.map { $0.1 }
    }

    func append(_ char: Character) {
        buffer.append(char)
    }

    func commit() -> String {
        let result = convert(buffer)
        buffer = ""
        return result
    }

    func deleteBackward() {
        guard !buffer.isEmpty else { return }
        buffer.removeLast()
    }

    func reset() {
        buffer = ""
    }

    func convertToSinhala(_ text: String) -> String {
        convert(text)
    }

    private func convert(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        var result = ""
        let chars = Array(text)
        let totalLen = chars.count
        var i = 0
        while i < totalLen {
            var matched = false
            let remainingLen = totalLen - i
            let maxLen = min(Self.maxKeyLength, remainingLen)
            if maxLen > 0 {
                for length in (1...maxLen).reversed() {
                    let chunkStart = i
                    let chunkEnd = i + length
                    let chunk = String(chars[chunkStart..<chunkEnd])
                    if let value = Self.phoneticMap[chunk] {
                        result.append(value)
                        i = chunkEnd
                        matched = true
                        break
                    }
                }
            }
            if !matched {
                result.append(chars[i])
                i += 1
            }
        }
        return result
    }
}
