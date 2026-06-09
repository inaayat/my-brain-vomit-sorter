import Foundation

struct CategorizeResult {
    let category: Category
    let tags: [String]
    let cleanedText: String
}

struct ClusterResult {
    var duplicateOf: String?
    var clusterId: String?
    var newCluster: Bool = false
}

struct AIService {
    private static let client = AnthropicClient.shared

    static func categorize(text: String) async throws -> CategorizeResult {
        if text.trimmingCharacters(in: .whitespaces).range(of: #"^https?://\S+$"#, options: .regularExpression) != nil {
            return CategorizeResult(category: .resource, tags: [], cleanedText: text.trimmingCharacters(in: .whitespaces))
        }

        let system = """
            You categorize user thoughts, extract topic tags, and clean up the language.
            Categories:
            - brainstorm: random ideas, musings, observations, questions to ponder
            - action: concrete tasks, things to do, deliverables, deadlines
            - resource: URLs, links, references, articles to read

            Tags: extract 1-3 short topic tags. Use system/project names when applicable (e.g. Jira, PowerBI, Workday, SOX). Lowercase, 1-2 words.

            cleaned_text: Rewrite the user's input to be clearer and more concise while preserving the original meaning. Fix typos, grammar, and awkward phrasing. Keep it natural — don't make it robotic. If the input is already clear, return it unchanged.

            Respond with ONLY valid JSON:
            {"category": "...", "tags": ["tag1"], "cleaned_text": "..."}
            """

        let response = try await client.send(system: system, userMessage: text, maxTokens: 400)
        let parsed = try parseJSON(response)

        let categoryStr = parsed["category"] as? String ?? "brainstorm"
        let category = Category(rawValue: categoryStr) ?? .brainstorm
        let tags = (parsed["tags"] as? [String] ?? []).prefix(5).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        let cleanedText = (parsed["cleaned_text"] as? String)?.trimmingCharacters(in: .whitespaces) ?? text

        return CategorizeResult(category: category, tags: Array(tags), cleanedText: cleanedText)
    }

    static func classifyAndCluster(text: String, itemId: String, category: Category) async throws -> ClusterResult {
        var result = ClusterResult()

        let allItems = try Queries.getAllItems()
        let others = allItems.filter { $0.id != itemId }
        guard !others.isEmpty else { return result }

        let clusters = try Queries.getClusters(category: category)

        let itemsText = others.prefix(40).map { "- id:\($0.id.prefix(8)) [\($0.category.rawValue)] \($0.text)" }.joined(separator: "\n")
        let clustersText = clusters.isEmpty ? "(no clusters yet)" :
            clusters.map { "- cluster:\($0.id.prefix(8)) \"\($0.title)\" (\($0.itemCount) items)" }.joined(separator: "\n")

        let system = """
            You organize thoughts into clusters and detect duplicates. Respond with ONLY valid JSON.

            Given a new item, existing items, and existing clusters, determine:
            1. Is this a near-duplicate of an existing item? (same idea, just worded differently)
            2. Does it fit an existing cluster? (same broad topic)
            3. If no cluster fits, are there 2+ unclustered items (including this one) on the same topic that should form a NEW cluster?

            Respond with:
            {
              "duplicate_of": "id_prefix or null",
              "fits_cluster": "cluster_id_prefix or null",
              "create_cluster_with": ["id_prefix1", "id_prefix2"] or null,
              "cluster_title": "Clean 2-5 word title" or null
            }

            Rules:
            - duplicate = essentially the same thought/task phrased differently (not just related)
            - Cluster titles: clean, concise 2-5 words, like a project or topic name
            - create_cluster_with: IDs of OTHER items that share the same topic/theme
            - Be AGGRESSIVE about clustering — if 2+ items share a topic, cluster them
            """

        let userMessage = """
            New item (id:\(itemId.prefix(8))): \(text)

            Existing items:
            \(itemsText)

            Existing clusters:
            \(clustersText)
            """

        let response = try await client.send(system: system, userMessage: userMessage, maxTokens: 400)
        guard let aiResult = try? parseJSON(response) else { return result }

        if let dupId = aiResult["duplicate_of"] as? String, dupId != "null" {
            if let dup = others.first(where: { $0.id.prefix(8) == dupId }) {
                result.duplicateOf = dup.id
            }
        }

        if let fits = aiResult["fits_cluster"] as? String, fits != "null" {
            if let cluster = clusters.first(where: { $0.id.prefix(8) == fits }) {
                try Queries.assignToCluster(itemId: itemId, clusterId: cluster.id)
                result.clusterId = cluster.id
                return result
            }
        }

        if let createWith = aiResult["create_cluster_with"] as? [String],
           let title = aiResult["cluster_title"] as? String,
           !createWith.isEmpty {
            var clusterTexts = [text]
            for item in others where createWith.contains(String(item.id.prefix(8))) {
                clusterTexts.append(item.text)
            }
            let summary = try await generateClusterSummary(title: title, texts: clusterTexts)
            let cluster = Cluster.new(title: title, category: category, summary: summary)
            try Queries.createCluster(cluster)
            try Queries.assignToCluster(itemId: itemId, clusterId: cluster.id)
            result.clusterId = cluster.id
            result.newCluster = true

            for item in others where createWith.contains(String(item.id.prefix(8))) && item.clusterId == nil {
                try Queries.assignToCluster(itemId: item.id, clusterId: cluster.id)
            }
        }

        return result
    }

    static func generateClusterTitle(texts: [String]) async throws -> String {
        let system = "Generate a clean, concise 2-5 word title that captures the theme of these items. Respond with ONLY the title, no quotes."
        let userMessage = texts.map { "- \($0)" }.joined(separator: "\n")
        let response = try await client.send(system: system, userMessage: userMessage, maxTokens: 50)
        return response.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
    }

    static func generateClusterSummary(title: String, texts: [String]) async throws -> String {
        let system = """
            Write a clear, well-written 1-2 sentence summary that synthesizes these raw thoughts into a coherent description. This is the polished "top-level" description. Write it as a clear statement of intent or direction, not a list. Respond with ONLY the summary.
            """
        let userMessage = "Topic: \(title)\n\nRaw inputs:\n" + texts.map { "- \($0)" }.joined(separator: "\n")
        return try await client.send(system: system, userMessage: userMessage, maxTokens: 150)
    }

    // MARK: - Helpers

    private static func parseJSON(_ raw: String) throws -> [String: Any] {
        let cleaned = cleanJSON(raw)
        guard let data = cleaned.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.parseError
        }
        return obj
    }

    private static func cleanJSON(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            let lines = s.components(separatedBy: "\n")
            s = lines.dropFirst().joined(separator: "\n")
            if let end = s.range(of: "```") { s = String(s[s.startIndex..<end.lowerBound]) }
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
