import SwiftUI
import ApplicationServices

public struct AboutView: View {
    @State private var hasAccessibility = false
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"

    public var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("phacius_vnkey")
                            .font(.headline)
                            .foregroundColor(.mesoneerNavy)
                        Text("Version \(version)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("🇻🇳")
                        .font(.largeTitle)
                }
            }

            Section("Accessibility") {
                HStack {
                    Image(systemName: hasAccessibility ? "checkmark.shield.fill" : "xmark.shield.fill")
                        .foregroundColor(hasAccessibility ? .green : .red)
                    Text(hasAccessibility ? "Permission granted" : "Permission required")
                    Spacer()
                    if !hasAccessibility {
                        Button("Grant Access") {
                            openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.mesoneerBlue)
                    }
                }
            }

            Section("Links") {
                Link("mesoneer.io", destination: URL(string: "https://mesoneer.io")!)
                Link("Report an issue", destination: URL(string: "https://github.com/PhaciusPhat/phacius_vnkey/issues")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("About")
        .onAppear { checkAccessibility() }
    }

    public init() {}

    private func checkAccessibility() {
        hasAccessibility = AXIsProcessTrusted()
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
