import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            MealsListView()
                .tabItem { Label("Meals", systemImage: "fork.knife") }

            PantryListView()
                .tabItem { Label("Pantry", systemImage: "cabinet") }

            GroceryListsView()
                .tabItem { Label("Grocery", systemImage: "cart") }

            HouseholdView()
                .tabItem { Label("Household", systemImage: "person.2") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! .makeInMemoryContainer())
}
