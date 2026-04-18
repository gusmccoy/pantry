import SwiftUI
import SwiftData

struct GroceryListDetailView: View {
    @Bindable var list: GroceryList

    var body: some View {
        List {
            if let items = list.items, !items.isEmpty {
                Section("Need to buy") {
                    ForEach(activeItems) { row($0) }
                }
                if !coveredItems.isEmpty {
                    Section("Already in pantry") {
                        ForEach(coveredItems) { row($0) }
                    }
                }
            } else {
                Text("This list has no items.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(list.title.isEmpty ? "List" : list.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var activeItems: [GroceryListItem] {
        (list.items ?? [])
            .filter { !$0.isCoveredByPantry }
            .sorted { $0.displayName < $1.displayName }
    }

    private var coveredItems: [GroceryListItem] {
        (list.items ?? [])
            .filter(\.isCoveredByPantry)
            .sorted { $0.displayName < $1.displayName }
    }

    @ViewBuilder
    private func row(_ item: GroceryListItem) -> some View {
        HStack {
            Button {
                item.isChecked.toggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(item.displayName)
                    .strikethrough(item.isChecked)
                if item.quantity > 0 || !item.unit.isEmpty {
                    Text(quantityLabel(item))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if item.isCoveredByPantry {
                Text("in pantry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func quantityLabel(_ item: GroceryListItem) -> String {
        let q = item.quantity
        let qtyStr = q.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(q))
            : String(q)
        if q > 0 && !item.unit.isEmpty { return "\(qtyStr) \(item.unit)" }
        if q > 0 { return qtyStr }
        return item.unit
    }
}
