import Foundation
import GRDB

struct Queries {
    private static var db: DatabasePool { DatabaseManager.shared.dbPool }

    // MARK: - Items

    static func addItem(_ item: Item) throws {
        try db.write { db in try item.insert(db) }
    }

    static func updateItem(_ item: Item) throws {
        try db.write { db in try item.update(db) }
    }

    static func deleteItem(id: String) throws {
        try db.write { db in
            _ = try Link.filter(Link.Columns.fromId == id || Link.Columns.toId == id).deleteAll(db)
            _ = try Comment.filter(Comment.Columns.itemId == id).deleteAll(db)
            _ = try Item.filter(Item.Columns.id == id).deleteAll(db)
        }
    }

    static func getItem(id: String) throws -> Item? {
        try db.read { db in try Item.filter(Item.Columns.id == id).fetchOne(db) }
    }

    static func getAllItems() throws -> [Item] {
        try db.read { db in try Item.order(Item.Columns.createdAt.desc).fetchAll(db) }
    }

    static func getItems(category: Category? = nil, done: Bool? = nil, limit: Int = 100) throws -> [Item] {
        try db.read { db in
            var request = Item.all()
            if let category { request = request.filter(Item.Columns.category == category) }
            if let done { request = request.filter(Item.Columns.done == done) }
            return try request.order(Item.Columns.createdAt.desc).limit(limit).fetchAll(db)
        }
    }

    static func getOpenActions() throws -> [Item] {
        try db.read { db in
            try Item
                .filter(Item.Columns.category == Category.action && Item.Columns.done == false)
                .order(
                    Item.Columns.dueDate.asc,
                    Item.Columns.createdAt.asc
                )
                .fetchAll(db)
        }
    }

