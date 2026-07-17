import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum CuedTheme {
    static let window = Color(hex: 0x1E1E1E)
    static let surface = Color(hex: 0x262626)
    static let foreground = Color(hex: 0xF8F7F4)
    static let muted = Color(hex: 0xA6A6A6)
    static let border = Color(hex: 0x3A3A3A)
    static let borderBright = Color(hex: 0x5A5A5A)
    static let claude = Color(hex: 0xE87A50)
}

struct CuedRootView: View {
    @ObservedObject var store: CuedStore
    let windowActions: WindowActions

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(store.isGhostMode ? Color.clear : CuedTheme.window)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(store.isGhostMode ? CuedTheme.muted.opacity(0.5) : CuedTheme.border, lineWidth: 1)
                }

            VStack(spacing: 0) {
                topBar
                    .frame(height: 46)
                Group {
                    if store.deck == nil {
                        LandingView(store: store)
                    } else {
                        PlayerView(store: store)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 10)

            if store.isSettingsVisible {
                SettingsPanel(store: store)
                    .padding(.leading, 10)
                    .padding(.top, 52)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(20)
            }
        }
        .frame(minWidth: 420, minHeight: 620)
        .foregroundStyle(CuedTheme.foreground)
        .background(Color.clear)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil, perform: receiveDrop)
        .onKeyPress(.space) {
            guard store.deck != nil else { return .ignored }
            store.advance()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            guard store.deck != nil else { return .ignored }
            store.back()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard store.deck != nil else { return .ignored }
            store.advance()
            return .handled
        }
        .alert(
            "Cued",
            isPresented: Binding(
                get: { store.alertMessage != nil },
                set: { if !$0 { store.alertMessage = nil } }
            ),
            actions: {
                Button("OK") { store.alertMessage = nil }
            },
            message: {
                Text(store.alertMessage ?? "")
            }
        )
        .sheet(isPresented: $store.isOnboardingVisible) {
            OnboardingView(store: store)
        }
    }

    private var topBar: some View {
        ZStack {
            WindowDragHandle()
            HStack(spacing: 2) {
                ChromeButton(symbol: "gearshape", tooltip: "Settings") {
                    withAnimation(.easeOut(duration: 0.12)) {
                        store.isSettingsVisible.toggle()
                    }
                }
                Spacer()
                Text(store.positionText)
                    .font(.system(size: 12))
                    .foregroundStyle(CuedTheme.muted)
                Spacer()
                ChromeButton(symbol: "minus", tooltip: "Minimise", action: windowActions.minimise)
                Button(action: store.toggleGhost) {
                    GhostIcon()
                        .fill(CuedTheme.foreground)
                        .overlay {
                            GhostEyes()
                                .fill(store.isGhostMode ? Color.black.opacity(0.75) : CuedTheme.window)
                        }
                        .frame(width: 28, height: 28)
                        .frame(width: 64, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Ghost")
                ChromeButton(symbol: "xmark", tooltip: "Close", action: windowActions.close)
            }
            .opacity(store.isGhostMode ? 0.5 : 1)
            .onHover { hovering in
                if store.isGhostMode {
                    NSCursor.arrow.set()
                }
            }
        }
    }

    private func receiveDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let value = item as? URL {
                url = value
            } else {
                url = nil
            }
            if let url {
                Task { @MainActor in store.loadDeck(at: url) }
            }
        }
        return true
    }
}

private struct LandingView: View {
    @ObservedObject var store: CuedStore

