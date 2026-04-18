import Testing
import Foundation
@testable import pantry

@Suite("Grocery list builder")
struct GroceryListBuilderTests {

    @Test func aggregatesSameIngredientAcrossMeals() {
        let meal1 = meal("Pasta", [("Tomato", 2, "")])
        let meal2 = meal("Salad", [("tomato", 3, "")])

        let items = GroceryListBuilder.build(from: [meal1, meal2], pantry: [])

        #expect(items.count == 1)
        #expect(items.first?.normalizedName == "tomato")
        #expect(items.first?.quantity == 5)
    }

    @Test func keepsSeparateLineItemsWhenUnitsDiffer() {
        let meal1 = meal("A", [("Flour", 2, "cups")])
        let meal2 = meal("B", [("Flour", 500, "g")])

        let items = GroceryListBuilder.build(from: [meal1, meal2], pantry: [])

        #expect(items.count == 2)
    }

    @Test func marksCoveredWhenPantryHasEnough() {
        let m = meal("Stew", [("Onion", 2, "")])
        let pantry = [pantryItem("onion", 3, "")]

        let items = GroceryListBuilder.build(from: [m], pantry: pantry)

        #expect(items.count == 1)
        #expect(items.first?.isCoveredByPantry == true)
    }

    @Test func doesNotMarkCoveredWhenPantryTooShort() {
        let m = meal("Stew", [("Onion", 5, "")])
        let pantry = [pantryItem("onion", 2, "")]

        let items = GroceryListBuilder.build(from: [m], pantry: pantry)

        #expect(items.first?.isCoveredByPantry == false)
    }

    @Test func unitMismatchIsNotCovered() {
        let m = meal("Stew", [("Flour", 2, "cups")])
        let pantry = [pantryItem("flour", 500, "g")]

        let items = GroceryListBuilder.build(from: [m], pantry: pantry)

        #expect(items.first?.isCoveredByPantry == false)
    }

    @Test func unspecifiedQuantityCoveredIfPantryHasAny() {
        let m = meal("Soup", [("Salt", 0, "")])
        let pantry = [pantryItem("salt", 0, "")]

        let items = GroceryListBuilder.build(from: [m], pantry: pantry)

        #expect(items.first?.isCoveredByPantry == true)
    }

    @Test func preservesInsertionOrder() {
        let m = meal("A", [
            ("Carrot", 1, ""),
            ("Beef", 1, ""),
            ("Onion", 1, "")
        ])

        let items = GroceryListBuilder.build(from: [m], pantry: [])

        #expect(items.map(\.displayName) == ["Carrot", "Beef", "Onion"])
    }

    // MARK: - Helpers

    @MainActor
    private func meal(_ name: String, _ ingredients: [(String, Double, String)]) -> Meal {
        let m = Meal(name: name)
        m.ingredients = ingredients.map { raw, qty, unit in
            let ing = MealIngredient(rawName: raw, quantity: qty, unit: unit)
            ing.meal = m
            return ing
        }
        return m
    }

    @MainActor
    private func pantryItem(_ name: String, _ qty: Double, _ unit: String) -> PantryItem {
        PantryItem(rawName: name, quantity: qty, unit: unit)
    }
}
