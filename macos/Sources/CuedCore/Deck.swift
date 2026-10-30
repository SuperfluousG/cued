import Foundation

public struct DeckError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public struct CueBlock { public let heading: String; public let bullets: [String] }
public struct CueCard { public let id: String; public let title: String; public let blocks: [CueBlock] }

private struct UnicodeRules: Decodable {
    let casefold: [String: String]
    let whitespace: [UInt32]
    static let shared: UnicodeRules? = {
        // The shipped app only reads its own resource. Test-only lookup is
        // compiled out of release builds and never embeds an absolute source path.
        var resource = Bundle.main.url(forResource: "unicode-rules", withExtension: "json")
        #if DEBUG
        if resource == nil, let path = ProcessInfo.processInfo.environment["CUED_UNICODE_RULES"] {
            resource = URL(fileURLWithPath: path)
        }
        #endif
        guard let url = resource,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(UnicodeRules.self, from: data)
    }()

    func trim(_ value: String) -> String {
        let scalars = Array(value.unicodeScalars)
        let spaces = Set(whitespace)
        var start = 0, end = scalars.count
        while start < end && spaces.contains(scalars[start].value) { start += 1 }
        while end > start && spaces.contains(scalars[end - 1].value) { end -= 1 }
        return String(String.UnicodeScalarView(scalars[start..<end]))
    }

    func fold(_ value: String) -> Data {
        // Data equality is deliberate: Swift String equality normalises Unicode,
        // whereas the canonical validator casefolds without NFC normalisation.
        Data(value.unicodeScalars.map { casefold[String($0.value)] ?? String($0) }.joined().utf8)
    }
}

public struct Deck {
    public let title: String
    public let cards: [CueCard]
    public let warnings: [String]

    public static func load(url: URL) throws -> Deck {
        guard url.lastPathComponent.lowercased().hasSuffix(".cued.json") else {
            throw DeckError("Choose a file whose name ends with .cued.json.")
        }
        return try decode(Data(contentsOf: url))
    }

    public static func decode(_ data: Data) throws -> Deck {
        guard let rules = UnicodeRules.shared else {
            throw DeckError("Cued's validation resource is missing. Reinstall the complete application.")
        }
        var parser = try StrictJSON(data: data)
        let root = try object(parser.parse(), keys: ["schemaVersion", "title", "cards"], path: "Deck")
        guard case .number(let version)? = root["schemaVersion"], version == 2 else {
            throw DeckError("schemaVersion must be the number 2.")
        }
        let title = try string(root["title"], maximum: 120, path: "Deck title", rules: rules)
        guard case .array(let rawCards)? = root["cards"], !rawCards.isEmpty else {
            throw DeckError("A deck must contain at least one card.")
        }
        var cards: [CueCard] = [], warnings: [String] = [], ids = Set<String>()
        for (cardIndex, rawCard) in rawCards.enumerated() {
            let path = "Card \(cardIndex + 1)"
            let card = try object(rawCard, keys: ["id", "title", "blocks"], path: path)
            let id = try string(card["id"], maximum: nil, path: "\(path) ID", rules: rules)
            guard id.range(of: "\\A[a-z0-9]+(?:-[a-z0-9]+)*\\z", options: .regularExpression) != nil,
                  ids.insert(id).inserted else { throw DeckError("\(path) needs a unique kebab-case ID.") }
            let cardTitle = try string(card["title"], maximum: 100, path: "\(path) title", rules: rules)
            guard wordCount(cardTitle) <= 6 else { throw DeckError("\(path) title exceeds six words.") }
            guard case .array(let rawBlocks)? = card["blocks"], rawBlocks.count == 3 else {
                throw DeckError("\(path) must contain exactly three heading blocks.")
            }
            var blocks: [CueBlock] = [], total = 0
            for (blockIndex, rawBlock) in rawBlocks.enumerated() {
                let blockPath = "\(path), block \(blockIndex + 1)"
                let block = try object(rawBlock, keys: ["heading", "bullets"], path: blockPath)
                let heading = try string(block["heading"], maximum: 100, path: "\(blockPath) heading", rules: rules)
                guard case .array(let rawBullets)? = block["bullets"], (1...3).contains(rawBullets.count) else {
                    throw DeckError("\(blockPath) must contain one to three bullets.")
                }
                var bullets: [String] = [], seen = Set<Data>()
                for (bulletIndex, rawBullet) in rawBullets.enumerated() {
                    let bulletPath = "\(blockPath), bullet \(bulletIndex + 1)"
                    let bullet = try string(rawBullet, maximum: 180, path: bulletPath, rules: rules)
                    guard seen.insert(rules.fold(rules.trim(bullet))).inserted else {
                        throw DeckError("\(bulletPath) repeats a bullet within the same heading.")
                    }
                    let words = wordCount(bullet)
                    guard words <= 12 else { throw DeckError("\(bulletPath) exceeds twelve words.") }
                    if words < 4 || words > 8 { warnings.append("\(bulletPath): target is four to eight words; found \(words).") }
                    total += words
                    bullets.append(bullet)
                }
                blocks.append(CueBlock(heading: heading, bullets: bullets))
            }
            guard total <= 60 else { throw DeckError("\(path) exceeds sixty cue words.") }
            cards.append(CueCard(id: id, title: cardTitle, blocks: blocks))
        }
        return Deck(title: title, cards: cards, warnings: warnings)
    }

    public static func wordCount(_ text: String) -> Int {
        let regex = try! NSRegularExpression(pattern: "[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*")
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }

    private static func object(_ value: JSONValue, keys: Set<String>, path: String) throws -> [String: JSONValue] {
        guard case .object(let object) = value else { throw DeckError("\(path) must be an object.") }
        guard Set(object.keys) == keys else { throw DeckError("\(path) must contain only \(keys.sorted().joined(separator: ", ")).") }
        return object
    }

    private static func string(_ value: JSONValue?, maximum: Int?, path: String, rules: UnicodeRules) throws -> String {
        guard case .string(let text)? = value, !rules.trim(text).isEmpty else {
            throw DeckError("\(path) must be a non-empty string.")
        }
        if let maximum, text.unicodeScalars.count > maximum { throw DeckError("\(path) exceeds \(maximum) characters.") }
        return text
    }
}
