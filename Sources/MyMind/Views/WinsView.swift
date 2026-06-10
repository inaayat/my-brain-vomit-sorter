import SwiftUI

struct WinsView: View {
    @Bindable var appState: AppState
    @State private var wins: [(win: Win, item: Item?)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Wins")
                    .font(.inter(20, weight: .bold))
                    .fontWeight(.bold)
                Spacer()
                Text("\(wins.count) logged")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            if wins.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.inter(40))
                        .foregroundStyle(.yellow.opacity(0.5))
                    Text("No wins logged yet")
                        .font(.inter(13))
                        .foregroundStyle(Theme.textMuted)
                    Text("Complete action items and log your wins!")
                        .font(.inter(11))
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(wins, id: \.win.id) { entry in
                            WinCard(win: entry.win, item: entry.item) {
                                if let item = entry.item {
                                    appState.navigate(to: .itemDetail(item.id))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear { loadWins() }
    }

    private func loadWins() {
        let allWins = (try? Queries.getAllWins()) ?? []
        wins = allWins.map { win in
            let item = try? Queries.getItem(id: win.itemId)
            return (win, item)
        }
    }
}

struct WinCard: View {
    let win: Win
    let item: Item?
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Win (value add) first
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.yellowDark)
                    .font(.system(size: 12))
                if let valueAdd = win.valueAdd, !valueAdd.isEmpty {
                    Text(valueAdd)
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                } else {
                    Text("Win logged")
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                Text(win.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.inter(10))
                    .foregroundStyle(Theme.textMuted)
            }

            // Task it was associated with
            if let item {
                Text(item.text)
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(2)
            }

            // Artifact link
            if let artifact = win.artifact, let url = URL(string: artifact) {
                SwiftUI.Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.blueDark)
                        Text(url.host ?? artifact)
                            .font(.inter(11))
                            .foregroundStyle(Theme.blueDark)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.yellowTint, in: RoundedRectangle(cornerRadius: Theme.radius(10)))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
