import Foundation
import CloudKit
import Combine

let pantryCloudKitContainerID = "iCloud.mccoy.pantry"

@MainActor
final class HouseholdShareManager: ObservableObject {
    static let shared = HouseholdShareManager()

    @Published var state: ShareState = .loading
    @Published var participants: [CKShare.Participant] = []

    private let ckContainer = CKContainer(identifier: pantryCloudKitContainerID)
    private(set) var cachedShare: CKShare?

    enum ShareState: Equatable {
        case loading
        case notShared
        case owner(CKShare)
        case iCloudUnavailable

        static func == (lhs: ShareState, rhs: ShareState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.notShared, .notShared), (.iCloudUnavailable, .iCloudUnavailable):
                return true
            case (.owner(let a), .owner(let b)):
                return a.recordID == b.recordID
            default:
                return false
            }
        }
    }

    func refresh() async {
        state = .loading
        do {
            guard try await ckContainer.accountStatus() == .available else {
                state = .iCloudUnavailable
                return
            }
            let db = ckContainer.privateCloudDatabase
            guard let zoneID = try await findSwiftDataZone(in: db) else {
                state = .notShared
                return
            }
            if let share = try await fetchExistingShare(zoneID: zoneID, from: db) {
                cachedShare = share
                participants = share.participants.filter { $0.role != .owner }
                state = .owner(share)
            } else {
                state = .notShared
            }
        } catch {
            state = .notShared
        }
    }

    /// Creates the CKShare (or returns the existing one) and returns it
    /// alongside the CKContainer so callers can hand both to UICloudSharingController.
    func prepareShare() async throws -> (CKShare, CKContainer) {
        let db = ckContainer.privateCloudDatabase

        guard let zoneID = try await findSwiftDataZone(in: db) else {
            throw ShareError.noDataYet
        }
        if let existing = try await fetchExistingShare(zoneID: zoneID, from: db) {
            cachedShare = existing
            participants = existing.participants.filter { $0.role != .owner }
            state = .owner(existing)
            return (existing, ckContainer)
        }

        // Zone-level share — shares every record SwiftData stores in this zone.
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = "Household Pantry" as CKRecordValue
        try await db.save(share)
        cachedShare = share
        participants = []
        state = .owner(share)
        return (share, ckContainer)
    }

    /// Called by UICloudSharingController's preparation handler so the
    /// controller can create the share lazily on first invite.
    func prepareSharingController(
        preparationHandler: @escaping (CKShare?, CKContainer, Error?) -> Void
    ) {
        Task {
            do {
                let (share, container) = try await prepareShare()
                preparationHandler(share, container, nil)
            } catch {
                preparationHandler(nil, ckContainer, error)
            }
        }
    }

    func removeParticipant(_ participant: CKShare.Participant) async throws {
        guard let share = cachedShare else { return }
        share.removeParticipant(participant)
        try await ckContainer.privateCloudDatabase.save(share)
        participants = share.participants.filter { $0.role != .owner }
    }

    // MARK: - Helpers

    /// SwiftData names its zones "com.apple.coredata.cloudkit.zone" (unnamed
    /// config) or "com.apple.coredata.cloudkit.<Name>.zone" (named config).
    private func findSwiftDataZone(in db: CKDatabase) async throws -> CKRecordZone.ID? {
        let zones = try await db.allRecordZones()
        return zones.first {
            $0.zoneID.zoneName.hasPrefix("com.apple.coredata.cloudkit")
        }?.zoneID
    }

    /// Zone-level shares use the well-known record name "cloudkit.share".
    private func fetchExistingShare(
        zoneID: CKRecordZone.ID,
        from db: CKDatabase
    ) async throws -> CKShare? {
        let shareID = CKRecord.ID(recordName: "cloudkit.share", zoneID: zoneID)
        do {
            let record = try await db.record(for: shareID)
            return record as? CKShare
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }
}

enum ShareError: LocalizedError {
    case noDataYet

    var errorDescription: String? {
        "Add at least one meal or pantry item before inviting household members."
    }
}
