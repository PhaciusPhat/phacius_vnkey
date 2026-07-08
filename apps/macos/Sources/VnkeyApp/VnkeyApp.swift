import AppKit
import SwiftUI
import Foundation
import Bridge
import EventTap
import MenuBar
import Preferences

@main
struct VnkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No window scene — we're a menu-bar-only app.
        Settings {
            PreferencesWindow()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindow: NSWindow?
    private var perAppObserver: NSObjectProtocol?
    private var hotkeyTap: CFMachPort?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock — menu-bar only.
        NSApp.setActivationPolicy(.accessory)

        // Start menu bar.
        MenuBarController.shared.setup()

        // Start event tap.
        let settings = AppSettings.shared
        KeyEventListener.shared.reconfigure(
            method: settings.inputMethod,
            placement: settings.tonePlacement,
            enabled: settings.isEnabled,
            autoRestore: settings.autoRestore
        )
        KeyEventListener.shared.start()

        // Observe settings changes and push to engine.
        observeSettings()

        // Per-app tracking.
        setupPerAppTracking()

        // Open Preferences on notification.
        NotificationCenter.default.addObserver(
            forName: .vnkeyOpenPreferences,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openPreferences()
        }
    }

    // ── Per-app tracking ──────────────────────────────────────────────────────

    private func setupPerAppTracking() {
        let ws = NSWorkspace.shared
        perAppObserver = ws.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handleAppActivation(note)
        }
    }

    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }

        let settings = AppSettings.shared
        let enabled = settings.perAppEnabled[bundleId] ?? settings.defaultForNewApps

        // Reset composition when switching apps.
        KeyEventListener.shared.resetComposition()

        KeyEventListener.shared.reconfigure(
            method: settings.inputMethod,
            placement: settings.tonePlacement,
            enabled: enabled,
            autoRestore: settings.autoRestore
        )
        MenuBarController.shared.setEnabled(enabled)
    }

    // ── Settings observation ──────────────────────────────────────────────────

    private var settingsCancellables: [Any] = []

    private func observeSettings() {
        // Watch isEnabled / inputMethod / tonePlacement / autoRestore.
        let token = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pushSettingsToEngine()
        }
        settingsCancellables.append(token)
    }

    private func pushSettingsToEngine() {
        let s = AppSettings.shared
        KeyEventListener.shared.reconfigure(
            method: s.inputMethod,
            placement: s.tonePlacement,
            enabled: s.isEnabled,
            autoRestore: s.autoRestore
        )
    }

    // ── Preferences window ────────────────────────────────────────────────────

    private func openPreferences() {
        if let win = preferencesWindow {
            win.makeKeyAndOrderFront(nil)
            return
        }
        let view = PreferencesWindow()
        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.title = "phacius_vnkey"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.center()
        preferencesWindow = win
        win.makeKeyAndOrderFront(nil)
    }
}
