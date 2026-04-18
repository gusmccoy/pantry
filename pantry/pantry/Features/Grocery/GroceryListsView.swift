import SwiftUI
import SwiftData

struct GroceryListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroceryList.createdAt, order: .reverse) private var lists: [GroceryList]
    @State private var showingBuilder = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(lists) { list in
                    NavigationLink(value: list) {
                        VStack(alignment: .leading) {
                            Text(list.title.isEmpty ? "Untitled list" : list.title)
                                .font(.headline)
                            Text(progressLabel(list))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if lists.isEmpty {
                    ContentUnavailableView(
                        "No grocery lists",
                        systemImage: "cart",
                        description: Text("Build a list from the meals you've saved.")
                    )
                }
            }
            .navigationTitle("Grocery")
            .navigationDestination(for: GroceryList.self) { list in
                GroceryListDetailView(list: list)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingBuilder = true } label: {
                        Label("New list", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingBuilder) {
                BuildListView()
            }
        }
    }

    private func progressLabel(_ list: GroceryList) -> String {
        let items = list.items ?? []
        let checked = items.filter(\.isChecked).count
        return "\(checked)/\(items.count) checked • \(list.selectedMeals?.count ?? 0) meals"
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(lists[i]) }
    }
}
