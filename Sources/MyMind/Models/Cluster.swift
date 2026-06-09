import Foundation
import GRDB

struct Cluster: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var summary: String?
    var category: Category
    var createdAt: Date
    var updatedAt: Date

    var itemCount: Int = 0
    var items: [Item] = []

    enum CodingKeys: String, CodingKey {
        case id, title, summary, category, createdAt, updatedAt
    }
}

extension Cluster: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "clusters"

    enum Columns: String, ColumnExpression {
        case id, title, summary, category, createdAt, updatedAt
    }
}

extension Cluster {
    static func new(title: String, category: Category, summary: String? = nil) -> Cluster {
        let now = Date()
        return Cluster(
            id: UUID().uuidString,
            title: title,
            summary: summary,
            category: category,
            createdAt: now,
            updatedAt: now
        )
    }
}
