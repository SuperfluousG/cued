import AppKit
import CuedCore

final class CueDocumentView: NSView {
    override var isFlipped: Bool { true }
}

final class CueView: NSView {
    var onDrop: ((URL) -> Void)?
    var ghost = false { didSet { needsDisplay = true } }
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL])
    }
    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    override func draw(_ dirtyRect: NSRect) {
        (ghost ? NSColor.clear : NSColor(calibratedWhite: 0.125, alpha: 1)).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12).fill()
        NSColor(calibratedWhite: 0.6, alpha: ghost ? 0.45 : 0.18).setStroke()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 12, yRadius: 12).stroke()
    }

    private func droppedURL(_ sender: NSDraggingInfo) -> URL? {
        let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
        return urls?.count == 1 ? urls?.first : nil
    }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { droppedURL(sender) == nil ? [] : .copy }
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { droppedURL(sender) != nil }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = droppedURL(sender) else { return false }
        onDrop?(url)
        return true
    }
}

final class CueWindow: NSWindow {
    var playbackKey: ((UInt16) -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Space activates the focused native control. The playback shortcut is
        // only used when focus is on the card/window itself.
        if event.type == .keyDown && event.keyCode == 49 && firstResponder is NSControl {
            super.sendEvent(event)
            return
        }
        if event.type == .keyDown, attachedSheet == nil,
           modifiers.intersection([.command, .control, .option]).isEmpty,
           !(firstResponder is NSTextView), [49, 123, 124].contains(event.keyCode) {
            playbackKey?(event.keyCode)
            return
        }
        super.sendEvent(event)
    }
}

func cueLabel(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular, muted: Bool = false) -> NSTextField {
    let field = NSTextField(wrappingLabelWithString: text)
    field.font = .systemFont(ofSize: size, weight: weight)
    field.textColor = muted ? NSColor(calibratedWhite: 0.72, alpha: 1) : .white
    field.isSelectable = false
    field.setContentCompressionResistancePriority(.required, for: .vertical)
    return field
}
