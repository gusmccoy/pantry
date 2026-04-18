import Foundation
import SwiftData

@Model
final class MealIngredient {
    var id: UUID = UUID()
    var rawName: String = ""
    var normalizedName: String = ""
    var quantity: Double = 0
    var unit: String = ""
    var meal: Meal?

    init(rawName: String = "", quantity: Double = 0, unit: String = "") {
        self.id = UUID()
        self.rawName = rawName
        self.normalizedName = IngredientName.normalize(rawName)
        self.quantity = quantity
        self.unit = unit
    }
}
