import Foundation
import XCTest
@testable import CuedMac

final class DeckTests: XCTestCase {
    func testValidDeckPasses() {
        XCTAssertNoThrow(try DeckValidator.validate(Self.validDeck))
    }

    func testRejectsWrongSchema() {
        let deck = CueDeck(schemaVersion: 1, title: "Test", cards: Self.validDeck.cards)
        XCTAssertThrowsError(try DeckValidator.validate(deck)) { error in
            XCTAssertEqual(error as? DeckError, .invalidDeck("Unsupported schemaVersion. Cued accepts version 2."))
        }
    }

    func testRejectsMoreThanThreeBlocks() {
        var blocks = Self.validDeck.cards[0].blocks
        blocks.append(CueBlock(heading: "Fourth", bullets: ["No"]))
        let card = CueCard(id: "opening", title: "Opening", blocks: blocks)
        XCTAssertThrowsError(try DeckValidator.validate(CueDeck(schemaVersion: 2, title: "Test", cards: [card])))
    }

    func testRejectsLongBullet() {
        let bullet = "one two three four five six seven eight nine ten eleven twelve thirteen"
        let card = CueCard(
            id: "opening",
            title: "Opening",
            blocks: [
                CueBlock(heading: "Message", bullets: [bullet]),
                CueBlock(heading: "Question", bullets: ["Ask this"]),
                CueBlock(heading: "Watch", bullets: ["Notice that"])
            ]
        )
        XCTAssertThrowsError(try DeckValidator.validate(CueDeck(schemaVersion: 2, title: "Test", cards: [card])))
    }

    func testRejectsDuplicateIdsIgnoringCase() {
        let first = Self.validDeck.cards[0]
        let second = CueCard(id: "OPENING", title: "Second", blocks: first.blocks)
        XCTAssertThrowsError(try DeckValidator.validate(CueDeck(schemaVersion: 2, title: "Test", cards: [first, second])))
    }

    static let validDeck = CueDeck(
        schemaVersion: 2,
        title: "Test deck",
        cards: [
            CueCard(
                id: "opening",
                title: "Open with the point",
                blocks: [
                    CueBlock(heading: "Message", bullets: ["State the central point", "Keep it concrete"]),
                    CueBlock(heading: "Question", bullets: ["What matters most?"]),
                    CueBlock(heading: "Watch", bullets: ["Do not over-explain"])
                ]
            )
        ]
    )
}

final class StoreTests: XCTestCase {
    @MainActor
    func testAdvanceFinishesToLanding() throws {
        let store = CuedStore()
        let data = try JSONEncoder().encode(DeckTests.validDeck)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".cued.json")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        store.loadDeck(at: url)
        XCTAssertNotNil(store.deck)
        store.advance()
        XCTAssertNil(store.deck)
        XCTAssertEqual(store.currentIndex, 0)
        XCTAssertFalse(store.isGhostMode)
    }
}
