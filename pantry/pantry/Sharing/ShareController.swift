import Foundation
import SwiftData
import CloudKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Scaffold for CKShare-based household sharing.
///
/// Status: PLACEHOLDER. Sync across a single user's own devices works
/// automatically via the private CloudKit database (set up in
/// ModelContainer.makePantryContainer). What's missing is the CKShare
/// flow that lets *another iCloud user* join the household.
///
/// Wire this up once there are two iCloud accounts available to test with:
///  1. Pick a root model to share (e.g. a dedicated HouseholdRoot record,
///     or the Meal/PantryItem graph directly).
///  2. Call ModelContainer.share(...) or drop down to CKContainer and
///     create a CKShare rooted at that record's CKRecord.
///  3. Present UICloudSharingController (iOS) / NSSharingServicePicker
///     (macOS) with the resulting share URL.
///  4. Handle inbound accepts in SceneDelegate / AppDelegate via
///     userDidAcceptCloudKitShareWith.
enum HouseholdSharing {
    enum State: Equatable {
        case notShared
        case unavailable(reason: String)
    }

    static func currentState() -> State {
        // TODO: Inspect the CKContainer for an existing share rooted at the
        // household's root record. For now, always report "notShared" so the
        // UI can prompt the user to invite someone.
        .notShared
    }

    /// Returns an error the UI can display. Real implementation will create
    /// a CKShare and present the platform sharing UI.
    static func startInviteFlow() -> String {
        "Household sharing is not yet wired up. The app already syncs across your own iCloud devices. Invite a household member will be available in a future build."
    }
}
