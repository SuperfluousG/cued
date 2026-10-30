import AppKit
import CuedCore

final class CueWindowController: NSWindowController, NSWindowDelegate {
    let session = DeckSession()
    let defaults: UserDefaults
    private(set) var ghost = false
    private(set) var textSize: CGFloat
    private let surface = CueView(frame: .zero)
    private let body = NSStackView()
    private let position = cueLabel("", size: 12, muted: true)
    private let titleLabel = cueLabel("Cued", size: 28, weight: .semibold)
    private let backButton = NSButton(title: "← Back", target: nil, action: nil)
    private let nextButton = NSButton(title: "Next", target: nil, action: nil)
    private let ghostButton = NSButton(title: "Ghost", target: nil, action: nil)
    private let footer = NSStackView()
    private let scroll = NSScrollView()

    init(defaults: UserDefaults) {
        self.defaults = defaults
        textSize = CGFloat(defaults.object(forKey: "textSize") as? Double ?? 20)
        textSize = min(30, max(17, textSize))
        let window = CueWindow(contentRect: NSRect(x: 160, y: 160, width: 520, height: 720),
                               styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                               backing: .buffered, defer: false)
        window.title = "Cued"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.fullScreenAuxiliary]
        window.minSize = NSSize(width: 420, height: 480)
        window.appearance = NSAppearance(named: .darkAqua)
        super.init(window: window)
        window.delegate = self
        buildInterface()
        restoreFrame()
        window.playbackKey = { [weak self] code in
            if code == 123 { self?.back() } else { self?.next() }
        }
        surface.onDrop = { [weak self] url in self?.open(url) }
        render()
    }
    required init?(coder: NSCoder) { fatalError("Use init(defaults:)") }

    private func button(_ title: String, action: Selector, help: String) -> NSButton {
        let result = NSButton(title: title, target: self, action: action)
        result.bezelStyle = .rounded
        result.toolTip = help
        result.setAccessibilityLabel(help)
        return result
    }

    private func buildInterface() {
        guard let window else { return }
        window.contentView = surface
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        surface.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: surface.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: surface.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: surface.topAnchor, constant: 36),
            stack.bottomAnchor.constraint(equalTo: surface.bottomAnchor, constant: -20)
        ])

        let top = NSStackView()
        top.spacing = 8
        top.addArrangedSubview(button("Open…", action: #selector(chooseDeck), help: "Open a Cued deck"))
        top.addArrangedSubview(button("A−", action: #selector(smallerText), help: "Make cue text smaller"))
        top.addArrangedSubview(button("A+", action: #selector(largerText), help: "Make cue text larger"))
        ghostButton.target = self
        ghostButton.action = #selector(toggleGhost)
        ghostButton.bezelStyle = .rounded
        ghostButton.toolTip = "Toggle transparent ghost mode"
        ghostButton.setAccessibilityLabel("Ghost mode")
        top.addArrangedSubview(ghostButton)
        top.addArrangedSubview(position)
        stack.addArrangedSubview(top)
        top.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        position.setContentHuggingPriority(.defaultLow, for: .horizontal)
        position.alignment = .right

        stack.addArrangedSubview(titleLabel)
        titleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        body.orientation = .vertical
        body.alignment = .leading
        body.spacing = 9
        body.translatesAutoresizingMaskIntoConstraints = false
        let document = NSView()
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(body)
        scroll.documentView = document
        NSLayoutConstraint.activate([
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            body.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -10),
            body.topAnchor.constraint(equalTo: document.topAnchor),
            body.bottomAnchor.constraint(equalTo: document.bottomAnchor)
        ])
        stack.addArrangedSubview(scroll)
        scroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        scroll.setContentHuggingPriority(.defaultLow, for: .vertical)

        footer.spacing = 12
        backButton.target = self; backButton.action = #selector(back)
        nextButton.target = self; nextButton.action = #selector(next)
        for button in [backButton, nextButton] { button.bezelStyle = .rounded; footer.addArrangedSubview(button) }
        nextButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nextButton.lineBreakMode = .byTruncatingTail
        nextButton.setAccessibilityLabel("Next card or finish deck")
        stack.addArrangedSubview(footer)
        footer.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    func open(_ url: URL, showError: Bool = true) {
        do {
            try session.load(url: url)
            setGhost(false)
            render()
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } catch {
            guard showError else { return }
            let alert = NSAlert()
            alert.messageText = "Could not open this deck"
            alert.informativeText = error.localizedDescription + "\n\nYour current deck has not changed."
            alert.alertStyle = .warning
            if let window { alert.beginSheetModal(for: window) }
        }
    }

    @objc func chooseDeck() {
        let panel = NSOpenPanel()
        panel.title = "Open a Cued deck"
        panel.message = "Choose a file ending in .cued.json."
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        guard let window else { return }
        panel.beginSheetModal(for: window) { [weak self] response in
            if response == .OK, let url = panel.url { self?.open(url) }
        }
    }

    @objc func openExample() {
        guard let url = Bundle.main.url(forResource: "sample.cued", withExtension: "json") else {
            let alert = NSAlert(); alert.messageText = "The example is missing from this application bundle."; alert.runModal(); return
        }
        open(url)
    }

    @objc func next() { session.advance(); if session.deck == nil { setGhost(false) }; render() }
    @objc func back() { session.back(); render() }
    @objc func toggleGhost() { setGhost(!ghost) }
    func setGhost(_ value: Bool) {
        ghost = value
        surface.ghost = value
        ghostButton.state = value ? .on : .off
        ghostButton.title = value ? "Solid" : "Ghost"
        // Preserve input handling and readable control surfaces in both modes.
        window?.hasShadow = !value
        body.alphaValue = value ? 0.94 : 1
    }
    @objc func smallerText() { changeTextSize(-1) }
    @objc func largerText() { changeTextSize(1) }
    private func changeTextSize(_ amount: CGFloat) {
        textSize = min(30, max(17, textSize + amount))
        defaults.set(Double(textSize), forKey: "textSize")
        render()
    }

    func render() {
        for child in body.arrangedSubviews { body.removeArrangedSubview(child); child.removeFromSuperview() }
        window?.title = session.deck.map { "Cued — \($0.title)" } ?? "Cued"
        guard let card = session.card, let deck = session.deck else {
            titleLabel.stringValue = "Cued"
            position.stringValue = ""
            footer.isHidden = true
            add(cueLabel("Speaking cards without the script", size: 22, weight: .medium))
            add(cueLabel("Keep a few clear prompts beside your camera. Open a deck or drop one onto this window.", size: 17, muted: true))
            add(button("Try the four-card example", action: #selector(openExample), help: "Open the included four-card example"))
            add(button("Create a deck with your AI tool…", action: #selector(createDeck), help: "Copy a prepared deck creation prompt"))
            add(cueLabel("Space or →: next · ←: back\nDrag the title bar to move. Drag an edge to resize.", size: 13, muted: true))
            resetScroll()
            return
        }
        titleLabel.stringValue = card.title
        position.stringValue = "\(session.index + 1) / \(deck.cards.count)"
        footer.isHidden = false
        backButton.isEnabled = session.index > 0
        nextButton.title = session.isFinalCard ? "Finish deck" : "Next: \(deck.cards[session.index + 1].title)"
        nextButton.toolTip = nextButton.title
        for (index, block) in card.blocks.enumerated() {
            if index > 0 { let gap = NSView(); gap.heightAnchor.constraint(equalToConstant: 8).isActive = true; add(gap) }
            add(cueLabel(block.heading, size: max(16, textSize - 1), weight: .semibold))
            for bullet in block.bullets { add(cueLabel("•  " + bullet, size: textSize)) }
        }
        resetScroll()
    }

    private func add(_ view: NSView) {
        body.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: body.widthAnchor).isActive = true
    }
    private func resetScroll() {
        surface.layoutSubtreeIfNeeded()
        if let document = scroll.documentView { document.scroll(NSPoint(x: 0, y: max(0, document.bounds.height - scroll.contentSize.height))) }
    }

    var creationPrompt: String {
        let destination = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Cued/Decks").path
        return "Use the installed make-cued-deck skill to prepare speaking cards. Use relevant context already available; otherwise ask what I am preparing for. Save the validated .cued.json file in \(destination). If this AI tool has authorised access to this Mac, open the file in \(Bundle.main.bundleURL.path); otherwise return the file for me to open in Cued. If the skill is not installed, explain how to install the included skill package before using it."
    }

    @objc func createDeck() {
        let alert = NSAlert()
        alert.messageText = "Create a Cued deck"
        alert.informativeText = "Install the included make-cued-deck skill using your AI tool’s Skills or Plugins controls. Then paste this prompt into a new conversation and send it yourself. Copying the prompt does not install a skill or submit a request. The included guide explains the packages."
        let text = NSTextView(frame: NSRect(x: 0, y: 0, width: 440, height: 160))
        text.string = creationPrompt; text.isEditable = false; text.isSelectable = true
        text.font = .systemFont(ofSize: 13)
        let scroller = NSScrollView(frame: text.frame)
        scroller.documentView = text; scroller.hasVerticalScroller = true
        alert.accessoryView = scroller
        alert.addButton(withTitle: "Copy prompt")
        alert.addButton(withTitle: "Cancel")
        guard let window else { return }
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            let destination = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Cued/Decks")
            do {
                try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(self.creationPrompt, forType: .string)
            } catch {
                let failure = NSAlert(); failure.messageText = "Could not prepare the deck folder"; failure.informativeText = error.localizedDescription; failure.beginSheetModal(for: window)
            }
        }
    }

    func windowDidMove(_ notification: Notification) { saveFrame() }
    func windowDidResize(_ notification: Notification) { saveFrame() }
    private func saveFrame() { if let window { defaults.set(NSStringFromRect(window.frame), forKey: "windowFrame") } }
    private func restoreFrame() {
        guard let window else { return }
        if let value = defaults.string(forKey: "windowFrame") {
            let frame = NSRectFromString(value)
            if frame.width.isFinite && frame.height.isFinite && frame.minX.isFinite && frame.minY.isFinite && frame.width >= 420 && frame.height >= 480 {
                window.setFrame(frame, display: false)
            }
        } else { window.center() }
        guard let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(window.frame) }) ?? NSScreen.main else { return }
        var frame = window.frame
        frame.size.width = min(frame.width, screen.visibleFrame.width)
        frame.size.height = min(frame.height, screen.visibleFrame.height)
        frame.origin.x = max(screen.visibleFrame.minX, min(frame.origin.x, screen.visibleFrame.maxX - frame.width))
        frame.origin.y = max(screen.visibleFrame.minY, min(frame.origin.y, screen.visibleFrame.maxY - frame.height))
        window.setFrame(frame, display: false)
    }

    func writeRenderCapture(to url: URL) throws {
        surface.layoutSubtreeIfNeeded()
        guard let bitmap = surface.bitmapImageRepForCachingDisplay(in: surface.bounds) else { throw DeckError("Could not allocate render capture.") }
        surface.cacheDisplay(in: surface.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { throw DeckError("Could not encode render capture.") }
        try png.write(to: url)
    }
}
