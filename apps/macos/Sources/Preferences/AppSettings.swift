import Foundation
import Bridge

private let suiteName = "io.mesoneer.phacius_vnkey"

/// Centralized settings backed by UserDefaults.
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let defaults: UserDefaults

    @Published public var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: "isEnabled") }
    }
    @Published public var inputMethod: VNInputMethod {
        didSet { defaults.set(Int(inputMethod.rawValue), forKey: "inputMethod") }
    }
    @Published public var tonePlacement: VNTonePlacement {
        didSet { defaults.set(Int(tonePlacement.rawValue), forKey: "tonePlacement") }
    }
    @Published public var autoRestore: Bool {
        didSet { defaults.set(autoRestore, forKey: "autoRestore") }
    }
    @Published public var startAtLogin: Bool {
        didSet { defaults.set(startAtLogin, forKey: "startAtLogin") }
    }
    @Published public var globalHotkey: String {
        didSet { defaults.set(globalHotkey, forKey: "globalHotkey") }
    }
    @Published public var defaultForNewApps: Bool {
        didSet { defaults.set(defaultForNewApps, forKey: "defaultForNewApps") }
    }
    /// Map of bundle ID → enabled override. nil means "use default".
    @Published public var perAppEnabled: [String: Bool] {
        didSet {
            if let data = try? JSONEncoder().encode(perAppEnabled) {
                defaults.set(data, forKey: "perAppEnabled")
            }
        }
    }

    private init() {
        defaults = UserDefaults(suiteName: suiteName) ?? .standard

        isEnabled       = defaults.object(forKey: "isEnabled")      as? Bool ?? true
        inputMethod     = VNInputMethod(rawValue: Int32(defaults.integer(forKey: "inputMethod"))) ?? .telex
        tonePlacement   = VNTonePlacement(rawValue: Int32(defaults.integer(forKey: "tonePlacement"))) ?? .modern
        autoRestore     = defaults.object(forKey: "autoRestore")     as? Bool ?? true
        startAtLogin    = defaults.object(forKey: "startAtLogin")    as? Bool ?? false
        globalHotkey    = defaults.string(forKey: "globalHotkey") ?? "⌃⌥V"
        defaultForNewApps = defaults.object(forKey: "defaultForNewApps") as? Bool ?? true

        if let data = defaults.data(forKey: "perAppEnabled"),
           let map = try? JSONDecoder().decode([String: Bool].self, from: data) {
            perAppEnabled = map
        } else {
            perAppEnabled = [:]
        }
    }
}
