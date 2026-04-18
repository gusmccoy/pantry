import Foundation
import CloudKit

// MARK: - iOS

#if os(iOS)
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        acceptShare(cloudKitShareMetadata)
    }
}
#endif

// MARK: - macOS

#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(
        _ application: NSApplication,
        userDidAcceptCloudKitShareWith metadata: CKShare.Metadata
    ) {
        acceptShare(metadata)
    }
}
#endif

// MARK: - Shared accept logic

private func acceptShare(_ metadata: CKShare.Metadata) {
    let op = CKAcceptSharesOperation(shareMetadatas: [metadata])
    op.qualityOfService = .userInteractive
    op.perShareResultBlock = { _, result in
        if case .failure(let error) = result {
            print("[HouseholdSharing] Failed to accept share: \(error)")
        }
    }
    op.acceptSharesResultBlock = { result in
        if case .failure(let error) = result {
            print("[HouseholdSharing] acceptShares operation failed: \(error)")
        }
        // After accepting, SwiftData will sync shared records into the local store
        // on the next CloudKit push/pull cycle (typically within seconds).
    }
    CKContainer(identifier: pantryCloudKitContainerID).add(op)
}
