import Foundation
import VnkeyC

// ── Swift-friendly types mirroring the Rust core ──────────────────────────────

public enum VNInputMethod: Int32, CaseIterable {
    case telex = 0
    case vni = 1

    public var displayName: String {
        switch self {
        case .telex: return "Telex"
        case .vni:   return "VNI"
        }
    }
}

public enum VNTonePlacement: Int32 {
    case modern  = 0
    case classic = 1
}

public enum VNEditAction: Equatable {
    case backspace(count: UInt8)
    case insert(String)
}

// ── Engine wrapper ────────────────────────────────────────────────────────────

/// Thread-unsafe Swift wrapper around the Rust engine.
/// All calls must happen on the same thread (the CGEventTap callback thread).
public final class VNEngine {
    private var handle: OpaquePointer?

    public init(method: VNInputMethod = .telex,
                placement: VNTonePlacement = .modern,
                enabled: Bool = true,
                autoRestore: Bool = true) {
        var cfg = makeConfig(method: method, placement: placement,
                             enabled: enabled, autoRestore: autoRestore)
        handle = vnkey_engine_new(cfg)
    }

    deinit {
        if let h = handle {
            vnkey_engine_free(h)
        }
    }

    public func setConfig(method: VNInputMethod,
                          placement: VNTonePlacement,
                          enabled: Bool,
                          autoRestore: Bool) {
        guard let h = handle else { return }
        var cfg = makeConfig(method: method, placement: placement,
                             enabled: enabled, autoRestore: autoRestore)
        vnkey_engine_set_config(h, cfg)
    }

    public func process(character: Character, isBoundary: Bool = false) -> [VNEditAction] {
        guard let h = handle,
              let scalar = character.unicodeScalars.first else { return [] }
        let result = vnkey_engine_process(h, scalar.value, isBoundary)
        return parseResult(result)
    }

    public func reset() {
        guard let h = handle else { return }
        vnkey_engine_reset(h)
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private func parseResult(_ result: VnkeyResult) -> [VNEditAction] {
        var actions: [VNEditAction] = []
        let count = Int(result.action_count)
        withUnsafePointer(to: result.actions) { ptr in
            ptr.withMemoryRebound(to: VnkeyAction.self, capacity: 4) { buf in
                for i in 0..<min(count, 4) {
                    let action = buf[i]
                    switch action.kind {
                    case VnkeyActionKindBackspace:
                        actions.append(.backspace(count: action.count))
                    case VnkeyActionKindInsert:
                        let text = withUnsafePointer(to: action.text) { textPtr in
                            textPtr.withMemoryRebound(to: UInt8.self, capacity: 64) { bytes in
                                var len = 0
                                while len < 64 && bytes[len] != 0 { len += 1 }
                                return String(bytes: UnsafeBufferPointer(start: bytes, count: len),
                                             encoding: .utf8) ?? ""
                            }
                        }
                        if !text.isEmpty { actions.append(.insert(text)) }
                    default:
                        break
                    }
                }
            }
        }
        return actions
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

private func makeConfig(method: VNInputMethod,
                        placement: VNTonePlacement,
                        enabled: Bool,
                        autoRestore: Bool) -> VnkeyConfig {
    var cfg = VnkeyConfig()
    cfg.method = VnkeyInputMethod(rawValue: UInt32(method.rawValue))
    cfg.placement = VnkeyTonePlacement(rawValue: UInt32(placement.rawValue))
    cfg.enabled = enabled
    cfg.auto_restore = autoRestore
    return cfg
}
