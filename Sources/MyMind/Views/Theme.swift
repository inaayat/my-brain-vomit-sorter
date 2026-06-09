import SwiftUI

enum Theme {
    // Core Neutrals
    static let canvas = Color(hex: "#F5EFE6")
    static let cardBg = Color(hex: "#FFFFFF")
    static let cardAlt = Color(hex: "#F9F9F7")
    static let divider = Color(hex: "#E6E0D6")
    static let softGray = Color(hex: "#ECEBE7")

    // Text
    static let textPrimary = Color(hex: "#0F0F10")
    static let textSecondary = Color(hex: "#2A2A2A")
    static let textMuted = Color(hex: "#7A7A7A")

    // Sidebar / Nav
    static let sidebarBg = Color(hex: "#0F0F10")
    static let sidebarText = Color(hex: "#FFFFFF")
    static let sidebarMuted = Color(hex: "#9A9A9A")
    static let sidebarActive = Color(hex: "#FFFFFF").opacity(0.08)

    // Category: Actions (Green)
    static let green = Color(hex: "#9CAF6C")
    static let greenDark = Color(hex: "#7E944F")
    static let greenTint = Color(hex: "#C9D7A3")

    // Category: Brainstorms (Pink)
    static let pink = Color(hex: "#E78AB6")
    static let pinkDark = Color(hex: "#C85A8E")
    static let pinkTint = Color(hex: "#F4B6D3")

    // Category: Revisit (Yellow)
    static let yellow = Color(hex: "#F2D36B")
    static let yellowDark = Color(hex: "#C7A73E")
    static let yellowTint = Color(hex: "#FAE8A6")

    // Category: Resources (Blue)
    static let blue = Color(hex: "#9FB7D9")
    static let blueDark = Color(hex: "#6E8FBC")
    static let blueTint = Color(hex: "#C9D8EF")

    // Accents
    static let purple = Color(hex: "#A75A8A")
    static let warmBrown = Color(hex: "#8B6F3D")

    // Progress / Visualization
    static let emptyState = Color(hex: "#E6E0D6")

    // Convenience
    static let accent = purple
    static let border = divider
    static let card = cardBg
    static let surface = cardAlt
    static let bg = canvas
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

struct PriorityPicker: View {
    let item: Item
    var onChange: () -> Void

    var body: some View {
        Menu {
            Button {
                setPriority(.high)
            } label: {
                Label("High", systemImage: "arrow.up")
            }
            Button {
                setPriority(.medium)
            } label: {
                Label("Standard", systemImage: "minus")
            }
            Button {
                setPriority(.backlog)
            } label: {
                Label("Backlog", systemImage: "arrow.down")
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: item.priority.isHigh ? "arrow.up" : (item.priority.isBacklog ? "arrow.down" : "minus"))
                    .font(.system(size: 8, weight: .bold))
                Text(item.priority.isHigh ? "High" : (item.priority.isBacklog ? "Backlog" : "Std"))
                    .font(.inter(8, weight: .medium))
            }
            .foregroundStyle(item.priority.isHigh || item.priority.isBacklog ? .white : Theme.textMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(item.priority.isHigh ? Theme.pink : (item.priority.isBacklog ? Theme.yellow : Theme.softGray), in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func setPriority(_ priority: Priority) {
        var updated = item
        updated.priority = priority
        try? Queries.updateItem(updated)
        onChange()
    }
}

struct PillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.inter(11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Theme.purple : Color.clear, in: Capsule())
                .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                .overlay(Capsule().strokeBorder(Theme.divider, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}
