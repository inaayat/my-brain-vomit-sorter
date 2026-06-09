import Foundation
import GRDB

struct Link: Identifiable, Codable, Equatable {
    var id: Int64?
    var fromId: String
    var toId: String
    var relationship: String
    var createdAt: Date
}

extension Link: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "links"

    enum Columns: String, ColumnExpression {
        case id, fromId, toId, relationship, createdAt
    }
}

extension Link {
    static func new(fromId: String, toId: String, relationship: String = "related") -> Link {
        Link(id: nil, fromId: fromId, toId: toId, relationship: relationship, createdAt: Date())
    }
}
