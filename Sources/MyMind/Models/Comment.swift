import Foundation
import GRDB

struct Comment: Identifiable, Codable, Equatable {
    var id: String
    var itemId: String
    var text: String
    var createdAt: Date
}

extension Comment: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "comments"

    enum Columns: String, ColumnExpression {
        case id, itemId, text, createdAt
    }
}

extension Comment {
    static func new(itemId: String, text: String) -> Comment {
        Comment(id: UUID().uuidString, itemId: itemId, text: text, createdAt: Date())
    }
}
