import Foundation

struct CueDeck: Codable, Equatable {
    let schemaVersion: Int
    let title: String
    let cards: [CueCard]
}

struct CueCard: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let blocks: [CueBlock]
}

struct CueBlock: Codable, Equatable {
    let heading: String
    let bullets: [String]
}

enum DeckError: LocalizedError, Equatable {
    case fileTooLarge
    case invalidJSON(String)
    case invalidDeck(String)

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "The cue deck is larger than 1 MB."
        case .invalidJSON(let message):
            return "The file is not valid cue-deck JSON.\n\n\(message)"
        case .invalidDeck(let message):
            return message
        }
    }
}

enum DeckLoader {
    static let maximumBytes = 1_048_576

    static func load(from url: URL) throws -> CueDeck {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true else {
            throw DeckError.invalidDeck("Choose a cue-deck file.")
        }
        if let size = values.fileSize, size > maximumBytes {
            throw DeckError.fileTooLarge
        }

        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        if data.count > maximumBytes {
            throw DeckError.fileTooLarge
        }

        let deck: CueDeck
        do {
            deck = try JSONDecoder().decode(CueDeck.self, from: data)
        } catch {
            throw DeckError.invalidJSON(error.localizedDescription)
        }
        try DeckValidator.validate(deck)
        return deck
    }
}

enum DeckValidator {
    private static let kebabCase = try! NSRegularExpression(pattern: "^[a-z0-9]+(?:-[a-z0-9]+)*$")
    private static let wordPattern = try! NSRegularExpression(pattern: "[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*")

    static func validate(_ deck: CueDeck) throws {
        guard deck.schemaVersion == 2 else {
            throw DeckError.invalidDeck("Unsupported schemaVersion. Cued accepts version 2.")
        }
        guard !deck.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeckError.invalidDeck("The deck needs a title.")
        }
        guard deck.title.count <= 120 else {
            throw DeckError.invalidDeck("The deck title must be 120 characters or fewer.")
        }
        guard !deck.cards.isEmpty else {
            throw DeckError.invalidDeck("A deck must contain at least one card.")
        }

        var identifiers = Set<String>()
        for (cardIndex, card) in deck.cards.enumerated() {
            let number = cardIndex + 1
            guard !card.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DeckError.invalidDeck("Card \(number) needs an id.")
            }
            guard fullMatch(kebabCase, card.id) else {
                throw DeckError.invalidDeck("Card \(number) needs a kebab-case id.")
            }
            guard identifiers.insert(card.id.lowercased()).inserted else {
                throw DeckError.invalidDeck("Card ids must be unique.")
            }
            guard !card.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DeckError.invalidDeck("Card \(number) needs a title.")
            }
            guard wordCount(card.title) <= 6 else {
                throw DeckError.invalidDeck("Card \(number) has a title longer than six words.")
            }
            guard card.blocks.count == 3 else {
                throw DeckError.invalidDeck("Card \(number) must contain exactly three heading blocks.")
            }

            var totalWords = 0
            for (blockIndex, block) in card.blocks.enumerated() {
                let blockNumber = blockIndex + 1
                guard !block.heading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw DeckError.invalidDeck("Card \(number), heading \(blockNumber) needs a title.")
                }
                guard block.heading.count <= 100 else {
                    throw DeckError.invalidDeck("Card \(number), heading \(blockNumber) is longer than 100 characters.")
                }
                guard (1...3).contains(block.bullets.count) else {
                    throw DeckError.invalidDeck("Card \(number), heading \(blockNumber) must contain one to three bullets.")
                }

                var bullets = Set<String>()
                for bullet in block.bullets {
                    let trimmed = bullet.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        throw DeckError.invalidDeck("Card \(number) contains an empty bullet.")
                    }
                    guard bullets.insert(trimmed.lowercased()).inserted else {
                        throw DeckError.invalidDeck("Card \(number), heading \(blockNumber) contains a duplicate bullet.")
                    }
                    let words = wordCount(trimmed)
                    guard words <= 12 else {
                        throw DeckError.invalidDeck("Card \(number) contains a bullet longer than 12 words.")
                    }
                    totalWords += words
                }
            }
            guard totalWords <= 60 else {
                throw DeckError.invalidDeck("Card \(number) contains more than 60 cue words.")
            }
        }
    }

    private static func fullMatch(_ expression: NSRegularExpression, _ value: String) -> Bool {
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = expression.firstMatch(in: value, range: range) else { return false }
        return match.range == range
    }

    private static func wordCount(_ value: String) -> Int {
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return wordPattern.numberOfMatches(in: value, range: range)
    }
}

