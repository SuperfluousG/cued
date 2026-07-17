import AppKit
import Foundation

@MainActor
final class CuedStore: ObservableObject {
    @Published private(set) var deck: CueDeck?
    @Published private(set) var currentIndex = 0
    @Published var isGhostMode = false
    @Published var isSettingsVisible = false
    @Published var cueTextSize = 20.0
    @Published var ghostTextOpacity = 0.90
    @Published var reducedMotion = false
    @Published var alertMessage: String?
    @Published var isOnboardingVisible = false
    @Published var supportStatus = SupportStatus()

    var currentCard: CueCard? {
        guard let deck, deck.cards.indices.contains(currentIndex) else { return nil }
        return deck.cards[currentIndex]
    }

    var nextTitle: String {
        guard let deck else { return "" }
        if currentIndex >= deck.cards.count - 1 { return "Finish deck" }
        return "Next: \(deck.cards[currentIndex + 1].title)"
    }

    var positionText: String {
        guard let deck else { return "" }
        return "\(currentIndex + 1) / \(deck.cards.count)"
    }

    var canGoBack: Bool { deck != nil && currentIndex > 0 }
    var isFinalCard: Bool { deck != nil && currentIndex == (deck?.cards.count ?? 1) - 1 }

    func loadDeck(at url: URL) {
        do {
            let loaded = try DeckLoader.load(from: url)
            deck = loaded
            currentIndex = 0
            isGhostMode = false
            isSettingsVisible = false
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func chooseDeck() {
        let panel = NSOpenPanel()
        panel.title = "Open Cued deck"
        panel.prompt = "Open"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            loadDeck(at: url)
        }
    }

    func advance() {
        guard let deck else { return }
        if currentIndex >= deck.cards.count - 1 {
            showLanding()
        } else {
            currentIndex += 1
        }
    }

    func back() {
        guard canGoBack else { return }
        currentIndex -= 1
    }

    func moveForwardWithoutAnimation() {
        advance()
    }

    func showLanding() {
        deck = nil
        currentIndex = 0
        isGhostMode = false
        isSettingsVisible = false
    }

    func toggleGhost() {
        isGhostMode.toggle()
    }

    func openProvider(_ provider: Provider) {
        do {
            let url = try ProviderLinks.url(for: provider, paths: CuedPaths.live)
            guard NSWorkspace.shared.open(url) else {
                alertMessage = "Cued could not open \(provider.displayName). Make sure its macOS desktop app is installed."
                return
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func prepareSupportFiles() {
        do {
            supportStatus = try SupportInstaller.prepare(paths: CuedPaths.live)
        } catch {
            supportStatus = SupportStatus(error: error.localizedDescription)
        }
        isOnboardingVisible = !UserDefaults.standard.bool(forKey: "CuedOnboardingComplete")
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "CuedOnboardingComplete")
        isOnboardingVisible = false
    }

    func reinstallOpenAISkill() {
        do {
            supportStatus = try SupportInstaller.prepare(paths: CuedPaths.live)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func revealClaudeSkill() {
        let url = CuedPaths.live.claudeSkillPackage
        guard FileManager.default.fileExists(atPath: url.path) else {
            alertMessage = "The Claude skill package was not found. Reinstall the Cued support files first."
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
