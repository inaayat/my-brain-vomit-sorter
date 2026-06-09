import Foundation
import GRDB

enum Category: String, Codable, CaseIterable, DatabaseValueConvertible {
    case brainstorm, action, revisit, resource

    static var activeCategories: [Category] { [.action, .brainstorm, .resource] }

    var sortOrder: Int {
        switch self {
        case .action: return 0
        case .brainstorm: return 1
        case .resource: return 2
        case .revisit: return 3
        }
    }
}

enum Priority: String, Codable, CaseIterable, DatabaseValueConvertible {
    case high, medium, low, backlog

    var isHigh: Bool { self == .high }
    var isBacklog: Bool { self == .backlog }
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium, .low: return 1
        case .backlog: return 2
        }
    }
}

struct Item: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var category: Category
    var createdAt: Date
    var done: Bool
    var doneAt: Date?
    var priority: Priority
    var dueDate: Date?
    var clusterId: String?
    var tags: String?
    var url: String?
    var urlTitle: String?

    var parsedTags: [String] {
        guard let tags else { return [] }
        guard let data = tags.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return arr
    }

    var daysOld: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    var isOverdue: Bool {
        guard let dueDate, !done else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }

    var isDueToday: Bool {
        guard let dueDate, !done else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isDueSoon: Bool {
        guard let dueDate, !done else { return false }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return Calendar.current.isDate(dueDate, inSameDayAs: tomorrow)
    }
}

extension Item: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "items"

    enum Columns: String, ColumnExpression {
        case id, text, category, createdAt, done, doneAt, priority, dueDate, clusterId, tags, url, urlTitle
    }
}

extension Item {
    static func new(text: String, category: Category = .brainstorm, priority: Priority = .medium, dueDate: Date? = nil, url: String? = nil, urlTitle: String? = nil) -> Item {
        Item(
            id: UUID().uuidString,
            text: text,
            category: category,
            createdAt: Date(),
            done: false,
            doneAt: nil,
            priority: priority,
            dueDate: dueDate,
            clusterId: nil,
            tags: nil,
            url: url,
            urlTitle: urlTitle
        )
    }
}
