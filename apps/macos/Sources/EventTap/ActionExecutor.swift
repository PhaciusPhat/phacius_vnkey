import CoreGraphics
import Foundation
import Bridge

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
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
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
        event.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        up?.post(tap: .cghidEventTap)
    }
}
