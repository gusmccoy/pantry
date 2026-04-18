import SwiftUI
import SwiftData

@main
struct pantryApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    let container: ModelContainer
    let syncMode: SyncMode

    init() {
        do {
            (container, syncMode) = try ModelContainer.makePantryContainer()
        } catch {
            fatalError("Could not create local ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.syncMode, syncMode)
        }
        .modelContainer(container)
    }
}

// MARK: - SyncMode environment key

private struct SyncModeKey: EnvironmentKey {
    static let defaultValue: SyncMode = .cloudKit
}

extension EnvironmentValues {
    var syncMode: SyncMode {
        get { self[SyncModeKey.self] }
        set { self[SyncModeKey.self] = newValue }
    }
}
