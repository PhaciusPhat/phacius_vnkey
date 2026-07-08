import SwiftUI
import Bridge

/// Mesoneer brand colors.
extension Color {
    static let mesoneerBlue    = Color(red: 0.086, green: 0.341, blue: 0.878)  // #1657E0
    static let mesoneerNavy    = Color(red: 0.039, green: 0.106, blue: 0.239)  // #0A1B3D
    static let mesoneerSurface = Color(red: 0.957, green: 0.969, blue: 0.984)  // #F4F7FB
}

public struct GeneralView: View {
    @ObservedObject private var settings = AppSettings.shared

    public var body: some View {
        Form {
            Section {
                Toggle("Vietnamese typing", isOn: $settings.isEnabled)
                    .tint(.mesoneerBlue)
            } header: {
                Text("Typing behavior and defaults.")
                    .foregroundColor(.secondary)
            }

            Section {
                Picker("Input method", selection: $settings.inputMethod) {
                    Text("Telex").tag(VNInputMethod.telex)
                    Text("VNI").tag(VNInputMethod.vni)
                }
                .pickerStyle(.segmented)

                Picker("Tone placement", selection: $settings.tonePlacement) {
                    Text("Modern").tag(VNTonePlacement.modern)
                    Text("Classic").tag(VNTonePlacement.classic)
                }
                .pickerStyle(.segmented)

                Text(settings.tonePlacement == .modern ? "e.g. hòa" : "e.g. hoà")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Auto-restore English", isOn: $settings.autoRestore)
                    .tint(.mesoneerBlue)

                Toggle("Start at login", isOn: $settings.startAtLogin)
                    .tint(.mesoneerBlue)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }

    public init() {}
}
