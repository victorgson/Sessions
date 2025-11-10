import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

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
    SettingsView()
}
