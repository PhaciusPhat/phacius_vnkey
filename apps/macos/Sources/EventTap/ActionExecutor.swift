import CoreGraphics
import Foundation
import Bridge

/// Sentinel written into `eventSourceUserData` of every event we synthesize, so
/// the tap callback can recognize and ignore our own injected keystrokes rather
/// than feeding them back into the engine. ("VNKEY" in ASCII.)
let vnkeySyntheticMarker: Int64 = 0x0056_4E4B_4559

/// Translates `VNEditAction`s into synthesized `CGEvent`s.
public final class ActionExecutor {
    /// Execute the given actions. `source` is used to create synthetic events.
    public static func execute(_ actions: [VNEditAction], source: CGEventSource?) {
        for action in actions {
            switch action {
            case .backspace(let count):
                synthesizeBackspace(count: Int(count), source: source)
            case .insert(let text):
                synthesizeInsert(text: text, source: source)
            }
        }
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private static func synthesizeBackspace(count: Int, source: CGEventSource?) {
        for _ in 0..<count {
            let down = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
            let up   = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
            post(down)
            post(up)
        }
    }

    private static func synthesizeInsert(text: String, source: CGEventSource?) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else { return }
        let scalars = Array(text.unicodeScalars)
        var utf16: [UniChar] = []
        for scalar in scalars {
            let ch = Character(scalar)
            utf16.append(contentsOf: String(ch).utf16)
        }
        event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        post(event)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        post(up)
    }

    /// Tag the event as synthetic and post it, so the tap callback ignores it
    /// instead of routing it back through the engine (which would corrupt the
    /// composition buffer).
    private static func post(_ event: CGEvent?) {
        guard let event else { return }
        event.setIntegerValueField(.eventSourceUserData, value: vnkeySyntheticMarker)
        event.post(tap: .cghidEventTap)
    }
}
