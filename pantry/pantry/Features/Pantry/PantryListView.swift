import SwiftUI
import SwiftData

struct PantryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PantryItem.rawName) private var items: [PantryItem]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        VStack(alignment: .leading) {
                            Text(item.rawName.isEmpty ? "(unnamed)" : item.rawName)
                            if item.quantity > 0 || !item.unit.isEmpty {
                                Text(quantityLabel(item))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Pantry is empty",
                        systemImage: "cabinet",
                        description: Text("Track what you have on hand so grocery lists know what to skip.")
                    )
                }
            }
            .navigationTitle("Pantry")
            .navigationDestination(for: PantryItem.self) { item in
                PantryItemEditor(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddSheet = true } label: {
                        Label("Add item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPantryItemSheet()
            }
        }
    }

    private func quantityLabel(_ item: PantryItem) -> String {
        if item.quantity > 0 && !item.unit.isEmpty {
            return "\(formatQty(item.quantity)) \(item.unit)"
        }
        if item.quantity > 0 { return formatQty(item.quantity) }
        return item.unit
    }

    private func formatQty(_ q: Double) -> String {
        q.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(q))
            : String(q)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(items[i]) }
    }
}

private struct AddPantryItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existing: [PantryItem]

    @State private var name = ""
    @State private var quantity: Double = 0
    @State private var unit = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                QuantityField(quantity: $quantity, unit: $unit)
            }
            .navigationTitle("Add to pantry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let normalized = IngredientName.normalize(name)
        // Dedupe: merge into existing pantry item with same normalized name + unit.
        if let match = existing.first(where: {
            $0.normalizedName == normalized && $0.unit == unit
        }) {
            match.quantity += quantity
            match.updatedAt = .now
        } else {
            let item = PantryItem(rawName: name, quantity: quantity, unit: unit)
            modelContext.insert(item)
        }
        dismiss()
    }
}

struct PantryItemEditor: View {
    @Bindable var item: PantryItem

    var body: some View {
        Form {
            TextField("Name", text: Binding(
                get: { item.rawName },
                set: {
                    item.rawName = $0
                    item.normalizedName = IngredientName.normalize($0)
                    item.updatedAt = .now
                }
            ))
            QuantityField(quantity: $item.quantity, unit: $item.unit)
        }
        .navigationTitle("Pantry item")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
