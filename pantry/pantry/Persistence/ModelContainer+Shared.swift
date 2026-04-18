import Foundation
import SwiftData

enum PantrySchema {
    static let models: [any PersistentModel.Type] = [
        Meal.self,
        MealIngredient.self,
        PantryItem.self,
        GroceryList.self,
        GroceryListItem.self
    ]

    static let schema = Schema(models)
}

// Tracks whether the production container succeeded in connecting to CloudKit.
// Read from the environment in HouseholdView to surface a sync warning.
enum SyncMode {
    case cloudKit
    case localOnly(reason: String)
}

extension ModelContainer {
    /// Creates the production container.
    ///
    /// Tries the CloudKit-backed store first with the explicit container ID.
    /// If CloudKit init fails (container not yet deployed in the portal, no
    /// iCloud account, etc.) it falls back to local-only storage so the app
    /// always boots. `syncMode` indicates which path was taken.
    static func makePantryContainer() throws -> (ModelContainer, SyncMode) {
        // Try CloudKit with explicit container ID (more reliable than .automatic).
        do {
            let config = ModelConfiguration(
                schema: PantrySchema.schema,
                cloudKitDatabase: .private("iCloud.mccoy.pantry")
            )
            let container = try ModelContainer(
                for: PantrySchema.schema,
                configurations: [config]
            )
            return (container, .cloudKit)
        } catch {
            // CloudKit failed — fall back to a plain local store so the app
            // doesn't crash. Common causes: container not yet provisioned in
            // CloudKit dashboard, iCloud not signed in, schema conflict.
            let localConfig = ModelConfiguration(
                schema: PantrySchema.schema,
                isStoredInMemoryOnly: false
            )
            let container = try ModelContainer(
                for: PantrySchema.schema,
                configurations: [localConfig]
            )
            return (container, .localOnly(reason: error.localizedDescription))
        }
    }

    /// In-memory container for previews and tests — no CloudKit, no disk.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: PantrySchema.schema, configurations: [config])
    }
}
