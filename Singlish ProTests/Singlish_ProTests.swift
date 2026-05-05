//
//  Singlish_ProTests.swift
//  Singlish ProTests
//
//  Created by KD Jayakody on 2026-04-23.
//

import Testing
@testable import Singlish_Pro

struct Singlish_ProTests {

    @Test func testBasicConversion() async throws {
        let engine = SinglishEngine()

        // Test basic consonant conversion
        engine.append("k")
        #expect(engine.displayText == "ක්")

        engine.reset()
        engine.append("o")
        engine.append("y")
        engine.append("a")
        #expect(engine.displayText == "ඔය")

        engine.reset()
        engine.append("m")
        engine.append("a")
        engine.append("m")
        engine.append("a")
        #expect(engine.displayText == "මම")
    }

    @Test func testVowelConversion() async throws {
        let engine = SinglishEngine()

        // Test vowel combinations
        engine.append("a")
        engine.append("a")
        #expect(engine.displayText == "ආ")

        engine.reset()
        engine.append("a")
        engine.append("e")
        #expect(engine.displayText == "ඈ")

        engine.reset()
        engine.append("i")
        engine.append("i")
        #expect(engine.displayText == "ඊ")
    }

    @Test func testWordConversion() async throws {
        let engine = SinglishEngine()

        // Test common word conversions
        engine.append("k")
        engine.append("o")
        engine.append("h")
        engine.append("o")
        engine.append("m")
        engine.append("a")
        engine.append("d")
        engine.append("h")
        engine.append("a")
        let result = engine.displayText
        #expect(result.contains("කොහොමද"))
    }

    @Test func testSuggestions() async throws {
        let engine = SinglishEngine()

        engine.append("k")
        engine.append("o")
        engine.append("h")
        engine.append("o")
        engine.append("m")
        engine.append("a")
        engine.append("d")
        engine.append("a")

        let suggestions = engine.suggestions
        #expect(!suggestions.isEmpty)
        #expect(suggestions.contains("කොහොමද"))
    }

    @Test func testDeleteBackward() async throws {
        let engine = SinglishEngine()

        engine.append("m")
        engine.append("a")
        engine.append("m")
        engine.append("a")
        #expect(engine.displayText == "මම")

        engine.deleteBackward()
        #expect(engine.displayText == "මම්")

        engine.deleteBackward()
        #expect(engine.displayText == "ම")
    }

    @Test func testReset() async throws {
        let engine = SinglishEngine()

        engine.append("m")
        engine.append("a")
        engine.append("m")
        engine.append("a")
        #expect(!engine.englishBuffer.isEmpty)

        engine.reset()
        #expect(engine.englishBuffer.isEmpty)
        #expect(engine.displayText == "")
    }

    @Test func testCommit() async throws {
        let engine = SinglishEngine()

        engine.append("m")
        engine.append("a")
        engine.append("m")
        engine.append("a")

        let committed = engine.commit()
        #expect(committed == "මම")
        #expect(engine.englishBuffer.isEmpty)
    }

    @Test func testEmptyInput() async throws {
        let engine = SinglishEngine()

        #expect(engine.displayText == "")
        #expect(engine.suggestions.isEmpty)
    }

    @Test func testConsonantVowelCombination() async throws {
        let engine = SinglishEngine()

        engine.append("k")
        engine.append("o")
        #expect(engine.displayText == "කො")

        engine.reset()
        engine.append("b")
        engine.append("a")
        #expect(engine.displayText == "බ")
    }

    @Test func testSpecialCharacters() async throws {
        let engine = SinglishEngine()

        engine.append("h")
        engine.append("a")
        engine.append("l")
        // Test rakaransaya (r combination)
        #expect(engine.displayText.contains("ල්"))
    }

    @Test func testLearnedWordsSuggestByLatinInputPrefix() async throws {
        let learnedWords = LearnedWords.shared
        let prefix = "ko_test_a"

        learnedWords.record(input: prefix, output: "කොහොමද")
        learnedWords.record(input: prefix, output: "කොහොමද")
        learnedWords.record(input: prefix, output: "කොහොමද?")
        learnedWords.record(input: "ma_test_a", output: "මම")

        let suggestions = learnedWords.suggestions(forInputPrefix: prefix, limit: 3)

        #expect(suggestions.first == "කොහොමද")
        #expect(suggestions.contains("කොහොමද?"))
        #expect(!suggestions.contains("මම"))
    }

    @Test func testLearnedWordsFallbackSupportsLegacyPrefixQueries() async throws {
        let learnedWords = LearnedWords.shared
        let inputPrefix = "ko_test_b"

        learnedWords.record(input: inputPrefix, output: "කොහොමද")
        let sinhalaSuggestions = learnedWords.suggestions(for: "කො", limit: 10)

        #expect(sinhalaSuggestions.contains("කොහොමද"))
    }

    @Test func testSinhalaCompositionDeletionCounts() async throws {
        #expect(SinhalaComposition.deletionCount(for: "ම") == 1)
        #expect(SinhalaComposition.deletionCount(for: "ම්") == 2)
        #expect(SinhalaComposition.deletionCount(for: "ක්") == 2)
        #expect(SinhalaComposition.deletionCount(for: "කො") == 2)
    }

}
