import Foundation
import GRDB

struct TagRelationship: Identifiable, Codable, Equatable {
    var id: String
    var parentTag: String
    var childTag: String
    var createdAt: Date
}

extension TagRelationship: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "tag_relationships"

    enum Columns: String, ColumnExpression {
        case id, parentTag, childTag, createdAt
    }
}
