import Foundation
import SwiftData

@Model
final class GroceryListItem {
    var id: UUID = UUID()
    var normalizedName: String = ""
    var displayName: String = ""
    var quantity: Double = 0
    var unit: String = ""
    var isCoveredByPantry: Bool = false
    var isChecked: Bool = false
    var list: GroceryList?

    init(
        normalizedName: String = "",
        displayName: String = "",
        quantity: Double = 0,
        unit: String = "",
        isCoveredByPantry: Bool = false
    ) {
        self.id = UUID()
        self.normalizedName = normalizedName
        self.displayName = displayName
        self.quantity = quantity
        self.unit = unit
        self.isCoveredByPantry = isCoveredByPantry
        self.isChecked = false
    }
}
