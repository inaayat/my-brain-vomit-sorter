import Foundation

struct CategorizeResult {
    let category: Category
    let tags: [String]
    let cleanedText: String
}

struct NoteSuggestionsResult {
    let actions: [String]
    let brainstorms: [String]
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

    static func analyzeNotes(itemText: String, notes: String) async throws -> NoteSuggestionsResult {
        let system = """
            You analyze notes attached to a task and extract:
            1. Follow-up action items (concrete, specific tasks to do)
            2. Brainstorm ideas (observations, questions, directions to explore)
            Respond ONLY with valid JSON:
            {"actions": ["...", "..."], "brainstorms": ["...", "..."]}
            Keep suggestions concise (1 sentence each). Return empty arrays if nothing applies.
            """
        let userMessage = "Task: \(itemText)\n\nNotes:\n\(notes)"
        let response = try await client.send(system: system, userMessage: userMessage, maxTokens: 600)
        let parsed = try parseJSON(response)
        let actions = (parsed["actions"] as? [String] ?? []).map { $0.trimmingCharacters(in: .whitespaces) }
        let brainstorms = (parsed["brainstorms"] as? [String] ?? []).map { $0.trimmingCharacters(in: .whitespaces) }
        return NoteSuggestionsResult(actions: actions, brainstorms: brainstorms)
    }

    struct AnalyzeResult {
        var proposedItems: [ProposedItem]
        var suggestedTags: [SuggestedTag]
    }

    struct SuggestedTag {
        let bulletText: String
        let tag: String
    }

    static func analyzeDump(content: String) async throws -> AnalyzeResult {
        let system = """
            You analyze a daily brain-dump (bullet-pointed thoughts). You do two things:

            1. EXTRACT ITEMS: For each meaningful bullet, propose it as a MyMind item:
            - text: a CLEAR, professional rewrite of the thought — full sentence, no filler words, no hedging language ("maybe", "I think", "probably"), no shorthand or abbreviations. Transform casual notes into actionable, precise language. Example: "follow up w/ Sarah re budget thing" becomes "Follow up with Sarah regarding Q3 budget approval"
            - category: one of "action" (concrete task), "brainstorm" (idea/observation), "win" (achievement/accomplishment), or "resource" (URL/reference/article)
            - tags: 1-3 short topic tags (lowercase, use exact project/system names like "workday", "accounting-center", "jira")
            - original_text: the exact source bullet text

            2. SUGGEST TAGS: For bullets that don't already have a #tag, suggest what tag should be appended. Look for exact recurring words, project names, meeting names, or topic areas across all bullets.

            Respond with ONLY valid JSON:
            {
              "items": [{"text": "...", "category": "action", "tags": ["tag1"], "original_text": "..."}],
              "suggested_tags": [{"bullet": "exact bullet text", "tag": "suggested-tag"}]
            }

            Rules:
            - Don't create items from trivial/filler bullets
            - Preserve existing #hashtags as tags
            - If a bullet already has a #tag, don't suggest a tag for it
            - Tags should be specific and reusable (project names, meeting names, topics)
            - Look for patterns: if multiple bullets mention the same project/topic, suggest that as a tag
            - Return empty arrays if nothing applies
            """

        let response = try await client.send(system: system, userMessage: content, maxTokens: 3000)
        let cleaned = cleanJSON(response)
        guard let data = cleaned.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return AnalyzeResult(proposedItems: [], suggestedTags: [])
        }

        let items: [ProposedItem] = ((obj["items"] as? [[String: Any]]) ?? []).compactMap { item in
            guard let text = item["text"] as? String,
                  let categoryStr = item["category"] as? String else { return nil }
            let isWin = categoryStr == "win"
            let category: Category
            switch categoryStr {
            case "action": category = .action
            case "brainstorm": category = .brainstorm
            case "resource": category = .resource
            case "win": category = .action
            default: category = .brainstorm
            }
            let tags = (item["tags"] as? [String])?.map { $0.lowercased() } ?? []
            let originalText = item["original_text"] as? String ?? text
            return ProposedItem(text: text, category: category, isWin: isWin, tags: tags, originalText: originalText)
        }

        let suggestedTags: [SuggestedTag] = ((obj["suggested_tags"] as? [[String: Any]]) ?? []).compactMap { st in
            guard let bullet = st["bullet"] as? String,
                  let tag = st["tag"] as? String else { return nil }
            return SuggestedTag(bulletText: bullet, tag: tag.lowercased())
        }

        return AnalyzeResult(proposedItems: items, suggestedTags: suggestedTags)
    }

    // MARK: - Master Doc Synthesis

    static func synthesizeMasterDoc(existingContent: String, bullets: String) async throws -> String {
        let system = """
            You organize notes into a clean, well-structured document. Your output should be well-formatted Markdown.
            Use headings (##, ###) to group by theme. Use bullet points for individual items. Use clear, professional language.
            Preserve ALL information from the input — do not drop anything.
            Remove duplicates. Merge related points under the same heading.
            If there is existing document content, integrate the new bullets into the existing structure rather than appending at the end.
            Return ONLY the final document content (no explanation, no preamble).
            """
        var userMessage = ""
        if !existingContent.isEmpty {
            userMessage += "EXISTING DOCUMENT:\n\(existingContent)\n\n"
        }
        userMessage += "BULLETS TO INTEGRATE:\n\(bullets)"
        return try await client.send(system: system, userMessage: userMessage, maxTokens: 4000)
    }

    // MARK: - Redundancy Cleanup

    struct RedundancyGroup: Identifiable {
        let id = UUID()
        let itemIds: [String]
        let reason: String
        let mergedText: String
    }

    static func findRedundancies(items: [(id: String, text: String, category: String)]) async throws -> [RedundancyGroup] {
        guard !items.isEmpty else { return [] }
        let itemsJSON = items.map { "{\"id\":\"\($0.id)\",\"text\":\"\($0.text.replacingOccurrences(of: "\"", with: "'"))\",\"category\":\"\($0.category)\"}" }.joined(separator: ",")
        let system = """
            You analyze a list of task/brainstorm items and find groups of redundant or near-duplicate entries.
            Two items are redundant if they say essentially the same thing, one is a subset of the other, or they refer to the same action with different wording.

            For each group found:
            - ids: the item IDs that are redundant with each other (minimum 2)
            - reason: one short sentence explaining why they're duplicates
            - merged_text: a single clean sentence that captures all the meaning from the group

            Respond with ONLY valid JSON:
            [{"ids": ["id1", "id2"], "reason": "...", "merged_text": "..."}]

            If no redundancies exist, return an empty array: []
            Only flag CLEAR duplicates — don't group items that are merely related to the same topic.
            """

        let response = try await client.send(system: system, userMessage: "[\(itemsJSON)]", maxTokens: 2000)
        let cleaned = cleanJSON(response)
        guard let data = cleaned.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return arr.compactMap { obj in
            guard let ids = obj["ids"] as? [String], ids.count >= 2,
                  let reason = obj["reason"] as? String,
                  let mergedText = obj["merged_text"] as? String else { return nil }
            return RedundancyGroup(itemIds: ids, reason: reason, mergedText: mergedText)
        }
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
