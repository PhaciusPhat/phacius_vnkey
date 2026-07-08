import SwiftUI

public struct HotkeyView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var isRecording = false

    public var body: some View {
        Form {
            Section {
                HStack {
                    Text("Global toggle")
                    Spacer()
                    Button(action: { isRecording.toggle() }) {
                        Text(isRecording ? "Press a key…" : settings.globalHotkey)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isRecording ? Color.mesoneerBlue.opacity(0.15) : Color.mesoneerSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isRecording ? Color.mesoneerBlue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Press a key combination to set the global on/off toggle.")
                    .foregroundColor(.secondary)
            }

            Section {
                Text("Default: ⌃⌥V")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Hotkey")
    }

    public init() {}
}
