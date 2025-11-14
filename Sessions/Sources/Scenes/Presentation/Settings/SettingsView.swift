import SwiftUI
import Observation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    SettingsDetailLink(title: "Notifications", systemImage: "bell.fill")
                    SettingsDetailLink(title: "Focus Goals", systemImage: "target")
                }

                Section("Support") {
                    SettingsDetailLink(title: "Help Center", systemImage: "questionmark.circle")
                    SettingsDetailLink(title: "Contact Us", systemImage: "envelope")
                }

                #if DEBUG || DEVELOPMENT
                Section("Debug") {
                    LabeledContent(
                        "Subscription Status",
                        value: subscriptionStatusText(viewModel.subscriptionStatusProvider.status)
                    )
                }
                #endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func subscriptionStatusText(_ status: SubscriptionStatus) -> String {
        switch status {
        case .unknown:
            return "Unknown"
        case .inactive:
            return "Not Subscribed"
        case .active:
            return "Subscribed"
        }
    }
}

private struct SettingsDetailLink: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationLink {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.title2.weight(.semibold))
                Text("This option isn't wired up yet, but this is where it will live.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .navigationTitle(title)
            .background(Color(.systemGroupedBackground))
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(
        subscriptionStatusProvider: PreviewSubscriptionStatusProvider(status: .active(expirationDate: nil))
    ))
}

@MainActor
@Observable
final class PreviewSubscriptionStatusProvider: SubscriptionStatusProviding {
    var status: SubscriptionStatus

    init(status: SubscriptionStatus) {
        self.status = status
    }

    var isSubscribed: Bool { status.isSubscribed }

    func refreshStatus() async {}
}
