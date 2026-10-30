import Foundation

/// Replaces the active deck only after full validation. Playback never writes a deck.
public final class DeckSession {
    public private(set) var deck: Deck?
    public private(set) var index = 0
    public var card: CueCard? { deck.map { $0.cards[index] } }
    public var isFinalCard: Bool { deck.map { index == $0.cards.count - 1 } ?? false }
    public init() {}

    public func load(url: URL) throws {
        let candidate = try Deck.load(url: url)
        deck = candidate
        index = 0
    }
    public func advance() {
        guard let deck else { return }
        if index + 1 == deck.cards.count { finish() } else { index += 1 }
    }
    public func back() { index = max(0, index - 1) }
    public func finish() { deck = nil; index = 0 }
}
