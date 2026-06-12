import Foundation
import GRDB

struct MasterDoc: Identifiable, Codable, Equatable {
    var id: String
    var tag: String
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
}

extension MasterDoc: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "master_docs"

    enum Columns: String, ColumnExpression {
        case id, tag, title, content, createdAt, updatedAt
    }
}
