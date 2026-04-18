import SwiftUI

struct HouseholdView: View {
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Sync") {
                    Label("Syncing across your iCloud devices", systemImage: "icloud")
                    Text("Your meals, pantry, and grocery lists automatically sync to every Apple device signed in with this iCloud account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Household") {
                    Button {
                        message = HouseholdSharing.startInviteFlow()
                    } label: {
                        Label("Invite a household member", systemImage: "person.badge.plus")
                    }
                    if let m = message {
                        Text(m)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Household")
        }
    }
}
