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

extension ModelContainer {
    /// Production container: CloudKit-backed private DB plus a shared DB
    /// configuration so participants see records accepted via CKShare.
    ///
    /// The CloudKit container identifier is read from the app's iCloud
    /// entitlement (the `com.apple.developer.icloud-container-identifiers`
    /// array in `pantry.entitlements`). SwiftData picks it up automatically
    /// when `cloudKitDatabase` is set to `.automatic`.
    static func makePantryContainer() throws -> ModelContainer {
        let privateConfig = ModelConfiguration(
            "Private",
            schema: PantrySchema.schema,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(
            for: PantrySchema.schema,
            configurations: [privateConfig]
        )
    }

    /// In-memory container for previews and tests. No CloudKit.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: PantrySchema.schema,
            configurations: [config]
        )
    }
}
