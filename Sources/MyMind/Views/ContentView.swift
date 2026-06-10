import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(appState: appState)

            Divider().background(Theme.border)

            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg)

            // Slide-in detail panel
            if appState.detailPanelItemId != nil {
                Divider().background(Theme.divider)

                detailPanel
                    .frame(width: panelWidth)
                    .background(Theme.cardBg)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.detailPanelItemId)
        .frame(minWidth: 800, minHeight: 560)
        .preferredColorScheme(appState.broMode ? .dark : .light)
        .id(appState.broMode)
        .sheet(isPresented: $appState.showEditSheet) {
            if let item = appState.editingItem {
                EditSheet(appState: appState, item: item)
            }
        }
        .sheet(isPresented: $appState.showLogWinSheet) {
            if let item = appState.completedItem {
                LogWinSheet(item: item) { artifact, valueAdd in
                    let win = Win.new(itemId: item.id, artifact: artifact, valueAdd: valueAdd)
                    try? Queries.addWin(win)
                    appState.refreshCounts()
                } onSkip: {}
            }
        }
        .onAppear { appState.refreshCounts() }
    }

    private var panelWidth: CGFloat {
        400
    }

    @ViewBuilder
    private var mainContent: some View {
        switch appState.selectedDestination {
        case .overview:
            OverviewView(appState: appState)
        case .completed:
            ItemListView(appState: appState, category: nil, title: "Completed", showDone: true)
        case .wins:
            WinsView(appState: appState)
        case .clusters:
            ClustersView(appState: appState)
        case .guide:
            GuideView()
        case .itemDetail:
            OverviewView(appState: appState)
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let itemId = appState.detailPanelItemId {
            ItemDetailView(appState: appState, itemId: itemId)
                .padding(20)
        }
    }
}
