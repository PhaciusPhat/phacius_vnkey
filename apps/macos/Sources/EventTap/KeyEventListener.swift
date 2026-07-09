import ApplicationServices
import CoreGraphics
import Foundation
import Bridge

/// Installs a CGEventTap and routes keystrokes through the Vietnamese engine.
public final class KeyEventListener {
    public static let shared = KeyEventListener()

    private let engine: VNEngine
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {
        engine = VNEngine()
    }

    // ── Public API ────────────────────────────────────────────────────────────

    public func start() {
        guard checkAccessibilityPermission() else { return }

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
            guard let userInfo else { return Unmanaged.passRetained(event) }
            let listener = Unmanaged<KeyEventListener>.fromOpaque(userInfo).takeUnretainedValue()
            return listener.handleEvent(proxy: proxy, type: type, event: event)
        }

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passRetained(self).toOpaque()
        )

        guard let tap = eventTap else {
            print("[VnkeyApp] Failed to create CGEventTap — Accessibility permission required")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    public func reconfigure(method: VNInputMethod,
                             placement: VNTonePlacement,
                             enabled: Bool,
                             autoRestore: Bool) {
        engine.setConfig(method: method, placement: placement,
                         enabled: enabled, autoRestore: autoRestore)
    }

    /// Call this on mouse click or focus change to reset composition state.
    public func resetComposition() {
        engine.reset()
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private func handleEvent(proxy: CGEventTapProxy,
                              type: CGEventType,
                              event: CGEvent) -> Unmanaged<CGEvent>? {
        // macOS disables the tap if a callback runs too long (we synthesize
        // several events per keystroke) or on certain user input. Re-enable it,
        // otherwise typing silently stops working for good.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        }

        guard type == .keyDown else { return Unmanaged.passRetained(event) }

        // Ignore events we injected ourselves — posting to `.cghidEventTap`
        // re-delivers them to this same tap, and re-processing them would
        // corrupt the composition buffer on every keystroke.
        if event.getIntegerValueField(.eventSourceUserData) == vnkeySyntheticMarker {
            return Unmanaged.passRetained(event)
        }

        // Extract the character from the event.
        var length = 1
        var chars = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)

        guard length > 0, let scalar = Unicode.Scalar(chars[0]) else {
            return Unmanaged.passRetained(event)
        }

        let ch = Character(scalar)
        let actions = engine.process(character: ch, isBoundary: false)

        if actions.isEmpty {
            return Unmanaged.passRetained(event) // pass through
        }

        // Swallow the original event and execute synthetic actions.
        let source = CGEventSource(stateID: .hidSystemState)
        ActionExecutor.execute(actions, source: source)
        return nil // swallowed
    }

    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