    static func searchItems(query: String) throws -> [Item] {
        try db.read { db in
            try Item
                .filter(Item.Columns.text.like("%\(query)%"))
                .order(Item.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    static func promoteDueSoonToHigh() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: today)!
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE items SET priority = ?
                    WHERE done = 0
                      AND dueDate IS NOT NULL
                      AND dueDate < ?
                      AND priority != ?
                    """,
                arguments: [Priority.high.rawValue, dayAfterTomorrow, Priority.high.rawValue]
            )
        }
    }

    static func completeItem(id: String) throws {
        try db.write { db in
            try db.execute(
                sql: "UPDATE items SET done = 1, doneAt = ? WHERE id = ?",
                arguments: [Date(), id]
            )
        }
    }

    static func uncompleteItem(id: String) throws {
        try db.write { db in
            try db.execute(
                sql: "UPDATE items SET done = 0, doneAt = NULL WHERE id = ?",
                arguments: [id]
            )
        }
    }

    static func assignToCluster(itemId: String, clusterId: String) throws {
        try db.write { db in
            try db.execute(
                sql: "UPDATE items SET clusterId = ? WHERE id = ?",
                arguments: [clusterId, itemId]
            )
            try db.execute(
                sql: "UPDATE clusters SET updatedAt = ? WHERE id = ?",
                arguments: [Date(), clusterId]
            )
        }
    }

    static func getCategoryCounts() throws -> [String: Int] {
        try db.read { db in
            var counts: [String: Int] = [:]
            let rows = try Row.fetchAll(db, sql: "SELECT category, COUNT(*) as count FROM items WHERE done = 0 GROUP BY category")
            for row in rows { counts[row["category"]] = row["count"] }
            counts["all"] = try Item.filter(Item.Columns.done == false).fetchCount(db)
            counts["completed"] = try Item.filter(Item.Columns.done == true).fetchCount(db)
            return counts
        }
    }

    // MARK: - Clusters

    static func createCluster(_ cluster: Cluster) throws {
        try db.write { db in try cluster.insert(db) }
    }

    static func getCluster(id: String) throws -> Cluster? {
        try db.read { db in
            guard var cluster = try Cluster.filter(Cluster.Columns.id == id).fetchOne(db) else { return nil }
            cluster.items = try Item.filter(Item.Columns.clusterId == id).order(Item.Columns.createdAt.desc).fetchAll(db)
            cluster.itemCount = cluster.items.count
            return cluster
        }
    }

    static func getClusters(category: Category? = nil) throws -> [Cluster] {
        try db.read { db in
            var request = Cluster.all()
            if let category { request = request.filter(Cluster.Columns.category == category) }
            var clusters = try request.order(Cluster.Columns.updatedAt.desc).fetchAll(db)
            for i in clusters.indices {
                clusters[i].items = try Item.filter(Item.Columns.clusterId == clusters[i].id).order(Item.Columns.createdAt.desc).fetchAll(db)
                clusters[i].itemCount = clusters[i].items.count
            }
            return clusters
        }
    }

    static func updateCluster(_ cluster: Cluster) throws {
        try db.write { db in try cluster.update(db) }
    }

    static func deleteCluster(id: String) throws {
        try db.write { db in
            try db.execute(sql: "UPDATE items SET clusterId = NULL WHERE clusterId = ?", arguments: [id])
            _ = try Cluster.filter(Cluster.Columns.id == id).deleteAll(db)
        }
    }

    static func getUnclusteredItems(category: Category? = nil) throws -> [Item] {
        try db.read { db in
            var request = Item.filter(Item.Columns.clusterId == nil && Item.Columns.done == false)
            if let category { request = request.filter(Item.Columns.category == category) }
            return try request.order(Item.Columns.createdAt.desc).fetchAll(db)
        }
    }

    static func getAllClustersWithItems() throws -> [Cluster] {
        try db.read { db in
            var clusters = try Cluster.order(Cluster.Columns.updatedAt.desc).fetchAll(db)
            for i in clusters.indices {
                clusters[i].items = try Item.filter(Item.Columns.clusterId == clusters[i].id).order(Item.Columns.createdAt.desc).fetchAll(db)
                clusters[i].itemCount = clusters[i].items.count
            }
            return clusters
        }
    }

    static func mergeClusters(keepId: String, removeIds: [String]) throws {
        try db.write { db in
            for removeId in removeIds {
                try db.execute(sql: "UPDATE items SET clusterId = ? WHERE clusterId = ?", arguments: [keepId, removeId])
                _ = try Cluster.filter(Cluster.Columns.id == removeId).deleteAll(db)
            }
            try db.execute(sql: "UPDATE clusters SET updatedAt = ? WHERE id = ?", arguments: [Date(), keepId])
        }
    }

    static func removeFromCluster(itemId: String) throws {
        try db.write { db in
            try db.execute(sql: "UPDATE items SET clusterId = NULL WHERE id = ?", arguments: [itemId])
        }
    }

    static func renameCluster(id: String, title: String) throws {
        try db.write { db in
            try db.execute(sql: "UPDATE clusters SET title = ?, updatedAt = ? WHERE id = ?", arguments: [title, Date(), id])
        }
    }

    static func createClusterFromItems(itemIds: [String], title: String = "New Cluster") throws -> Cluster {
        let cluster = Cluster.new(title: title, category: .brainstorm)
        try createCluster(cluster)
        for id in itemIds {
            try assignToCluster(itemId: id, clusterId: cluster.id)
        }
        return cluster
    }

    // MARK: - Comments

    static func addComment(_ comment: Comment) throws {
        try db.write { db in try comment.insert(db) }
    }

    static func getComments(itemId: String) throws -> [Comment] {
        try db.read { db in
            try Comment.filter(Comment.Columns.itemId == itemId).order(Comment.Columns.createdAt.asc).fetchAll(db)
        }
    }

    static func deleteComment(id: String) throws {
        try db.write { db in _ = try Comment.filter(Comment.Columns.id == id).deleteAll(db) }
    }

    // MARK: - Links

    static func addLink(_ link: Link) throws {
        try db.write { db in try link.insert(db) }
    }

    static func getLinkedItems(itemId: String) throws -> [Item] {
        try db.read { db in
            try Item.fetchAll(db, sql: """
                SELECT i.* FROM items i
                JOIN links l ON (l.toId = i.id AND l.fromId = ?) OR (l.fromId = i.id AND l.toId = ?)
                """, arguments: [itemId, itemId])
        }
    }

    static func removeLink(fromId: String, toId: String) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM links WHERE (fromId = ? AND toId = ?) OR (fromId = ? AND toId = ?)",
                arguments: [fromId, toId, toId, fromId]
            )
        }
    }

    static func getLinkCount(itemId: String) throws -> Int {
        try db.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM links WHERE fromId = ? OR toId = ?
                """, arguments: [itemId, itemId]) ?? 0
        }
    }

    static func getItemsWithUrls(done: Bool = false) throws -> [Item] {
        try db.read { db in
            try Item.fetchAll(db, sql: "SELECT * FROM items WHERE done = ? AND url IS NOT NULL AND url != '' ORDER BY createdAt DESC", arguments: [done])
        }
    }

    static func getResourceCount(itemId: String) throws -> Int {
        try db.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM links l
                JOIN items i ON (l.toId = i.id AND l.fromId = ?) OR (l.fromId = i.id AND l.toId = ?)
                WHERE i.category = 'resource' OR (i.url IS NOT NULL AND i.url != '')
                """, arguments: [itemId, itemId]) ?? 0
        }
    }

    static func getResourceCounts(itemIds: [String]) throws -> [String: Int] {
        guard !itemIds.isEmpty else { return [:] }
        return try db.read { db in
            let placeholders = itemIds.map { _ in "?" }.joined(separator: ",")
            let sql = """
                SELECT source_id, COUNT(*) as cnt FROM (
                    SELECT l.fromId as source_id, i.id as resource_id FROM links l
                    JOIN items i ON l.toId = i.id
                    WHERE l.fromId IN (\(placeholders))
                    AND (i.category = 'resource' OR (i.url IS NOT NULL AND i.url != ''))
                    UNION ALL
                    SELECT l.toId as source_id, i.id as resource_id FROM links l
                    JOIN items i ON l.fromId = i.id
                    WHERE l.toId IN (\(placeholders))
                    AND (i.category = 'resource' OR (i.url IS NOT NULL AND i.url != ''))
                ) GROUP BY source_id
                """
            let args = StatementArguments(itemIds + itemIds)
            var result: [String: Int] = [:]
            let rows = try Row.fetchAll(db, sql: sql, arguments: args)
            for row in rows {
                result[row["source_id"]] = row["cnt"]
            }
            return result
        }
    }

    static func searchResourceItems(query: String) throws -> [Item] {
        try db.read { db in
            try Item.fetchAll(db, sql: """
                SELECT * FROM items
                WHERE (category = 'resource' OR (url IS NOT NULL AND url != ''))
                AND (text LIKE ? OR url LIKE ? OR urlTitle LIKE ?)
                ORDER BY createdAt DESC LIMIT 10
                """, arguments: ["%\(query)%", "%\(query)%", "%\(query)%"])
        }
    }

    static func getAllLinks() throws -> [Link] {
        try db.read { db in try Link.fetchAll(db) }
    }

    // MARK: - Wins

    static func addWin(_ win: Win) throws {
        try db.write { db in try win.insert(db) }
    }

    static func getWin(itemId: String) throws -> Win? {
        try db.read { db in try Win.filter(Win.Columns.itemId == itemId).fetchOne(db) }
    }

    static func getAllWins() throws -> [Win] {
        try db.read { db in try Win.order(Win.Columns.createdAt.desc).fetchAll(db) }
    }

    static func deleteWin(id: String) throws {
        try db.write { db in _ = try Win.filter(Win.Columns.id == id).deleteAll(db) }
    }

    static func getWinCount() throws -> Int {
        try db.read { db in try Win.fetchCount(db) }
    }

    // MARK: - Daily Dumps

    static func getDump(date: String) throws -> DailyDump? {
        try db.read { db in
            try DailyDump.filter(DailyDump.Columns.date == date).fetchOne(db)
        }
    }

    static func getOrCreateTodayDump() throws -> DailyDump {
        let today = DailyDump.today()
        if let existing = try getDump(date: today) { return existing }
        let dump = DailyDump.new(date: today)
        try db.write { db in try dump.insert(db) }
        return dump
    }

    static func updateDumpContent(id: String, content: String) throws {
        try db.write { db in
            try db.execute(
                sql: "UPDATE daily_dumps SET content = ?, updatedAt = ? WHERE id = ?",
                arguments: [content, Date(), id]
            )
        }
    }

    static func appendToDump(date: String, bullet: String) throws {
        let dump = try getOrCreateTodayDump()
        let newContent = dump.content.isEmpty ? "• \(bullet)" : "\(dump.content)\n• \(bullet)"
        try updateDumpContent(id: dump.id, content: newContent)
    }

    static func getAllDumps() throws -> [DailyDump] {
        try db.read { db in
            try DailyDump.order(DailyDump.Columns.date.desc).fetchAll(db)
        }
    }

    static func toggleDumpLock(id: String) throws {
        try db.write { db in
            try db.execute(
                sql: "UPDATE daily_dumps SET locked = NOT locked, updatedAt = ? WHERE id = ?",
                arguments: [Date(), id]
            )
        }
    }
}
