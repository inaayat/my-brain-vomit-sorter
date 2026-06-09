import SwiftUI

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
                    .background(Theme.pinkTint.opacity(0.4), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Main nav icons
            VStack(spacing: 16) {
                iconButton(.overview, icon: "square.grid.2x2", tooltip: "Overview")
                iconButton(.actions, icon: "bolt.fill", tooltip: "Actions")
                iconButton(.brainstorms, icon: "cloud.bolt.fill", tooltip: "Brainstorms")
                iconButton(.resources, icon: "bookmark.fill", tooltip: "Resources")
            }

            Divider()
                .frame(width: 24)
                .background(Theme.sidebarText.opacity(0.15))
                .padding(.vertical, 16)

            // Library
            VStack(spacing: 16) {
                iconButton(.allItems, icon: "tray.full.fill", tooltip: "All Items")
                iconButton(.clusters, icon: "rectangle.3.group", tooltip: "Clusters")
                iconButton(.completed, icon: "checkmark.circle", tooltip: "Completed")
                iconButton(.wins, icon: "trophy.fill", tooltip: "Wins")
            }


            Spacer()
        }
        .frame(width: 64)
        .background(Theme.sidebarBg)
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