    var body: some View {
        HStack(spacing: 0) {
            Button(action: store.chooseDeck) {
                VStack(spacing: 22) {
                    Text("Open")
                        .font(.system(size: 26, weight: .semibold))
                    Image(systemName: "folder")
                        .font(.system(size: 70, weight: .light))
                }
                .frame(width: 170, height: 230)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Open a cue deck")

            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.57), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 2, height: 190)
            .padding(.horizontal, 10)

            VStack(spacing: 22) {
                Text("Create")
                    .font(.system(size: 26, weight: .semibold))
                HStack(spacing: 20) {
                    ProviderButton(resource: "openai", tooltip: "Create with ChatGPT") {
                        store.openProvider(.openAI)
                    }
                    ProviderButton(resource: "claude", tooltip: "Create with Claude Cowork", tint: CuedTheme.claude) {
                        store.openProvider(.claude)
                    }
                }
            }
            .frame(width: 230)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(store.isGhostMode ? store.ghostTextOpacity : 1)
    }
}

private struct ProviderButton: View {
    let resource: String
    let tooltip: String
    var tint: Color = CuedTheme.foreground
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BundleSVGImage(name: resource)
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .frame(width: 82, height: 82)
                .background(CuedTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(CuedTheme.border, lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

private struct PlayerView: View {
    @ObservedObject var store: CuedStore
    @State private var cardOffset = 0.0
    @State private var cardOpacity = 1.0
    @State private var isTransitioning = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if !store.isFinalCard && !store.isGhostMode {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(CuedTheme.window)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x454545), lineWidth: 1))
                    .frame(height: 22)
                    .padding(.horizontal, 24)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(CuedTheme.window)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(CuedTheme.borderBright, lineWidth: 1))
                    .frame(height: 22)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            if let card = store.currentCard {
                VStack(alignment: .leading, spacing: 0) {
                    Text(card.title)
                        .font(.system(size: 28, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(card.blocks.enumerated()), id: \.offset) { _, block in
                            CueBlockView(block: block, textSize: store.cueTextSize)
                        }
                    }
                    .padding(.horizontal, 8)

                    Spacer(minLength: 12)

                    HStack(spacing: 10) {
                        Button(action: store.back) {
                            Label("Back", systemImage: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 84, height: 46)
                                .background(CuedTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0x505050), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(!store.canGoBack)
                        .opacity(store.canGoBack ? 1 : 0.35)
                        .help("Previous card")

                        Button(action: advanceAnimated) {
                            HStack {
                                Text(store.nextTitle)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 17))
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(CuedTheme.window, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(CuedTheme.borderBright, lineWidth: 1))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(isTransitioning)
                    }
                    .padding(.top, 18)
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 20)
                .background(store.isGhostMode ? Color.clear : CuedTheme.window)
                .opacity(store.isGhostMode ? store.ghostTextOpacity : cardOpacity)
                .shadow(color: store.isGhostMode ? .black : .clear, radius: 3, x: 1, y: 1)
                .offset(y: cardOffset)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func advanceAnimated() {
        guard !isTransitioning else { return }
        if store.reducedMotion {
            store.advance()
            return
        }

        isTransitioning = true
        withAnimation(.easeIn(duration: 0.125)) {
            cardOffset = 42
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
            store.advance()
            cardOffset = -18
            cardOpacity = 0
            withAnimation(.easeOut(duration: 0.15)) {
                cardOffset = 0
                cardOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isTransitioning = false
            }
        }
    }
}

private struct CueBlockView: View {
    let block: CueBlock
    let textSize: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(block.heading)
                .font(.system(size: max(16, textSize - 1), weight: .semibold))
            ForEach(Array(block.bullets.enumerated()), id: \.offset) { _, bullet in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.system(size: textSize))
                        .frame(width: 14, alignment: .leading)
                    Text(bullet)
                        .font(.system(size: textSize))
                        .lineSpacing(textSize * 0.32)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, 3)
    }
}

private struct SettingsPanel: View {
    @ObservedObject var store: CuedStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cue text")
                .font(.system(size: 13))
                .foregroundStyle(CuedTheme.muted)
            Slider(value: $store.cueTextSize, in: 17...26, step: 1)

            Text("Ghost text")
                .font(.system(size: 13))
                .foregroundStyle(CuedTheme.muted)
                .padding(.top, 4)
            Slider(value: $store.ghostTextOpacity, in: 0.65...1, step: 0.05)

