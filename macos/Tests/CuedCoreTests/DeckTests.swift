import XCTest
import Darwin
@testable import CuedCore

final class DeckTests: XCTestCase {
    struct Manifest: Decodable {
        struct Case: Decodable { let file: String; let valid: Bool; let warnings: Int? }
        let cases: [Case]
    }
    var fixtures: URL {
        if let directory = ProcessInfo.processInfo.environment["CUED_FIXTURES"] { return URL(fileURLWithPath: directory) }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("tests/fixtures")
    }

    override func setUpWithError() throws {
        // This explicit test input is only consumed by DEBUG builds of CuedCore.
        setenv("CUED_UNICODE_RULES", fixtures.appendingPathComponent("unicode-rules.json").path, 1)
    }

    func testSharedCorpus() throws {
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: fixtures.appendingPathComponent("manifest.json")))
        XCTAssertFalse(manifest.cases.isEmpty)
        var results: [[String: Any]] = []
        for fixture in manifest.cases {
            var accepted = false, warningCount = 0, diagnostic = ""
            do {
                let deck = try Deck.load(url: fixtures.appendingPathComponent(fixture.file))
                accepted = true; warningCount = deck.warnings.count
            } catch { diagnostic = error.localizedDescription }
            let passed = accepted == fixture.valid && (!fixture.valid || fixture.warnings == warningCount)
            XCTAssertTrue(passed, "\(fixture.file): expected valid=\(fixture.valid), observed=\(accepted), warnings=\(warningCount); \(diagnostic)")
            results.append(["file": fixture.file, "expectedValid": fixture.valid, "actualValid": accepted, "warnings": warningCount, "passed": passed, "diagnostic": diagnostic])
        }
        if let report = ProcessInfo.processInfo.environment["CUED_FIXTURE_REPORT"] {
            let data = try JSONSerialization.data(withJSONObject: ["implementation": "macOS Swift", "cases": results, "passed": results.allSatisfy { $0["passed"] as? Bool == true }], options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: report))
        }
    }

    func testFailedReplacementPreservesPlaybackAndFinishingIsStable() throws {
        let session = DeckSession()
        let sample = fixtures.appendingPathComponent("valid/sample.cued.json")
        try session.load(url: sample)
        session.advance()
        let originalCard = session.card?.id
        let originalData = try Data(contentsOf: sample)
        XCTAssertThrowsError(try session.load(url: fixtures.appendingPathComponent("does-not-exist.cued.json")))
        XCTAssertEqual(session.card?.id, originalCard)
        XCTAssertEqual(session.index, 1)
        session.back(); session.back()
        XCTAssertEqual(session.index, 0)
        let count = try XCTUnwrap(session.deck?.cards.count)
        for _ in 0..<count { session.advance() }
        XCTAssertNil(session.deck)
        session.advance(); session.back()
        XCTAssertNil(session.deck)
        XCTAssertEqual(session.index, 0)
        XCTAssertEqual(try Data(contentsOf: sample), originalData)
    }

    func testWordRulePreservesHyphensApostrophesAndExistingUnicodeSemantics() {
        XCTAssertEqual(Deck.wordCount("Don't re-write version-2"), 3)
        XCTAssertEqual(Deck.wordCount("Café déjà 東京"), 3)
    }
}
