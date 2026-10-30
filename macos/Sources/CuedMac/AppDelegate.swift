import AppKit
import CuedCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var controller: CueWindowController!
    private var pendingFiles: [String] = []
    private let arguments = CommandLine.arguments

    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = value(after: "--smoke-report") == nil ? UserDefaults.standard : UserDefaults(suiteName: "dev.cued.release-smoke.\(ProcessInfo.processInfo.processIdentifier)")!
        controller = CueWindowController(defaults: defaults)
        buildMenus()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let report = value(after: "--smoke-report") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in runSmoke(directory: URL(fileURLWithPath: report)) }
            return
        }
        for file in pendingFiles { controller.open(URL(fileURLWithPath: file)) }
        pendingFiles.removeAll()
        if let file = arguments.dropFirst().first(where: { !$0.hasPrefix("-") }) { controller.open(URL(fileURLWithPath: file)) }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        if controller == nil { pendingFiles.append(contentsOf: filenames) }
        else { for file in filenames { controller.open(URL(fileURLWithPath: file)) } }
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controller?.showWindow(nil)
        controller?.window?.makeKeyAndOrderFront(nil)
        return true
    }

    private func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    private func buildMenus() {
        let menu = NSMenu()
        let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Cued", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Cued", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Cued", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        func section(_ title: String) -> NSMenu {
            let item = NSMenuItem(); item.title = title; menu.addItem(item)
            let submenu = NSMenu(title: title); item.submenu = submenu
            return submenu
        }
        func command(_ submenu: NSMenu, _ title: String, _ selector: Selector, _ key: String = "") {
            let item = submenu.addItem(withTitle: title, action: selector, keyEquivalent: key)
            item.target = controller
        }
        let file = section("File")
        command(file, "Open Deck…", #selector(CueWindowController.chooseDeck), "o")
        command(file, "Open Example", #selector(CueWindowController.openExample))
        command(file, "Create a Deck…", #selector(CueWindowController.createDeck), "n")
        file.addItem(.separator())
        file.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let view = section("View")
        command(view, "Toggle Ghost Mode", #selector(CueWindowController.toggleGhost), "g")
        command(view, "Larger Cue Text", #selector(CueWindowController.largerText), "+")
        command(view, "Smaller Cue Text", #selector(CueWindowController.smallerText), "-")
        let window = section("Window")
        window.addItem(withTitle: "Minimise", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        NSApp.windowsMenu = window
        let help = section("Help")
        command(help, "Create a Deck…", #selector(CueWindowController.createDeck))
        NSApp.helpMenu = help
        NSApp.mainMenu = menu
    }

    /// Runs inside the packaged AppKit app. These checks are deliberately labelled
    /// programmatic: they do not prove Finder gestures, keyboard focus or Gatekeeper.
    private func runSmoke(directory: URL) {
        var checks: [String: Bool] = [:]
        var failure: String?
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            guard let sample = Bundle.main.url(forResource: "sample.cued", withExtension: "json") else { throw DeckError("Bundled example is missing.") }
            checks["visibleWindow"] = controller.window?.isVisible == true
            checks["floatingLevel"] = controller.window?.level == .floating
            controller.open(sample, showError: false)
            checks["bundledExample"] = controller.session.deck?.cards.count == 4
            checks["firstCard"] = controller.session.index == 0
            checks["loadedCardHasKeyboardFocus"] = controller.cardHasKeyboardFocus
            checks["localSpaceAndLeftArrow"] = controller.checkCardKeyboardNavigation()
            checks["initialCardStartsAtTop"] = controller.isShowingStartOfCard
            try controller.writeRenderCapture(to: directory.appendingPathComponent("macos-packaged-first-card.png"))
            controller.next(); checks["next"] = controller.session.index == 1
            controller.back(); checks["back"] = controller.session.index == 0
            checks["focusedButtonSpaceDoesNotAdvance"] = controller.checkFocusedButtonSpace()
            if let fixtureDirectory = value(after: "--fixtures") {
                let manifest = URL(fileURLWithPath: fixtureDirectory).appendingPathComponent("manifest.json")
                let data = try Data(contentsOf: manifest)
                let fixtureManifest = try JSONDecoder().decode(FixtureManifest.self, from: data)
                guard let invalid = fixtureManifest.cases.first(where: { !$0.valid }) else { throw DeckError("No invalid recovery fixture.") }
                controller.open(URL(fileURLWithPath: fixtureDirectory).appendingPathComponent(invalid.file), showError: false)
                checks["rejectedLoadKeepsDeck"] = controller.session.deck?.cards.count == 4 && controller.session.index == 0
            }
            controller.setGhost(true)
            checks["ghostControlsRemainInteractive"] = controller.ghost && controller.window?.ignoresMouseEvents == false
            try controller.writeRenderCapture(to: directory.appendingPathComponent("macos-packaged-ghost.png"))
            controller.setGhost(false)
            for _ in 0..<12 { controller.largerText() }
            controller.window?.setContentSize(NSSize(width: 420, height: 480))
            controller.render()
            checks["enlargedCardStartsAtTop"] = controller.isShowingStartOfCard
            try controller.writeRenderCapture(to: directory.appendingPathComponent("macos-packaged-large-text.png"))
            for _ in 0..<4 { controller.next() }
            checks["finishReturnsToLanding"] = controller.session.deck == nil
            checks["copyPromptHasDestination"] = controller.creationPrompt.contains("/Documents/Cued/Decks")
            checks["settingsPersistLocally"] = controller.defaults.double(forKey: "textSize") == 30
            try controller.writeRenderCapture(to: directory.appendingPathComponent("macos-packaged-landing.png"))
        } catch { failure = error.localizedDescription }
        let passed = failure == nil && !checks.isEmpty && checks.values.allSatisfy { $0 }
        var result: [String: Any] = [
            "kind": "packaged-app-programmatic-smoke", "passed": passed, "checks": checks,
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "architecture": architecture,
            "screens": NSScreen.screens.map { ["width": $0.frame.width, "height": $0.frame.height, "backingScale": $0.backingScaleFactor] },
            "limitations": ["Render captures are generated from the app's own displayed view, not human desktop interaction.", "Finder Open With, drag/drop gestures, cross-app focus, Retina display matrix and Gatekeeper are NOT_RUN."]
        ]
        if let failure { result["error"] = failure }
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: directory.appendingPathComponent("packaged-app-smoke.json"))
            FileHandle.standardOutput.write(data)
        }
        exit(passed ? 0 : 1)
    }
}

struct FixtureManifest: Decodable {
    struct Case: Decodable { let file: String; let valid: Bool; let warnings: Int? }
    let cases: [Case]
}

var architecture: String {
    #if arch(arm64)
    return "arm64"
    #elseif arch(x86_64)
    return "x86_64"
    #else
    return "unknown"
    #endif
}
