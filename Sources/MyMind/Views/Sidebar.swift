import SwiftUI
import AppKit

struct Sidebar: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Logo — navigates to Guide
            Button {
                appState.selectedDestination = .guide
            } label: {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.pink)
                    .frame(width: 36, height: 36)
                    .background(Theme.pinkTint.opacity(0.4), in: RoundedRectangle(cornerRadius: Theme.radius(10), style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
            .padding(.bottom, 24)

            VStack(spacing: 16) {
                iconButton(.overview, icon: "square.grid.2x2", tooltip: "Feed")
                iconButton(.dailyDump, icon: "list.bullet.rectangle.portrait", tooltip: "Daily Dump")
                iconButton(.clusters, icon: "rectangle.3.group", tooltip: "Clusters")
                iconButton(.completed, icon: "checkmark.circle", tooltip: "Completed")
                iconButton(.wins, icon: "trophy.fill", tooltip: "Wins")
                iconButton(.masterDocs, icon: "doc.text.fill", tooltip: "Master Docs")
            }

            Spacer()

            Button { exportData() } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.sidebarMuted)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .help("Export Data")
            .padding(.bottom, 8)

            VStack(spacing: 6) {
                Text(appState.broMode ? "girls just\nwanna\nhave fun" : "bro\nmode")
                    .font(.inter(7, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.sidebarMuted)
                    .lineLimit(3)

                Toggle("", isOn: $appState.broMode)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                    .tint(.gray)
            }
            .frame(width: 56)
            .padding(.bottom, 16)
        }
        .frame(width: 64)
        .background(Theme.sidebarBg)
    }

    private func exportData() {
        let markdown = ExportService.generateMarkdown()
        let panel = NSSavePanel()
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        panel.nameFieldStringValue = "mymind-export-\(dateStr).md"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    @ViewBuilder
    private func iconButton(_ dest: NavigationDestination, icon: String, tooltip: String) -> some View {
        let isSelected = appState.selectedDestination == dest

        Button {
            appState.selectedDestination = dest
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? Theme.sidebarBg : Theme.sidebarMuted)
                .frame(width: 38, height: 38)
                .background(isSelected ? Theme.pink : Color.clear, in: Circle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}
