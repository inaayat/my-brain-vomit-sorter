import SwiftUI

enum Theme {
    static var isBro: Bool { UserDefaults.standard.bool(forKey: "broMode") }

    static func radius(_ normal: CGFloat) -> CGFloat { isBro ? 0 : normal }

    static var cardBorder: Color { isBro ? Color(hex: "#2E2E2E") : Color.clear }

    // Core Neutrals
    static var canvas: Color { isBro ? Color(hex: "#121212") : Color(hex: "#F5EFE6") }
    static var cardBg: Color { isBro ? Color(hex: "#1A1A1A") : Color(hex: "#FFFFFF") }
    static var cardAlt: Color { isBro ? Color(hex: "#1E1E1E") : Color(hex: "#F9F9F7") }
    static var divider: Color { isBro ? Color(hex: "#2E2E2E") : Color(hex: "#E6E0D6") }
    static var softGray: Color { isBro ? Color(hex: "#2A2A2A") : Color(hex: "#ECEBE7") }

    // Text
    static var textPrimary: Color { isBro ? Color(hex: "#E0E0E0") : Color(hex: "#0F0F10") }
    static var textSecondary: Color { isBro ? Color(hex: "#C0C0C0") : Color(hex: "#2A2A2A") }
    static var textMuted: Color { isBro ? Color(hex: "#A0A0A0") : Color(hex: "#7A7A7A") }

    // Sidebar / Nav (unchanged in bro mode)
    static var sidebarBg: Color { Color(hex: "#0F0F10") }
    static var sidebarText: Color { Color(hex: "#FFFFFF") }
    static var sidebarMuted: Color { Color(hex: "#9A9A9A") }
    static var sidebarActive: Color { Color(hex: "#FFFFFF").opacity(0.08) }

    // Category: Actions (Green)
    static var green: Color { Color(hex: "#9CAF6C") }
    static var greenDark: Color { Color(hex: "#7E944F") }
    static var greenTint: Color { isBro ? Color(hex: "#1E2420") : Color(hex: "#C9D7A3") }

    // Category: Brainstorms (Pink)
    static var pink: Color { Color(hex: "#E78AB6") }
    static var pinkDark: Color { Color(hex: "#C85A8E") }
    static var pinkTint: Color { isBro ? Color(hex: "#241E22") : Color(hex: "#F4B6D3") }

    // Category: Revisit (Yellow)
    static var yellow: Color { Color(hex: "#F2D36B") }
    static var yellowDark: Color { Color(hex: "#C7A73E") }
    static var yellowTint: Color { isBro ? Color(hex: "#24221E") : Color(hex: "#FAE8A6") }

    // Category: Resources (Blue)
    static var blue: Color { Color(hex: "#9FB7D9") }
    static var blueDark: Color { Color(hex: "#6E8FBC") }
    static var blueTint: Color { isBro ? Color(hex: "#1E2124") : Color(hex: "#C9D8EF") }

    // Accents
    static var purple: Color { Color(hex: "#A75A8A") }
    static var warmBrown: Color { Color(hex: "#8B6F3D") }

    // Progress / Visualization
    static var emptyState: Color { isBro ? Color(hex: "#2A2A2A") : Color(hex: "#E6E0D6") }

    // Convenience
    static var accent: Color { purple }
    static var border: Color { divider }
    static var card: Color { cardBg }
    static var surface: Color { cardAlt }
    static var bg: Color { canvas }
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
