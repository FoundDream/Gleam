//
//  MainWindowView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// Main Window View
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $appState.searchText, prompt: "搜索笔记、截图...")
        .sheet(isPresented: $appState.showQuickNoteWindow) {
            QuickNoteSheet()
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: $appState.selectedTab) {
            Section("内容") {
                ForEach(SidebarTab.allCases) { tab in
                    Label {
                        HStack {
                            Text(tab.rawValue)
                            Spacer()
                            Text(countFor(tab))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(10)
                        }
                    } icon: {
                        Image(systemName: tab.icon)
                            .foregroundColor(colorFor(tab))
                    }
                    .tag(tab)
                }
            }

            Section("标签") {
                ForEach(allTags, id: \.self) { tag in
                    Label(tag, systemImage: "tag")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem {
                Button {
                    appState.showQuickNoteWindow = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func countFor(_ tab: SidebarTab) -> String {
        switch tab {
        case .quickNotes:
            return "\(appState.quickNotes.count)"
        case .screenshots:
            return "\(appState.screenshots.count)"
        case .translationHistory:
            return "\(appState.translationHistory.count)"
        }
    }

    private func colorFor(_ tab: SidebarTab) -> Color {
        switch tab {
        case .quickNotes: return .orange
        case .screenshots: return .purple
        case .translationHistory: return .blue
        }
    }

    private var allTags: [String] {
        var tags = Set<String>()
        appState.screenshots.forEach { tags.formUnion($0.tags) }
        return Array(tags).sorted()
    }
}

// MARK: - Detail View

struct DetailView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.selectedTab {
        case .quickNotes:
            QuickNotesView()
        case .screenshots:
            ScreenshotsView()
        case .translationHistory:
            TranslationHistoryView()
        }
    }
}

// MARK: - QuickNotes View (随手记列表)

struct QuickNotesView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedNote: QuickNote?

    var body: some View {
        HSplitView {
            // 列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(appState.filteredQuickNotes) { note in
                        QuickNoteCard(note: note, isSelected: selectedNote?.id == note.id)
                            .onTapGesture {
                                selectedNote = note
                            }
                    }
                }
                .padding()
            }
            .frame(minWidth: 300)

            // 详情
            if let note = selectedNote {
                QuickNoteDetailView(note: note)
                    .frame(minWidth: 300)
            } else {
                EmptyDetailView(
                    icon: "note.text",
                    title: "选择一条笔记",
                    subtitle: "点击列表查看详情"
                )
                .frame(minWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    appState.showQuickNoteWindow = true
                } label: {
                    Label("新建笔记", systemImage: "plus")
                }

                Spacer()

                Picker("排序", selection: .constant("date")) {
                    Text("按时间").tag("date")
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
        }
    }
}

// MARK: - QuickNote Card (随手记卡片)

struct QuickNoteCard: View {
    let note: QuickNote
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                    .font(.title3)

