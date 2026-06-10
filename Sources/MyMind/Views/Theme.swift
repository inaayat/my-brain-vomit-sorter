import SwiftUI

enum Theme {
    static var isBro: Bool { UserDefaults.standard.bool(forKey: "broMode") }

    static func radius(_ normal: CGFloat) -> CGFloat { normal }

    static var cardBorder: Color { isBro ? Color(nsColor: .separatorColor) : Color.clear }

    // Core Neutrals (bro mode uses Apple's dark mode elevation hierarchy)
    static var canvas: Color { isBro ? Color(nsColor: .windowBackgroundColor) : Color(hex: "#F5EFE6") }
    static var cardBg: Color { isBro ? Color(nsColor: .controlBackgroundColor) : Color(hex: "#FFFFFF") }
    static var cardAlt: Color { isBro ? Color(hex: "#3A3A3C") : Color(hex: "#F9F9F7") }
    static var divider: Color { isBro ? Color(nsColor: .separatorColor) : Color(hex: "#E6E0D6") }
    static var softGray: Color { isBro ? Color(hex: "#3A3A3C") : Color(hex: "#ECEBE7") }

    // Text (bro mode uses Apple's label hierarchy)
    static var textPrimary: Color { isBro ? Color(nsColor: .labelColor) : Color(hex: "#0F0F10") }
    static var textSecondary: Color { isBro ? Color(nsColor: .secondaryLabelColor) : Color(hex: "#2A2A2A") }
    static var textMuted: Color { isBro ? Color(nsColor: .tertiaryLabelColor) : Color(hex: "#7A7A7A") }

    // Sidebar / Nav (unchanged)
    static var sidebarBg: Color { Color(hex: "#0F0F10") }
    static var sidebarText: Color { Color(hex: "#FFFFFF") }
    static var sidebarMuted: Color { Color(hex: "#9A9A9A") }
    static var sidebarActive: Color { Color(hex: "#FFFFFF").opacity(0.08) }

    // Category colors (grey in bro mode — icon shape is the only differentiator)
    static var green: Color { isBro ? Color(nsColor: .systemGray) : Color(hex: "#9CAF6C") }
    static var greenDark: Color { isBro ? Color(nsColor: .secondaryLabelColor) : Color(hex: "#7E944F") }
    static var greenTint: Color { isBro ? Color(hex: "#2C2C2E") : Color(hex: "#C9D7A3") }

    static var pink: Color { isBro ? Color(nsColor: .systemGray) : Color(hex: "#E78AB6") }
    static var pinkDark: Color { isBro ? Color(nsColor: .secondaryLabelColor) : Color(hex: "#C85A8E") }
    static var pinkTint: Color { isBro ? Color(hex: "#2C2C2E") : Color(hex: "#F4B6D3") }

    static var yellow: Color { isBro ? Color(nsColor: .systemGray) : Color(hex: "#F2D36B") }
    static var yellowDark: Color { isBro ? Color(nsColor: .secondaryLabelColor) : Color(hex: "#C7A73E") }
    static var yellowTint: Color { isBro ? Color(hex: "#2C2C2E") : Color(hex: "#FAE8A6") }

    static var blue: Color { isBro ? Color(nsColor: .systemGray) : Color(hex: "#9FB7D9") }
    static var blueDark: Color { isBro ? Color(nsColor: .secondaryLabelColor) : Color(hex: "#6E8FBC") }
    static var blueTint: Color { isBro ? Color(hex: "#2C2C2E") : Color(hex: "#C9D8EF") }

    // Accents
    static var purple: Color { isBro ? Color(nsColor: .secondaryLabelColor) : Color(hex: "#A75A8A") }
    static var warmBrown: Color { isBro ? Color(nsColor: .tertiaryLabelColor) : Color(hex: "#8B6F3D") }

    // Progress / Visualization
    static var emptyState: Color { isBro ? Color(hex: "#3A3A3C") : Color(hex: "#E6E0D6") }

    // Specific element backgrounds (exact original colors preserved in normal mode)
    static var clusterBg: Color { isBro ? Color(hex: "#2C2C2E") : Color(hex: "#FBF5E3") }
    static var resourceRowBg: Color { isBro ? Color(hex: "#2C2C2E") : Color(hex: "#EEF3FB") }

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
