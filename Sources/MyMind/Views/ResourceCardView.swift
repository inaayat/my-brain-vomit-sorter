import SwiftUI

struct ResourceCardView: View {
    let item: Item
    var onTap: () -> Void
    var onDrop: ((String) -> Void)?
    @State private var isDropTarget = false

    private var url: URL? {
        if let u = item.url { return URL(string: u) }
        if let match = item.text.range(of: #"https?://\S+"#, options: .regularExpression) {
            return URL(string: String(item.text[match]))
        }
        return nil
    }

    private var domain: String {
        guard let url else { return "" }
        return url.host?.replacingOccurrences(of: "www.", with: "") ?? ""
    }

    private var displayTitle: String {
        if let title = item.urlTitle, !title.isEmpty { return title }
        if !domain.isEmpty { return domain }
        return item.text
    }

    var body: some View {
        HStack(spacing: 10) {
            Button { onTap() } label: {
                Circle()
                    .strokeBorder(item.done ? Theme.greenDark : Theme.textMuted, lineWidth: 2)
                    .background(item.done ? Circle().fill(Theme.green) : nil)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)

            if let url {
                SwiftUI.Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.blueDark)
                        Text(displayTitle)
                            .font(.inter(13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Text(displayTitle)
                    .font(.inter(13))
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()

            if let url {
                SwiftUI.Link(destination: url) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#EEF3FB"), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isDropTarget ? Theme.purple : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .draggable(item.id)
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let draggedId = droppedIds.first, draggedId != item.id else { return false }
            onDrop?(draggedId)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }
}
