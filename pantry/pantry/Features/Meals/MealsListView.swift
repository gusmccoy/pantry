import SwiftUI
import SwiftData

struct MealsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.name) private var meals: [Meal]
    @State private var showingNewMeal = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(meals) { meal in
                    NavigationLink(value: meal) {
                        VStack(alignment: .leading) {
                            Text(meal.name.isEmpty ? "Untitled meal" : meal.name)
                                .font(.headline)
                            Text("\(meal.ingredients?.count ?? 0) ingredients")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if meals.isEmpty {
                    ContentUnavailableView(
                        "No meals yet",
                        systemImage: "fork.knife",
                        description: Text("Add meals so you can quickly build a grocery list.")
                    )
                }
            }
            .navigationTitle("Meals")
            .navigationDestination(for: Meal.self) { meal in
                MealEditorView(meal: meal)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewMeal = true } label: {
                        Label("New meal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewMeal) {
                NewMealSheet()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(meals[i]) }
    }
}

private struct NewMealSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Meal name", text: $name)
            }
            .navigationTitle("New meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let meal = Meal(name: name)
                        modelContext.insert(meal)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