                Text(previewTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(note.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(note.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    private var previewTitle: String {
        let firstLine = note.content.components(separatedBy: .newlines).first ?? note.content
        if firstLine.count > 30 {
            return String(firstLine.prefix(30)) + "..."
        }
        return firstLine
    }
}

// MARK: - QuickNote Detail (随手记详情)

struct QuickNoteDetailView: View {
    let note: QuickNote
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false
    @State private var editedContent: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 顶部工具栏
                HStack {
                    Image(systemName: "note.text")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading) {
                        Text("随手记")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("创建于 \(note.createdAt.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Menu {
                        Button("编辑", systemImage: "pencil") {
                            editedContent = note.content
                            isEditing = true
                        }
                        Button("复制", systemImage: "doc.on.doc") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(note.content, forType: .string)
                        }
                        Divider()
                        Button("删除", systemImage: "trash", role: .destructive) {
                            appState.deleteQuickNote(id: note.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                    .menuStyle(.borderlessButton)
                }

                Divider()

                // 内容
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)

                    HStack {
                        Button("取消") {
                            isEditing = false
                        }
                        Spacer()
                        Button("保存") {
                            var updated = note
                            updated.content = editedContent
                            appState.updateQuickNote(updated)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Text(note.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}

// MARK: - Screenshots View

struct ScreenshotsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: ScreenshotItem?

    var body: some View {
        HSplitView {
            // Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
                ], spacing: 16) {
                    ForEach(appState.filteredScreenshots) { item in
                        ScreenshotCard(item: item, isSelected: selectedItem?.id == item.id)
                            .onTapGesture {
                                selectedItem = item
                            }
                    }
                }
                .padding()
            }
            .frame(minWidth: 400)

            // Detail
            if let item = selectedItem {
                ScreenshotDetailView(item: item)
                    .frame(minWidth: 300)
            } else {
                EmptyDetailView(
                    icon: "photo",
                    title: "Select a Screenshot",
                    subtitle: "Click to view OCR text"
                )
                .frame(minWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task {
                        await appState.captureScreenshot()
                    }
                } label: {
                    Label("Screenshot", systemImage: "camera.viewfinder")
                }

                Spacer()

                Picker("View", selection: .constant("grid")) {
                    Image(systemName: "square.grid.2x2").tag("grid")
                    Image(systemName: "list.bullet").tag("list")
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
            }
        }
    }
}

// MARK: - Screenshot Card

struct ScreenshotCard: View {
    let item: ScreenshotItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            ScreenshotThumbnail(imagePath: item.imagePath)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Time and tags
            HStack {
                Text(item.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if !item.tags.isEmpty {
                    Text(item.tags.first!)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Screenshot Detail

struct ScreenshotDetailView: View {
    let item: ScreenshotItem
    @EnvironmentObject var appState: AppState
    @State private var loadedImage: NSImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image
                Group {
                    if let image = loadedImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 200)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
                .onAppear {
                    loadedImage = ScreenshotService.shared.loadImage(for: item)
                }
                .onChange(of: item.id) { _, _ in
                    loadedImage = ScreenshotService.shared.loadImage(for: item)
                }

                // Action buttons
                HStack {
                    Button {
                        if let image = loadedImage {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.writeObjects([image])
                        }
                    } label: {
                        Label("Copy Image", systemImage: "doc.on.doc")
                    }
                    .disabled(loadedImage == nil)

                    Spacer()

                    Button(role: .destructive) {
                        appState.deleteScreenshot(id: item.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .buttonStyle(.bordered)

                Divider()

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Info")
                        .font(.headline)

                    Grid(alignment: .leading, verticalSpacing: 8) {
                        GridRow {
                            Text("Time")
                                .foregroundColor(.secondary)
                            Text(item.timestamp.formatted())
                        }
                        GridRow {
                            Text("Tags")
                                .foregroundColor(.secondary)
                            HStack {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text(tag)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Translation History View

struct TranslationHistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.translationHistory.isEmpty {
            EmptyDetailView(
                icon: "clock.arrow.circlepath",
                title: "暂无翻译历史",
                subtitle: "使用 ⌥T 划词翻译"
            )
        } else {
            List(appState.translationHistory) { record in
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.originalText)
                        .font(.body)

                    Text(record.translatedText)
                        .font(.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(record.engine.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)

                        Text(record.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - QuickNote Sheet (随手记弹窗)

struct QuickNoteSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var content: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .foregroundColor(.orange)
                    Text("随手记")
                        .font(.headline)
                }

                Spacer()

                Button("保存") {
                    saveNote()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()

            Divider()

            // 内容输入
            TextEditor(text: $content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(12)
                .focused($isFocused)

            Divider()

            // 底部提示
            HStack {
                Text("⌘↩ 快速保存")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(content.count) 字")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 300)
        .onAppear {
            isFocused = true
        }
    }

    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        appState.addQuickNote(content: trimmedContent)
        dismiss()
    }
}

// MARK: - Screenshot Thumbnail

struct ScreenshotThumbnail: View {
    let imagePath: String
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard !imagePath.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let nsImage = NSImage(contentsOfFile: imagePath) {
                DispatchQueue.main.async {
                    self.image = nsImage
                }
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyDetailView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3)
                .fontWeight(.medium)

            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}


#Preview {
    MainWindowView()
        .environmentObject(AppState())
}
