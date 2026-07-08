import SwiftUI

public struct PreferencesWindow: View {
    public enum Section: String, CaseIterable, Identifiable {
        case general  = "General"
        case hotkey   = "Hotkey"
        case perApp   = "Per-app"
        case about    = "About"

        public var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "keyboard"
            case .hotkey:  return "command"
            case .perApp:  return "apps.iphone"
            case .about:   return "info.circle"
            }
        }
    }

    @State private var selection: Section? = .general

    public var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
            .listStyle(.sidebar)
        } detail: {
            switch selection {
            case .general, .none:
                GeneralView()
            case .hotkey:
                HotkeyView()
            case .perApp:
                PerAppView()
            case .about:
                AboutView()
            }
        }
        .frame(width: 620, height: 420)
        .background(Color.mesoneerSurface)
    }

    public init() {}
}
