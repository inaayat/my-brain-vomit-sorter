import Foundation

struct ExportService {
    static func generateMarkdown() -> String {
        var md = "# MyMind Export\n"
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        md += "Exported: \(dateStr)\n\n"

        let allItems = (try? Queries.getAllItems()) ?? []
        let openItems = allItems.filter { !$0.done }
        let completedItems = allItems.filter { $0.done }

        // Open Items by priority
        md += "---\n\n## Open Items (\(openItems.count))\n\n"

        let highItems = openItems.filter { $0.priority == .high && $0.category != .resource }
        let medItems = openItems.filter { $0.priority == .medium && $0.category != .resource }
        let backlogItems = openItems.filter { $0.priority == .backlog && $0.category != .resource }
        let resources = openItems.filter { $0.category == .resource }

        if !highItems.isEmpty {
            md += "### High Priority\n\n"
            md += "| Item | Type | Due |\n|------|------|-----|\n"
            for item in highItems {
                let due = item.dueDate.map { formatDate($0) } ?? "—"
                md += "| \(escape(item.text)) | \(item.category.rawValue) | \(due) |\n"
            }
            md += "\n"
        }

        if !medItems.isEmpty {
            md += "### Medium Priority\n\n"
            md += "| Item | Type | Due |\n|------|------|-----|\n"
            for item in medItems {
                let due = item.dueDate.map { formatDate($0) } ?? "—"
                md += "| \(escape(item.text)) | \(item.category.rawValue) | \(due) |\n"
            }
            md += "\n"
        }

        if !backlogItems.isEmpty {
            md += "### Backlog\n\n"
            md += "| Item | Type |\n|------|------|\n"
            for item in backlogItems {
                md += "| \(escape(item.text)) | \(item.category.rawValue) |\n"
            }
            md += "\n"
        }

        if !resources.isEmpty {
            md += "### Resources\n\n"
            for item in resources {
                let title = item.urlTitle ?? item.text
                if let url = item.url, !url.isEmpty {
                    md += "- [\(escape(title))](\(url))\n"
                } else {
                    md += "- \(escape(title))\n"
                }
            }
            md += "\n"
        }

        // Clusters
        let clusters = (try? Queries.getAllClustersWithItems()) ?? []
        if !clusters.isEmpty {
            md += "---\n\n## Clusters (\(clusters.count))\n\n"
            for cluster in clusters {
                md += "### \(escape(cluster.title))\n"
                if let summary = cluster.summary, !summary.isEmpty {
                    md += "> \(escape(summary))\n"
                }
                let clusterItems = allItems.filter { $0.clusterId == cluster.id }
                for item in clusterItems {
                    let status = item.done ? "[x]" : "[ ]"
                    md += "- \(status) \(escape(item.text))\n"
                }
                md += "\n"
            }
        }

        // Wins
        let wins = (try? Queries.getAllWins()) ?? []
        if !wins.isEmpty {
            md += "---\n\n## Wins (\(wins.count))\n\n"
            md += "| Achievement | Artifact | Date |\n|-------------|----------|------|\n"
            for win in wins {
                let value = win.valueAdd ?? "Win logged"
                let artifact = win.artifact ?? "—"
                let date = formatDate(win.createdAt)
                md += "| \(escape(value)) | \(escape(artifact)) | \(date) |\n"
            }
            md += "\n"
        }

        // Daily Dumps
        let dumps = (try? Queries.getAllDumps()) ?? []
        if !dumps.isEmpty {
            md += "---\n\n## Daily Dumps (\(dumps.count) days)\n\n"
            for dump in dumps {
                md += "### \(DailyDump.displayDate(dump.date))\n\n"
                md += dump.content + "\n\n"
            }
        }

        // Completed
        if !completedItems.isEmpty {
            md += "---\n\n## Completed (\(completedItems.count))\n\n"
            for item in completedItems {
                md += "- [x] \(escape(item.text))\n"
            }
            md += "\n"
        }

        return md
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
