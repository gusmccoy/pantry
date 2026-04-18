import Foundation
import SwiftData

@Model
final class GroceryList {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.now
    var selectedMeals: [Meal]? = []

    @Relationship(deleteRule: .cascade, inverse: \GroceryListItem.list)
    var items: [GroceryListItem]? = []

    init(title: String = "") {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.selectedMeals = []
        self.items = []
    }
}
