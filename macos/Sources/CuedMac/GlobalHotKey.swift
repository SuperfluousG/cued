import Carbon
import Foundation

final class GlobalHotKey {
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let action: () -> Void

    init?(action: @escaping () -> Void) {
        self.action = action

        var specification = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let instance = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { instance.action() }
                return noErr
            },
            1,
            &specification,
            pointer,
            &eventHandler
        )
        guard result == noErr else { return nil }

        var identifier = EventHotKeyID(signature: fourCharacterCode("CUED"), id: 1)
        let registration = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        guard registration == noErr else {
            if let eventHandler { RemoveEventHandler(eventHandler) }
            return nil
        }
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    private func fourCharacterCode(_ value: String) -> OSType {
        value.utf8.reduce(0) { ($0 << 8) + OSType($1) }
    }
}

