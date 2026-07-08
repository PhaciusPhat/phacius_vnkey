import SwiftUI
import AppKit

public struct PerAppView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var runningApps: [(bundleId: String, name: String)] = []

    public var body: some View {
        Form {
            Section {
                Toggle("Default for new apps", isOn: $settings.defaultForNewApps)
                    .tint(.mesoneerBlue)
            } header: {
                Text("Override per-application. Falls back to the default when no override is set.")
                    .foregroundColor(.secondary)
            }

            Section("Running apps") {
                if runningApps.isEmpty {
                    Text("No apps detected")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(runningApps, id: \.bundleId) { app in
                        HStack {
                            Text(app.name)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { settings.perAppEnabled[app.bundleId] ?? settings.defaultForNewApps },
                                set: { settings.perAppEnabled[app.bundleId] = $0 }
                            ))
                            .tint(.mesoneerBlue)
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Per-app")
        .onAppear { loadRunningApps() }
    }

    public init() {}

    private func loadRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName,
                      app.activationPolicy == .regular else { return nil }
                return (bundleId: bundleId, name: name)
            }
            .sorted { $0.name < $1.name }
    }
}
