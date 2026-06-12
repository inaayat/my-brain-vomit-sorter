import SwiftUI

struct DailyDumpView: View {
    @Bindable var appState: AppState
    @State private var todayDump: DailyDump?
    @State private var pastDumps: [DailyDump] = []
    @State private var content = ""
    @State private var isAnalyzing = false
    @State private var proposedItems: [ProposedItem] = []
    @State private var suggestedTags: [AIService.SuggestedTag] = []
    @State private var expandedPastDays: Set<String> = []
    @State private var showGuide = false
    @State private var searchTag: String? = nil
    @State private var tagFilter = ""
    @State private var mergeTarget: String? = nil
    @State private var showMergeConfirm = false
    @State private var mergeSource: String? = nil
    @State private var editingTag: String? = nil
    @State private var editedTagName = ""
    @State private var showRetired = false
    @State private var reviewClusters: [Cluster] = []
    @State private var showMasterDocPanel = false
    @State private var isUpdating = false

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    tagBar
                    if let tag = searchTag {
                        tagSearchResults(tag: tag)
                    } else {
                        guideBar
                        todaySection
                        if !suggestedTags.isEmpty { tagSuggestionsSection }
                    if !proposedItems.isEmpty { reviewSection }
                        if !pastDumps.isEmpty { pastSection }
                    }
                }
                .padding(28)
            }
            .background(Theme.bg)

            if showMasterDocPanel, let tag = searchTag {
                Divider()
                MasterDocPanelView(appState: appState, tag: tag, onClose: {
                    withAnimation { showMasterDocPanel = false }
                })
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { reload() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Dump")
                    .font(.inter(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(DailyDump.displayDate(DailyDump.today()))
                    .font(.inter(12))
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()

            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    analyze()
                } label: {
                    HStack(spacing: 5) {
                        if isAnalyzing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Analyze with AI")
                    }
                    .font(.inter(12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.purple)
                .controlSize(.small)
                .disabled(isAnalyzing)
            }
        }
    }

    // MARK: - Guide bar

    private var guideBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showGuide.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11))
                    Text("How to use the Daily Dump")
                        .font(.inter(11, weight: .medium))
                    Spacer()
                    Image(systemName: showGuide ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.softGray.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if showGuide {
                VStack(alignment: .leading, spacing: 6) {
                    guideItem("Type freely below — each line is a bullet point")
                    guideItem("Use #tags inline to categorize (e.g. #accounting-center, #workday)")
                    guideItem("Press Ctrl+Option+N from anywhere to quick-add a bullet")
                    guideItem("Hit 'Analyze with AI' to parse your dump into action items & brainstorms")
                    guideItem("Past days are read-only — click 'Unlock' to edit them")
                }
                .padding(12)
                .background(Theme.softGray.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 4)
            }
        }
    }

    private func guideItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.inter(11))
                .foregroundStyle(Theme.purple)
            Text(text)
                .font(.inter(11))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Tag Bar & Search

    private var tagBar: some View {
        let allTags = collectAllTags()
        let filteredTags = tagFilter.isEmpty ? allTags : allTags.filter { $0.localizedCaseInsensitiveContains(tagFilter) }
        return Group {
            if !allTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    if allTags.count > 8 {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textMuted)
                            TextField("Filter tags...", text: $tagFilter)
                                .textFieldStyle(.plain)
                                .font(.inter(11))
                                .frame(maxWidth: 180)
                            if !tagFilter.isEmpty {
                                Button {
                                    tagFilter = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.softGray.opacity(0.5), in: Capsule())
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(filteredTags, id: \.self) { tag in
                                tagPill(tag)
                            }

                            if searchTag != nil {
                                Button {
                                    withAnimation { searchTag = nil }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                        Text("Clear")
                                            .font(.inter(10))
                                    }
                                    .foregroundStyle(Theme.textMuted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.softGray, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if allTags.count > 8 {
                        Text("Drag a tag onto another to merge them")
                            .font(.inter(9))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .alert("Merge Tags", isPresented: $showMergeConfirm) {
                    Button("Merge") { performMerge() }
                    Button("Cancel", role: .cancel) { mergeSource = nil; mergeTarget = nil }
                } message: {
                    if let src = mergeSource, let tgt = mergeTarget {
                        Text("Replace all #\(src) with #\(tgt)? This updates every bullet across all days.")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tagPill(_ tag: String) -> some View {
        let isSelected = searchTag == tag
        if editingTag == tag {
            HStack(spacing: 3) {
                Image(systemName: "number")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.purple)
                TextField("", text: $editedTagName)
                    .textFieldStyle(.plain)
                    .font(.inter(10, weight: .medium))
                    .frame(minWidth: 50, maxWidth: 120)
                    .onSubmit { commitTagRename(from: tag) }
                Button {
                    commitTagRename(from: tag)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.greenDark)
                }
                .buttonStyle(.plain)
                Button {
                    editingTag = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.purple.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.purple, lineWidth: 1))
        } else {
            HStack(spacing: 3) {
                Image(systemName: "number")
                    .font(.system(size: 8, weight: .bold))
                Text(tag)
                    .font(.inter(10, weight: .medium))
                Text("(\(tagCount(tag)))")
                    .font(.inter(9))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : Theme.textMuted)
            }
            .foregroundStyle(isSelected ? .white : Theme.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected ? Theme.purple : Theme.purple.opacity(0.1),
                in: Capsule()
            )
            .overlay(
                mergeTarget == tag ? Capsule().strokeBorder(Theme.greenDark, lineWidth: 2) : nil
            )
            .onTapGesture(count: 2) {
                editingTag = tag
                editedTagName = tag
            }
            .onTapGesture(count: 1) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    searchTag = (searchTag == tag) ? nil : tag
                }
            }
            .draggable(tag)
            .dropDestination(for: String.self) { dropped, _ in
                guard let source = dropped.first, source != tag else { return false }
                let srcCount = tagCount(source)
                let tgtCount = tagCount(tag)
                if srcCount > tgtCount {
                    mergeSource = tag
                    mergeTarget = source
                } else {
                    mergeSource = source
                    mergeTarget = tag
                }
                showMergeConfirm = true
                return true
            } isTargeted: { targeted in
                mergeTarget = targeted ? tag : nil
            }
        }
    }

    @ViewBuilder
    private func tagSearchResults(tag: String) -> some View {
        let allResults = findBulletsByTag(tag, includeRetired: true)
        let visibleResults = showRetired ? allResults : allResults.filter { !$0.isRetired }
        let retiredCount = allResults.filter(\.isRetired).count
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "number")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.purple)
                Text(tag)
                    .font(.inter(16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(allResults.count - retiredCount) bullets")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Button {
                    withAnimation { showMasterDocPanel.toggle() }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 9))
                        Text("Master Doc")
                            .font(.inter(9, weight: .medium))
                    }
                    .foregroundStyle(Theme.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.purple.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)

                if retiredCount > 0 {
                    Button {
                        withAnimation { showRetired.toggle() }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: showRetired ? "eye.slash" : "eye")
                                .font(.system(size: 9))
                            Text(showRetired ? "Hide retired (\(retiredCount))" : "Show retired (\(retiredCount))")
                                .font(.inter(9, weight: .medium))
                        }
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.softGray.opacity(0.5), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if visibleResults.isEmpty {
                Text("No bullets found with this tag.")
                    .font(.inter(13))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.top, 20)
            } else {
                ForEach(visibleResults, id: \.id) { result in
                    tagResultRow(result)
                }
            }
        }
    }

    @ViewBuilder
    private func tagResultRow(_ result: TagSearchResult) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.dateDisplay)
                    .font(.inter(10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                Text(stripTags(result.bulletText))
                    .font(.inter(13))
                    .foregroundStyle(result.isRetired ? Theme.textMuted : Theme.textPrimary)
                    .strikethrough(result.isRetired)
                    .textSelection(.enabled)
            }
            Spacer()
            if showMasterDocPanel, let tag = searchTag {
                Button {
                    appendBulletToMasterDoc(text: result.bulletText, tag: tag)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.purple)
                }
                .buttonStyle(.plain)
                .help("Add to Master Doc")
            }
            Button {
                toggleRetire(result: result)
            } label: {
                Image(systemName: result.isRetired ? "arrow.uturn.backward.circle" : "archivebox")
                    .font(.system(size: 14))
                    .foregroundStyle(result.isRetired ? Theme.greenDark : Theme.textMuted)
            }
            .buttonStyle(.plain)
            .help(result.isRetired ? "Unretire" : "Retire")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(result.isRetired ? Theme.softGray.opacity(0.3) : Theme.cardBg, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Today's editor

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.inter(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(bulletCount) bullets")
                    .font(.inter(10))
                    .foregroundStyle(Theme.textMuted)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $content)
                    .font(.inter(13))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200, maxHeight: 400)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1))
                    .onChange(of: content) { _, newValue in
                        handleContentChange(newValue)
                        saveDraft()
                    }

                if content.isEmpty {
                    Text("• Start typing your thoughts...")
                        .font(.inter(13))
                        .foregroundStyle(Theme.textMuted)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }

            // Tag summary
            let tags = allTags
            if !tags.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.inter(10, weight: .medium))
                            .foregroundStyle(Theme.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.purple.opacity(0.1), in: Capsule())
                    }
                }
            }
        }
    }

    // MARK: - AI Review Section

    // MARK: - Tag Suggestions

    private var tagSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.purple)
                Text("Suggested Tags")
                    .font(.inter(12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Dismiss") {
                    withAnimation { suggestedTags.removeAll() }
                }
                .font(.inter(10))
                .foregroundStyle(Theme.textMuted)
            }

            ForEach(Array(suggestedTags.enumerated()), id: \.offset) { index, suggestion in
                tagSuggestionRow(index: index, suggestion: suggestion)
            }
        }
    }

    @ViewBuilder
    private func tagSuggestionRow(index: Int, suggestion: AIService.SuggestedTag) -> some View {
        HStack(spacing: 8) {
            Text(stripTags(suggestion.bulletText))
                .font(.inter(11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
            Spacer()
            Text("#\(suggestion.tag)")
                .font(.inter(10, weight: .bold))
                .foregroundStyle(Theme.purple)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.purple.opacity(0.1), in: Capsule())
            Button {
                applyTagSuggestion(index: index, suggestion: suggestion)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.greenDark)
            }
            .buttonStyle(.plain)
            Button {
                _ = withAnimation { suggestedTags.remove(at: index) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Theme.softGray.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    private func applyTagSuggestion(index: Int, suggestion: AIService.SuggestedTag) {
        // Append the #tag to the matching bullet in content
        let lines = content.components(separatedBy: "\n")
        let updated = lines.map { line -> String in
            let stripped = line.hasPrefix("• ") ? String(line.dropFirst(2)) : line
            if stripped.trimmingCharacters(in: .whitespaces) == suggestion.bulletText.trimmingCharacters(in: .whitespaces) {
                return line + " #\(suggestion.tag)"
            }
            return line
        }
        content = updated.joined(separator: "\n")
        saveDraft()
        _ = withAnimation { suggestedTags.remove(at: index) }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Proposed Items")
                    .font(.inter(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Dismiss All") {
                    withAnimation { proposedItems.removeAll() }
                }
                .font(.inter(10))
                .foregroundStyle(Theme.textMuted)
            }

            ForEach(Array(proposedItems.enumerated()), id: \.element.id) { index, proposed in
                proposedRow(index: index, proposed: proposed)
            }
        }
    }

    @ViewBuilder
    private func proposedRow(index: Int, proposed: ProposedItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                // Category picker — tap to cycle
                Button {
                    cycleCategory(at: index)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon(proposedItems[index].category, isWin: proposedItems[index].isWin))
                            .font(.system(size: 9, weight: .semibold))
                        Text(proposedItems[index].isWin ? "Win" : proposedItems[index].category.rawValue.capitalized)
                            .font(.inter(10, weight: .semibold))
                    }
                    .foregroundStyle(categoryLabelColor(proposedItems[index].category, isWin: proposedItems[index].isWin))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryLabelColor(proposedItems[index].category, isWin: proposedItems[index].isWin).opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)

                Text(proposed.text)
                    .font(.inter(12))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                Spacer()

                // Cluster picker
                Picker("", selection: $proposedItems[index].clusterId) {
                    Text("No cluster").tag(nil as String?)
                    ForEach(reviewClusters) { cluster in
                        Text(cluster.title).tag(cluster.id as String?)
                    }
                }
                .pickerStyle(.menu)
                .font(.inter(10))
                .frame(maxWidth: 140)

                Button {
                    acceptItem(at: index)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.greenDark)
                }
                .buttonStyle(.plain)
                Button {
                    _ = withAnimation { proposedItems.remove(at: index) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }

            if !proposed.tags.isEmpty {
                HStack(spacing: 3) {
                    ForEach(proposed.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.inter(9))
                            .foregroundStyle(Theme.purple)
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(proposedItemBg(proposed.category)))
    }

    private func cycleCategory(at index: Int) {
        let order: [(Category, Bool)] = [(.action, false), (.brainstorm, false), (.resource, false), (.action, true)]
        let current = (proposedItems[index].category, proposedItems[index].isWin)
        let currentIdx = order.firstIndex(where: { $0.0 == current.0 && $0.1 == current.1 }) ?? 0
        let next = order[(currentIdx + 1) % order.count]
        proposedItems[index].category = next.0
        proposedItems[index].isWin = next.1
    }

    private func categoryIcon(_ category: Category, isWin: Bool) -> String {
        if isWin { return "trophy.fill" }
        switch category {
        case .action: return "bolt.fill"
        case .brainstorm: return "cloud.bolt.fill"
        case .resource: return "link"
        case .revisit: return "arrow.counterclockwise"
        }
    }

    private func categoryLabelColor(_ category: Category, isWin: Bool) -> Color {
        if isWin { return Theme.yellowDark }
        switch category {
        case .action: return Theme.greenDark
        case .brainstorm: return Theme.pinkDark
        case .resource: return Theme.blueDark
        case .revisit: return Theme.yellowDark
        }
    }

    // MARK: - Past Days

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Past Days")
                .font(.inter(14, weight: .semibold))
                .foregroundStyle(Theme.textMuted)

            ForEach(pastDumps) { dump in
                pastDayRow(dump)
            }
        }
    }

    @ViewBuilder
    private func pastDayRow(_ dump: DailyDump) -> some View {
        let isExpanded = expandedPastDays.contains(dump.date)
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expandedPastDays.remove(dump.date) }
                    else { expandedPastDays.insert(dump.date) }
                }
            } label: {
                HStack {
                    Text(DailyDump.displayDate(dump.date))
                        .font(.inter(12, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    let count = dump.content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                    Text("\(count) bullets")
                        .font(.inter(10))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.softGray.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dump.content)
                        .font(.inter(12))
                        .foregroundStyle(Theme.textSecondary)
                        .textSelection(.enabled)
                        .padding(12)

                    HStack {
                        if dump.locked {
                            Button("Unlock to edit") {
                                try? Queries.toggleDumpLock(id: dump.id)
                                reload()
                            }
                            .font(.inter(10))
                            .foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                        Button {
                            analyzePastDump(dump)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Analyze with AI")
                            }
                            .font(.inter(10, weight: .semibold))
                            .foregroundStyle(Theme.purple)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Logic

    private func proposedItemBg(_ category: Category) -> Color {
        if category == .action {
            return Color(Theme.greenTint).opacity(0.4)
        }
        return Color(Theme.pinkTint).opacity(0.4)
    }

    private var bulletCount: Int {
        content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }

    private var allTags: [String] {
        let bullets = DumpBullet.parse(from: content)
        let tags = bullets.flatMap(\.tags)
        return Array(Set(tags)).sorted()
    }

    private func stripTags(_ text: String) -> String {
        text.replacingOccurrences(of: #"#[\w\-]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    private func collectAllTags() -> [String] {
        var allDumps = pastDumps
        if let today = todayDump { allDumps.insert(today, at: 0) }
        var tagSet = Set<String>()
        for dump in allDumps {
            let bullets = DumpBullet.parse(from: dump.content)
            for bullet in bullets {
                tagSet.formUnion(bullet.tags)
            }
        }
        return tagSet.sorted()
    }

    private func tagCount(_ tag: String) -> Int {
        var allDumps = pastDumps
        if let today = todayDump { allDumps.insert(today, at: 0) }
        var count = 0
        for dump in allDumps {
            let bullets = DumpBullet.parse(from: dump.content)
            count += bullets.filter { $0.tags.contains(tag) && !$0.isRetired }.count
        }
        return count
    }

    private func performMerge() {
        guard let source = mergeSource, let target = mergeTarget else { return }
        let hashSource = "#\(source)"
        let hashTarget = "#\(target)"

        // Replace in today's content
        content = content.replacingOccurrences(of: hashSource, with: hashTarget)
        saveDraft()

        // Replace in all past dumps
        for dump in pastDumps {
            let updated = dump.content.replacingOccurrences(of: hashSource, with: hashTarget)
            if updated != dump.content {
                try? Queries.updateDumpContent(id: dump.id, content: updated)
            }
        }

        mergeSource = nil
        mergeTarget = nil
        reload()
    }

    private func commitTagRename(from oldTag: String) {
        let newTag = editedTagName
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "#", with: "")
        guard !newTag.isEmpty, newTag != oldTag else {
            editingTag = nil
            return
        }
        let hashOld = "#\(oldTag)"
        let hashNew = "#\(newTag)"

        content = content.replacingOccurrences(of: hashOld, with: hashNew)
        saveDraft()

        for dump in pastDumps {
            let updated = dump.content.replacingOccurrences(of: hashOld, with: hashNew)
            if updated != dump.content {
                try? Queries.updateDumpContent(id: dump.id, content: updated)
            }
        }

        editingTag = nil
        if searchTag == oldTag { searchTag = newTag }
        reload()
    }

    private func findBulletsByTag(_ tag: String, includeRetired: Bool = false) -> [TagSearchResult] {
        var results: [TagSearchResult] = []
        var allDumps = pastDumps
        if let today = todayDump { allDumps.insert(today, at: 0) }
        for dump in allDumps {
            let bullets = DumpBullet.parse(from: dump.content)
            for bullet in bullets where bullet.tags.contains(tag) {
                results.append(TagSearchResult(
                    id: UUID(),
                    dumpId: dump.id,
                    date: dump.date,
                    dateDisplay: DailyDump.displayDate(dump.date),
                    bulletText: bullet.text,
                    rawLine: bullet.rawLine,
                    isRetired: bullet.isRetired
                ))
            }
        }
        return results
    }

    private func toggleRetire(result: TagSearchResult) {
        let marker = DumpBullet.retiredMarker
        let isToday = result.date == DailyDump.today()

        if result.isRetired {
            let restored = result.rawLine.replacingOccurrences(of: marker, with: "")
            if isToday {
                content = content.replacingOccurrences(of: result.rawLine, with: restored)
                saveDraft()
            } else {
                if let dump = pastDumps.first(where: { $0.id == result.dumpId }) {
                    let updated = dump.content.replacingOccurrences(of: result.rawLine, with: restored)
                    try? Queries.updateDumpContent(id: dump.id, content: updated)
                }
            }
        } else {
            let retired = result.rawLine + marker
            if isToday {
                content = content.replacingOccurrences(of: result.rawLine, with: retired)
                saveDraft()
            } else {
                if let dump = pastDumps.first(where: { $0.id == result.dumpId }) {
                    let updated = dump.content.replacingOccurrences(of: result.rawLine, with: retired)
                    try? Queries.updateDumpContent(id: dump.id, content: updated)
                }
            }
        }
        reload()
    }

    private func handleContentChange(_ newValue: String) {
        guard !isUpdating else { return }

        var updated = newValue

        // Replace "* " or standalone "*" at line starts with "• "
        updated = updated.replacingOccurrences(of: "\n* ", with: "\n• ")
        updated = updated.replacingOccurrences(of: "\n*", with: "\n• ")
        if updated.hasPrefix("* ") { updated = "• " + String(updated.dropFirst(2)) }
        if updated == "*" { updated = "• " }

        // First character on empty — ensure bullet prefix
        if !updated.isEmpty && !updated.hasPrefix("• ") && !updated.contains("\n") {
            updated = "• " + updated
        }

        // Enter pressed — new bullet on new line
        if updated.hasSuffix("\n") {
            updated += "• "
        }

        if updated != newValue {
            isUpdating = true
            content = updated
            DispatchQueue.main.async { isUpdating = false }
        }
    }

    private func saveDraft() {
        guard let dump = todayDump else { return }
        try? Queries.updateDumpContent(id: dump.id, content: content)
    }

    private func reload() {
        todayDump = try? Queries.getOrCreateTodayDump()
        content = todayDump?.content ?? ""
        let all = (try? Queries.getAllDumps()) ?? []
        pastDumps = all.filter { $0.date != DailyDump.today() }
    }

    private func analyze() {
        isAnalyzing = true
        Task {
            do {
                let result = try await AIService.analyzeDump(content: content)
                await MainActor.run {
                    proposedItems = result.proposedItems
                    suggestedTags = result.suggestedTags
                    reviewClusters = (try? Queries.getAllClustersWithItems()) ?? []
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run { isAnalyzing = false }
            }
        }
    }

    private func appendBulletToMasterDoc(text: String, tag: String) {
        let existing = try? Queries.getMasterDoc(tag: tag)
        let currentContent = existing?.content ?? ""
        let title = existing?.title ?? tag.replacingOccurrences(of: "-", with: " ").capitalized
        let bullet = "• \(stripTags(text))"
        let newContent = currentContent.isEmpty ? bullet : currentContent + "\n" + bullet
        try? Queries.upsertMasterDoc(tag: tag, content: newContent, title: title)
    }

    private func analyzePastDump(_ dump: DailyDump) {
        isAnalyzing = true
        Task {
            do {
                let result = try await AIService.analyzeDump(content: dump.content)
                await MainActor.run {
                    proposedItems = result.proposedItems
                    reviewClusters = (try? Queries.getAllClustersWithItems()) ?? []
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run { isAnalyzing = false }
            }
        }
    }

    private func acceptItem(at index: Int) {
        let proposed = proposedItems[index]

        if proposed.isWin {
            var item = Item.new(text: proposed.text, category: .action)
            item.done = true
            item.doneAt = Date()
            if !proposed.tags.isEmpty {
                item.tags = try? String(data: JSONEncoder().encode(proposed.tags), encoding: .utf8)
            }
            try? Queries.addItem(item)
            let win = Win.new(itemId: item.id, artifact: nil, valueAdd: proposed.text)
            try? Queries.addWin(win)
        } else {
            var item = Item.new(text: proposed.text, category: proposed.category)
            if !proposed.tags.isEmpty {
                item.tags = try? String(data: JSONEncoder().encode(proposed.tags), encoding: .utf8)
            }
            if let clusterId = proposed.clusterId {
                item.clusterId = clusterId
            }
            try? Queries.addItem(item)
            if proposed.clusterId == nil {
                Task { _ = try? await AIService.classifyAndCluster(text: proposed.text, itemId: item.id, category: item.category) }
            }
        }

        appState.refreshCounts()
        _ = withAnimation { proposedItems.remove(at: index) }
    }
}

struct ProposedItem: Identifiable {
    let id = UUID()
    var text: String
    var category: Category
    var isWin: Bool
    let tags: [String]
    let originalText: String
    var clusterId: String?
}

struct TagSearchResult: Identifiable {
    let id: UUID
    let dumpId: String
    let date: String
    let dateDisplay: String
    let bulletText: String
    let rawLine: String
    let isRetired: Bool
}
