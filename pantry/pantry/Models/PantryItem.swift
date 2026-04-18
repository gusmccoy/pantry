import Foundation
import SwiftData

@Model
final class PantryItem {
    var id: UUID = UUID()
    var rawName: String = ""
    var normalizedName: String = ""
    var quantity: Double = 0
    var unit: String = ""
    var updatedAt: Date = Date.now

    init(rawName: String = "", quantity: Double = 0, unit: String = "") {
        self.id = UUID()
        self.rawName = rawName
        self.normalizedName = IngredientName.normalize(rawName)
        self.quantity = quantity
        self.unit = unit
        self.updatedAt = .now
    }
}
