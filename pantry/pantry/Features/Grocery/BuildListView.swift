import SwiftUI
import SwiftData

struct BuildListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Meal.name) private var allMeals: [Meal]
    @Query private var pantry: [PantryItem]

    @State private var title = defaultTitle()
    @State private var pickedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("List") {
                    TextField("Title", text: $title)
                }
                Section("Pick meals") {
                    if allMeals.isEmpty {
                        Text("Add meals first.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(allMeals) { meal in
                        Button {
                            toggle(meal)
                        } label: {
                            HStack {
                                Image(systemName: pickedIDs.contains(meal.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(pickedIDs.contains(meal.id) ? Color.accentColor : Color.secondary)
                                VStack(alignment: .leading) {
                                    Text(meal.name.isEmpty ? "Untitled meal" : meal.name)
                                    Text("\(meal.ingredients?.count ?? 0) ingredients")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("New grocery list")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(pickedIDs.isEmpty)
                }
            }
        }
    }

    private func toggle(_ meal: Meal) {
        if pickedIDs.contains(meal.id) {
            pickedIDs.remove(meal.id)
        } else {
            pickedIDs.insert(meal.id)
        }
    }

    private func create() {
        let selected = allMeals.filter { pickedIDs.contains($0.id) }
        let drafts = GroceryListBuilder.build(from: selected, pantry: pantry)

        let list = GroceryList(title: title)
        list.selectedMeals = selected
        modelContext.insert(list)

        for d in drafts {
            let item = GroceryListItem(
                normalizedName: d.normalizedName,
                displayName: d.displayName,
                quantity: d.quantity,
                unit: d.unit,
                isCoveredByPantry: d.isCoveredByPantry
            )
            item.list = list
            modelContext.insert(item)
            if list.items == nil { list.items = [] }
            list.items?.append(item)
        }
        dismiss()
    }

    private static func defaultTitle() -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return "Week of \(df.string(from: .now))"
    }
}
