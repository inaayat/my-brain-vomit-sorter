import Foundation
import GRDB

struct Win: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var id: String
    var itemId: String
    var artifact: String?
    var valueAdd: String?
    var createdAt: Date

    static let databaseTableName = "wins"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let itemId = Column(CodingKeys.itemId)
        static let artifact = Column(CodingKeys.artifact)
        static let valueAdd = Column(CodingKeys.valueAdd)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    static func new(itemId: String, artifact: String?, valueAdd: String?) -> Win {
        Win(
            id: UUID().uuidString,
            itemId: itemId,
            artifact: artifact?.trimmingCharacters(in: .whitespaces).isEmpty == true ? nil : artifact?.trimmingCharacters(in: .whitespaces),
            valueAdd: valueAdd?.trimmingCharacters(in: .whitespaces).isEmpty == true ? nil : valueAdd?.trimmingCharacters(in: .whitespaces),
            createdAt: Date()
        )
    }
}
