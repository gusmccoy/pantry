import SwiftUI
import SwiftData

@main
struct pantryApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer.makePantryContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
