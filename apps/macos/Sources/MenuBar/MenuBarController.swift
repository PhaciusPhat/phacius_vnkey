import AppKit
import Foundation
import EventTap
import Bridge

/// Manages the macOS status bar item and dropdown menu.
public final class MenuBarController {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var isEnabled: Bool = true
    private var currentMethod: VNInputMethod = .telex

    private init() {}

    // ── Public API ────────────────────────────────────────────────────────────

    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        updateIcon()
        buildMenu()
    }

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        updateIcon()
        buildMenu()
        KeyEventListener.shared.reconfigure(
            method: currentMethod,
            placement: .modern,
            enabled: enabled,
            autoRestore: true
        )
    }

    public func setMethod(_ method: VNInputMethod) {
        currentMethod = method
        buildMenu()
        KeyEventListener.shared.reconfigure(
            method: method,
            placement: .modern,
            enabled: isEnabled,
            autoRestore: true
        )
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        button.title = ""
        button.image = MenuBarIcon.make(enabled: isEnabled)
        button.imageScaling = .scaleProportionallyDown
    }

    private func buildMenu() {
        let menu = NSMenu()

        // Toggle item
        let toggleItem = NSMenuItem(
            title: isEnabled ? "Vietnamese typing   [ON]" : "Vietnamese typing   [OFF]",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // Method picker
        let telexItem = NSMenuItem(title: "Telex", action: #selector(selectTelex), keyEquivalent: "")
        telexItem.target = self
        telexItem.state = currentMethod == .telex ? .on : .off

        let vniItem = NSMenuItem(title: "VNI", action: #selector(selectVni), keyEquivalent: "")
        vniItem.target = self
        vniItem.state = currentMethod == .vni ? .on : .off

        let methodMenu = NSMenu()
        methodMenu.addItem(telexItem)
        methodMenu.addItem(vniItem)

        let methodItem = NSMenuItem(title: "Method", action: nil, keyEquivalent: "")
        methodItem.submenu = methodMenu
        menu.addItem(methodItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let quitItem = NSMenuItem(title: "Quit phacius_vnkey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func toggleEnabled() {
        setEnabled(!isEnabled)
    }

    @objc private func selectTelex() {
        setMethod(.telex)
    }

    @objc private func selectVni() {
        setMethod(.vni)
    }

    @objc private func openPreferences() {
        NotificationCenter.default.post(name: .vnkeyOpenPreferences, object: nil)
    }
}

public extension Notification.Name {
    static let vnkeyOpenPreferences = Notification.Name("io.mesoneer.phacius_vnkey.openPreferences")
}