            Toggle("Reduced motion", isOn: $store.reducedMotion)
                .toggleStyle(.checkbox)

            Text("Advance: Control + Space")
                .font(.system(size: 12))
                .foregroundStyle(CuedTheme.muted)
                .padding(.top, 4)

            Divider().overlay(CuedTheme.border)

            Button("Reinstall ChatGPT skill") { store.reinstallOpenAISkill() }
                .buttonStyle(.plain)
                .foregroundStyle(CuedTheme.foreground)
            Button("Show Claude skill package") { store.revealClaudeSkill() }
                .buttonStyle(.plain)
                .foregroundStyle(CuedTheme.foreground)
        }
        .padding(16)
        .frame(width: 270, alignment: .leading)
        .background(CuedTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CuedTheme.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }
}

private struct OnboardingView: View {
    @ObservedObject var store: CuedStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                GhostIcon()
                    .fill(CuedTheme.window)
                    .overlay(GhostEyes().fill(CuedTheme.foreground))
                    .frame(width: 38, height: 38)
                Text("Cued is ready")
                    .font(.system(size: 24, weight: .semibold))
            }

            StatusRow(
                complete: store.supportStatus.openAISkillInstalled,
                title: "ChatGPT skill",
                detail: store.supportStatus.openAISkillInstalled ? "Installed for this Mac user" : "Could not be installed"
            )
            StatusRow(
                complete: store.supportStatus.claudePackageReady,
                title: "Claude skill",
                detail: "Upload once through Customize → Skills"
            )

            if let error = store.supportStatus.error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Show Claude package") { store.revealClaudeSkill() }
                    .disabled(!store.supportStatus.claudePackageReady)
                Spacer()
                Button("Continue") { store.completeOnboarding() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 430)
    }
}

private struct StatusRow: View {
    let complete: Bool
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: complete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(complete ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold)
                Text(detail).font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
    }
}

private struct ChromeButton: View {
    let symbol: String
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CuedTheme.muted)
                .frame(width: 44, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

private struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

private struct BundleSVGImage: View {
    let name: String

    var body: some View {
        if let url = Bundle.module.url(forResource: name, withExtension: "svg", subdirectory: "Resources"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
        }
    }
}

private struct GhostIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 28
        let sy = rect.height / 28
        var path = Path()
        path.move(to: CGPoint(x: 14 * sx, y: 2 * sy))
        path.addCurve(to: CGPoint(x: 2 * sx, y: 14 * sy), control1: CGPoint(x: 7.4 * sx, y: 2 * sy), control2: CGPoint(x: 2 * sx, y: 7.4 * sy))
        path.addLine(to: CGPoint(x: 2 * sx, y: 26 * sy))
        path.addLine(to: CGPoint(x: 7 * sx, y: 21 * sy))
        path.addLine(to: CGPoint(x: 11.5 * sx, y: 26 * sy))
        path.addLine(to: CGPoint(x: 16 * sx, y: 21 * sy))
        path.addLine(to: CGPoint(x: 21 * sx, y: 26 * sy))
        path.addLine(to: CGPoint(x: 26 * sx, y: 21 * sy))
        path.addLine(to: CGPoint(x: 26 * sx, y: 14 * sy))
        path.addCurve(to: CGPoint(x: 14 * sx, y: 2 * sy), control1: CGPoint(x: 26 * sx, y: 7.4 * sy), control2: CGPoint(x: 20.6 * sx, y: 2 * sy))
        path.closeSubpath()
        return path
    }
}

private struct GhostEyes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(ellipseIn: CGRect(x: rect.width * 0.286, y: rect.height * 0.357, width: rect.width * 0.143, height: rect.height * 0.214))
        path.addEllipse(in: CGRect(x: rect.width * 0.607, y: rect.height * 0.357, width: rect.width * 0.143, height: rect.height * 0.214))
        return path
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
