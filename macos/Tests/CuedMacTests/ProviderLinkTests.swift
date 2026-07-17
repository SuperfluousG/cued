import Foundation
import XCTest
@testable import CuedMac

final class ProviderLinkTests: XCTestCase {
    private let paths = CuedPaths(
        root: URL(fileURLWithPath: "/Users/Test Person/Documents/Cued", isDirectory: true),
        decks: URL(fileURLWithPath: "/Users/Test Person/Documents/Cued/Decks", isDirectory: true),
        skills: URL(fileURLWithPath: "/Users/Test Person/Documents/Cued/Skills", isDirectory: true),
        openAISkill: URL(fileURLWithPath: "/Users/Test Person/.agents/skills/make-cued-deck", isDirectory: true),
        claudeSkillPackage: URL(fileURLWithPath: "/Users/Test Person/Documents/Cued/Skills/make-cued-deck-claude.zip")
    )

    func testOpenAILinkContainsPromptAndWorkspace() throws {
        let components = try XCTUnwrap(URLComponents(url: ProviderLinks.url(for: .openAI, paths: paths), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "codex")
        XCTAssertEqual(components.host, "threads")
        XCTAssertEqual(components.path, "/new")
        XCTAssertEqual(value("path", in: components), paths.root.path)
        XCTAssertTrue(value("prompt", in: components)?.contains("$make-cued-deck") == true)
        XCTAssertTrue(value("prompt", in: components)?.contains(paths.decks.path) == true)
    }

    func testClaudeLinkContainsPromptAndFolder() throws {
        let components = try XCTUnwrap(URLComponents(url: ProviderLinks.url(for: .claude, paths: paths), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "claude")
        XCTAssertEqual(components.host, "cowork")
        XCTAssertEqual(components.path, "/new")
        XCTAssertEqual(value("folder", in: components), paths.root.path)
        XCTAssertTrue(value("q", in: components)?.contains("make-cued-deck") == true)
    }

    func testReturnLinkRoundTripsSpaces() throws {
        let deck = URL(fileURLWithPath: "/Users/Test Person/Documents/Cued/Decks/test deck.cued.json")
        let components = try XCTUnwrap(URLComponents(url: ProviderLinks.returnURL(for: deck), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "cued")
        XCTAssertEqual(components.host, "open")
        XCTAssertEqual(value("path", in: components), deck.path)
    }

    private func value(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}

