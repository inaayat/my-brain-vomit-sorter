import Foundation
import GRDB

final class DatabaseManager: Sendable {
    static let shared = DatabaseManager()

    let dbPool: DatabasePool

    private init() {
        let dataDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".my-mind")
        try! FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)

        let dbPath = dataDir.appendingPathComponent("mind.db").path
        dbPool = try! DatabasePool(path: dbPath)

        try! migrator.migrate(dbPool)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "clusters") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("summary", .text)
                t.column("category", .text).notNull().defaults(to: "brainstorm")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "items") { t in
                t.column("id", .text).primaryKey()
                t.column("text", .text).notNull()
                t.column("category", .text).notNull().defaults(to: "brainstorm")
                t.column("createdAt", .datetime).notNull()
                t.column("done", .boolean).notNull().defaults(to: false)
                t.column("doneAt", .datetime)
                t.column("priority", .text).notNull().defaults(to: "medium")
                t.column("dueDate", .datetime)
                t.column("clusterId", .text).references("clusters", onDelete: .setNull)
                t.column("tags", .text)
                t.column("url", .text)
            }

            try db.create(table: "comments") { t in
                t.column("id", .text).primaryKey()
                t.column("itemId", .text).notNull().references("items", onDelete: .cascade)
                t.column("text", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "links") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("fromId", .text).notNull().references("items", onDelete: .cascade)
                t.column("toId", .text).notNull().references("items", onDelete: .cascade)
                t.column("relationship", .text).notNull().defaults(to: "related")
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(index: "idx_items_category", on: "items", columns: ["category"])
            try db.create(index: "idx_items_done", on: "items", columns: ["done"])
            try db.create(index: "idx_items_cluster", on: "items", columns: ["clusterId"])
            try db.create(index: "idx_comments_item", on: "comments", columns: ["itemId"])
            try db.create(index: "idx_links_from", on: "links", columns: ["fromId"])
            try db.create(index: "idx_links_to", on: "links", columns: ["toId"])
        }

        migrator.registerMigration("v2-wins") { db in
            try db.create(table: "wins") { t in
                t.column("id", .text).primaryKey()
                t.column("itemId", .text).notNull().references("items", onDelete: .cascade)
                t.column("artifact", .text)
                t.column("valueAdd", .text)
                t.column("createdAt", .datetime).notNull()
            }
            try db.create(index: "idx_wins_item", on: "wins", columns: ["itemId"])
        }

        migrator.registerMigration("v3-urlTitle") { db in
            try db.alter(table: "items") { t in
                t.add(column: "urlTitle", .text)
            }
        }

        migrator.registerMigration("v4-notes") { db in
            try db.alter(table: "items") { t in
                t.add(column: "notes", .text)
            }
        }

        return migrator
    }
}
