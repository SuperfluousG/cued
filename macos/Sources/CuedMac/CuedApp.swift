import AppKit
import Carbon
import SwiftUI

@main
struct CuedMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class CuedPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = CuedStore()
    private var panel: CuedPanel?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        store.prepareSupportFiles()
        let arguments = CommandLine.arguments
        if arguments.contains("--skip-onboarding") {
            store.isOnboardingVisible = false
        }

        let panel = CuedPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 790),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Cued"
        panel.minSize = NSSize(width: 420, height: 620)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(
            rootView: CuedRootView(
                store: store,
                windowActions: WindowActions(
                    minimise: { [weak panel] in panel?.miniaturize(nil) },
                    close: { NSApp.terminate(nil) }
                )
            )
        )
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel

        hotKey = GlobalHotKey { [weak store] in
            Task { @MainActor in store?.advance() }
        }

        for argument in arguments.dropFirst() where !argument.hasPrefix("-") {
            let url = URL(fileURLWithPath: argument)
            if FileManager.default.fileExists(atPath: url.path) {
                store.loadDeck(at: url)
                break
            }
        }
        if arguments.contains("--ghost") && store.deck != nil {
            store.isGhostMode = true
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let filename = filenames.first else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }
        store.loadDeck(at: URL(fileURLWithPath: filename))
        panel?.makeKeyAndOrderFront(nil)
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(event:reply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc private func handleURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let value = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: value),
              url.scheme == "cued",
              url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = components.queryItems?.first(where: { $0.name == "path" })?.value else {
            return
        }
        store.loadDeck(at: URL(fileURLWithPath: path))
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct WindowActions {
    let minimise: () -> Void
    let close: () -> Void
}
