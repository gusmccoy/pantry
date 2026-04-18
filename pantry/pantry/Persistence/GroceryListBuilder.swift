import Foundation

enum GroceryListBuilder {
    struct DraftItem: Equatable {
        var normalizedName: String
        var displayName: String
        var quantity: Double
        var unit: String
        var isCoveredByPantry: Bool
    }

    static func build(
        from meals: [Meal],
        pantry: [PantryItem]
    ) -> [DraftItem] {
        let pantryByName = Dictionary(
            grouping: pantry,
            by: \.normalizedName
        )

        var byKey: [String: DraftItem] = [:]
        var order: [String] = []

        for meal in meals {
            for ing in meal.ingredients ?? [] {
                let key = "\(ing.normalizedName)|\(ing.unit)"
                if var existing = byKey[key] {
                    existing.quantity += ing.quantity
                    byKey[key] = existing
                } else {
                    let covered = covers(
                        pantryItems: pantryByName[ing.normalizedName] ?? [],
                        unit: ing.unit,
                        quantity: ing.quantity
                    )
                    byKey[key] = DraftItem(
                        normalizedName: ing.normalizedName,
                        displayName: ing.rawName,
                        quantity: ing.quantity,
                        unit: ing.unit,
                        isCoveredByPantry: covered
                    )
                    order.append(key)
                }
            }
        }

        return order.compactMap { byKey[$0] }
    }

    private static func covers(
        pantryItems: [PantryItem],
        unit: String,
        quantity: Double
    ) -> Bool {
        // Only consider pantry items with a matching unit. No unit conversion in v1.
        let matchingUnit = pantryItems.filter { $0.unit == unit }
        let total = matchingUnit.reduce(0.0) { $0 + $1.quantity }

        if quantity <= 0 {
            // Ingredient has no specified quantity — covered if pantry has any entry at all.
            return !pantryItems.isEmpty
        }
        return total >= quantity
    }
}
