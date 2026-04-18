import SwiftUI
import CloudKit

struct HouseholdView: View {
    @StateObject private var manager = HouseholdShareManager.shared
    @Environment(\.syncMode) private var syncMode
    @State private var showingShareSheet = false
    @State private var inviteError: String?

    var body: some View {
        NavigationStack {
            Form {
                syncSection
                householdSection
            }
            .navigationTitle("Household")
            .task { await manager.refresh() }
            #if os(iOS)
            .sheet(isPresented: $showingShareSheet) {
                CloudSharingSheet(manager: manager)
                    .ignoresSafeArea()
            }
            #endif
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var syncSection: some View {
        Section("Sync") {
            switch syncMode {
            case .cloudKit:
                Label("Syncing across your iCloud devices", systemImage: "icloud")
                Text("Meals, pantry, and grocery lists sync to every device signed in with this iCloud account.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .localOnly(let reason):
                Label("iCloud sync unavailable", systemImage: "xmark.icloud")
                    .foregroundStyle(.orange)
                Text("Data is saved locally only. Reason: \(reason)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var householdSection: some View {
        Section("Household") {
            switch manager.state {
            case .loading:
                HStack {
                    ProgressView()
                    Text("Checking share status…")
                        .foregroundStyle(.secondary)
                }

            case .iCloudUnavailable:
                Label("iCloud not available", systemImage: "xmark.icloud")
                Text("Sign in to iCloud in Settings to share with household members.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .notShared:
                inviteButton
                    .disabled(false)

            case .owner(let share):
                ownerContent(share: share)
            }

            if let err = inviteError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var inviteButton: some View {
        #if os(iOS)
        Button {
            inviteError = nil
            showingShareSheet = true
        } label: {
            Label("Invite household member…", systemImage: "person.badge.plus")
        }
        #elseif os(macOS)
        CloudSharingButton(manager: manager)
        #endif
    }

    @ViewBuilder
    private func ownerContent(share: CKShare) -> some View {
        // Re-open UICloudSharingController for participant management.
        Button {
            inviteError = nil
            showingShareSheet = true
        } label: {
            Label("Manage household members", systemImage: "person.2")
        }

        if manager.participants.isEmpty {
            Text("No members yet — invite someone below.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(manager.participants, id: \.userIdentity.userRecordID) { participant in
                ParticipantRow(participant: participant) {
                    Task {
                        do {
                            try await manager.removeParticipant(participant)
                        } catch {
                            inviteError = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ParticipantRow

private struct ParticipantRow: View {
    let participant: CKShare.Participant
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(displayName)
                Text(roleLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Remove", role: .destructive, action: onRemove)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var displayName: String {
        participant.userIdentity.nameComponents
            .flatMap {
                PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
            } ?? "Household member"
    }

    private var roleLabel: String {
        switch participant.permission {
        case .readWrite: return "Can edit"
        case .readOnly:  return "Read only"
        default:         return "Pending"
        }
    }
}
