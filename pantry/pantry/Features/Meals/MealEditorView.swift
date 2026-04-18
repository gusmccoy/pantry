import SwiftUI
import SwiftData

struct MealEditorView: View {
    @Bindable var meal: Meal
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $meal.name)
                TextField("Notes", text: $meal.notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section("Ingredients") {
                ForEach(meal.ingredients ?? []) { ing in
                    IngredientRowEditor(ingredient: ing)
                }
                .onDelete(perform: deleteIngredient)

                Button {
                    addIngredient()
                } label: {
                    Label("Add ingredient", systemImage: "plus")
                }
            }
        }
        .navigationTitle(meal.name.isEmpty ? "Meal" : meal.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func addIngredient() {
        let ing = MealIngredient(rawName: "")
        ing.meal = meal
        if meal.ingredients == nil { meal.ingredients = [] }
        meal.ingredients?.append(ing)
        modelContext.insert(ing)
    }

    private func deleteIngredient(at offsets: IndexSet) {
        guard var list = meal.ingredients else { return }
        for i in offsets {
            modelContext.delete(list[i])
        }
        list.remove(atOffsets: offsets)
        meal.ingredients = list
    }
}

private struct IngredientRowEditor: View {
    @Bindable var ingredient: MealIngredient

    var body: some View {
        HStack {
            TextField("Ingredient", text: Binding(
                get: { ingredient.rawName },
                set: {
                    ingredient.rawName = $0
                    ingredient.normalizedName = IngredientName.normalize($0)
                }
            ))
            .textFieldStyle(.roundedBorder)
            Spacer()
            QuantityField(
                quantity: $ingredient.quantity,
                unit: $ingredient.unit
            )
        }
    }
}
