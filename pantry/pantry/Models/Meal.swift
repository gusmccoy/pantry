import Foundation
import SwiftData

@Model
final class Meal {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \MealIngredient.meal)
    var ingredients: [MealIngredient]? = []

    init(name: String = "", notes: String = "") {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = .now
        self.ingredients = []
    }
}
