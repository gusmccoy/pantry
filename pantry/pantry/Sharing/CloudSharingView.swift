import SwiftUI
import CloudKit

// MARK: - iOS

#if os(iOS)
import UIKit

/// SwiftUI wrapper around UICloudSharingController.
/// Present this as a sheet; it handles the full invite / participant-management flow.
struct CloudSharingSheet: UIViewControllerRepresentable {
    @ObservedObject var manager: HouseholdShareManager
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller: UICloudSharingController

        if let existing = manager.cachedShare {
            // Share already exists — open participant management.
            controller = UICloudSharingController(
                share: existing,
                container: CKContainer(identifier: pantryCloudKitContainerID)
            )
        } else {
            // No share yet — let the controller drive creation.
            controller = UICloudSharingController { _, preparationHandler in
                manager.prepareSharingController(preparationHandler: preparationHandler)
            }
        }

        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(manager: manager, dismiss: dismiss) }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let manager: HouseholdShareManager
        let dismiss: DismissAction

        init(manager: HouseholdShareManager, dismiss: DismissAction) {
            self.manager = manager
            self.dismiss = dismiss
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            Task { await manager.refresh() }
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            Task { await manager.refresh() }
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            // Dismiss so the error surfaces in HouseholdView rather than being silently swallowed.
            dismiss()
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { "Household Pantry" }
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? { nil }
        func itemType(for csc: UICloudSharingController) -> String? { nil }
    }
}
#endif

// MARK: - macOS

#if os(macOS)
import AppKit

/// On macOS, NSCloudSharingService is not directly available as a simple
/// sheet. Instead we copy the share URL to the clipboard and open the
/// system-standard sharing picker via NSSharingServicePicker.
struct CloudSharingButton: View {
    @ObservedObject var manager: HouseholdShareManager
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var shareURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                openSharingPicker()
            } label: {
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Invite household member…", systemImage: "person.badge.plus")
                }
            }
            .disabled(isWorking)

            if let url = shareURL {
                HStack {
                    Text("Link copied")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("Open", destination: url)
                        .font(.caption)
                }
            }
            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func openSharingPicker() {
        isWorking = true
        errorMessage = nil
        Task {
            defer { isWorking = false }
            do {
                let (share, _) = try await manager.prepareShare()
                guard let url = share.url else { return }
                shareURL = url
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)

                // Also open the standard macOS sharing picker if available.
                if let service = NSSharingService(named: .cloudSharing) {
                    service.perform(withItems: [url])
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
#endif
