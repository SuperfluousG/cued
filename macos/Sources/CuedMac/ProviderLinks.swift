import Foundation

enum Provider: String, CaseIterable {
    case openAI
    case claude

    var displayName: String {
        switch self {
        case .openAI: return "ChatGPT"
        case .claude: return "Claude Cowork"
        }
    }
}

enum ProviderLinkError: LocalizedError {
    case couldNotBuildLink

    var errorDescription: String? {
        "Cued could not prepare the provider link."
    }
}

enum ProviderLinks {
    static func url(for provider: Provider, paths: CuedPaths) throws -> URL {
        var components: URLComponents
        let prompt: String

        switch provider {
        case .openAI:
            components = URLComponents(string: "codex://threads/new")!
            prompt = "Switch this task to Work mode and GPT-5.6 Terra. " +
                "Use $make-cued-deck to prepare a Cued deck. " +
                "Ask what I am preparing for if needed. " +
                "Save the validated deck in \(paths.decks.path). " +
                "Then use the skill's authorised macOS return path to open the deck in Cued."
            components.queryItems = [
                URLQueryItem(name: "prompt", value: prompt),
                URLQueryItem(name: "path", value: paths.root.path)
            ]
        case .claude:
            components = URLComponents(string: "claude://cowork/new")!
            prompt = "Use the installed make-cued-deck skill to prepare a Cued deck. " +
                "Use relevant context already available; otherwise ask what I am preparing for. " +
                "Save the validated .cued.json in \(paths.decks.path). " +
                "When finished, use the skill's authorised macOS return path to open the deck in Cued. " +
                "If desktop control is unavailable, return the file only. Keep delivery to the skill's required single line."
            components.queryItems = [
                URLQueryItem(name: "q", value: prompt),
                URLQueryItem(name: "folder", value: paths.root.path)
            ]
        }

        guard let result = components.url else { throw ProviderLinkError.couldNotBuildLink }
        return result
    }

    static func returnURL(for deck: URL) throws -> URL {
        var components = URLComponents()
        components.scheme = "cued"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "path", value: deck.path)]
        guard let result = components.url else { throw ProviderLinkError.couldNotBuildLink }
        return result
    }
}

