//
//  MainWindowView.swift
//  Gleam
//
//  Created by Song Ziwen on 2026/1/31.
//

import SwiftUI

/// 主窗口视图
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $appState.searchText, prompt: "搜索收藏、截图...")
        .sheet(isPresented: $appState.showNewCollectionSheet) {
            NewCollectionSheet()
        }
    }
}

// MARK: - 侧边栏

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
                    appState.showNewCollectionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func countFor(_ tab: SidebarTab) -> String {
        switch tab {
        case .collections:
            return "\(appState.collections.count)"
        case .screenshots:
            return "\(appState.screenshots.count)"
        case .translationHistory:
            return "\(appState.translationHistory.count)"
        }
    }

    private func colorFor(_ tab: SidebarTab) -> Color {
        switch tab {
        case .collections: return .yellow
        case .screenshots: return .orange
        case .translationHistory: return .blue
        }
    }

    private var allTags: [String] {
        var tags = Set<String>()
        appState.collections.forEach { tags.formUnion($0.tags) }
        appState.screenshots.forEach { tags.formUnion($0.tags) }
        return Array(tags).sorted()
    }
}

// MARK: - 详情视图

struct DetailView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.selectedTab {
        case .collections:
            CollectionsView()
        case .screenshots:
            ScreenshotsView()
        case .translationHistory:
            TranslationHistoryView()
        }
    }
}

// MARK: - 收藏视图

struct CollectionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: CollectionItem?

    var body: some View {
        HSplitView {
            // 列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(appState.filteredCollections) { item in
                        CollectionCard(item: item, isSelected: selectedItem?.id == item.id)
                            .onTapGesture {
                                selectedItem = item
                            }
                    }
                }
                .padding()
            }
            .frame(minWidth: 300)

            // 详情
            if let item = selectedItem {
                CollectionDetailView(item: item)
                    .frame(minWidth: 300)
            } else {
                EmptyDetailView(
                    icon: "star",
                    title: "选择一个收藏",
                    subtitle: "点击左侧列表查看详情"
                )
                .frame(minWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    appState.showNewCollectionSheet = true
                } label: {
                    Label("添加收藏", systemImage: "plus")
                }

                Spacer()

                Picker("排序", selection: .constant("date")) {
                    Text("按日期").tag("date")
                    Text("按标题").tag("title")
                    Text("按类型").tag("type")
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
        }
    }
}

// MARK: - 收藏卡片

struct CollectionCard: View {
    let item: CollectionItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.type.icon)
                    .foregroundColor(item.type.color)
                    .font(.title3)

                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(item.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(item.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if !item.tags.isEmpty {
                HStack {
                    ForEach(item.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
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
}

// MARK: - 收藏详情

struct CollectionDetailView: View {
    let item: CollectionItem
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 头部
                HStack {
                    Image(systemName: item.type.icon)
                        .font(.largeTitle)
                        .foregroundColor(item.type.color)

                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("创建于 \(item.createdAt.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Menu {
                        Button("编辑", systemImage: "pencil") {}
                        Button("复制", systemImage: "doc.on.doc") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.content, forType: .string)
                        }
                        Divider()
                        Button("删除", systemImage: "trash", role: .destructive) {
                            appState.deleteCollection(id: item.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                    .menuStyle(.borderlessButton)
                }

                Divider()

                // 内容
                Text(item.content)
                    .font(.body)
                    .textSelection(.enabled)

                // URL
                if let url = item.url {
                    Link(destination: URL(string: url)!) {
                        HStack {
                            Image(systemName: "link")
                            Text(url)
                                .lineLimit(1)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // 标签
                if !item.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.body)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 截图视图

struct ScreenshotsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: ScreenshotItem?

    var body: some View {
        HSplitView {
            // 网格
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

            // 详情
            if let item = selectedItem {
                ScreenshotDetailView(item: item)
                    .frame(minWidth: 300)
            } else {
                EmptyDetailView(
                    icon: "photo",
                    title: "选择一张截图",
                    subtitle: "点击左侧查看 OCR 文字"
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
                    Label("截图", systemImage: "camera.viewfinder")
                }

                Spacer()

                Picker("视图", selection: .constant("grid")) {
                    Image(systemName: "square.grid.2x2").tag("grid")
                    Image(systemName: "list.bullet").tag("list")
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
            }
        }
    }
}

// MARK: - 截图卡片

struct ScreenshotCard: View {
    let item: ScreenshotItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片
            ScreenshotThumbnail(imagePath: item.imagePath)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // 时间和标签
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

// MARK: - 截图详情

struct ScreenshotDetailView: View {
    let item: ScreenshotItem
    @EnvironmentObject var appState: AppState
    @State private var loadedImage: NSImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 图片
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

                // 操作按钮
                HStack {
                    Button {
                        if let image = loadedImage {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.writeObjects([image])
                        }
                    } label: {
                        Label("复制图片", systemImage: "doc.on.doc")
                    }
                    .disabled(loadedImage == nil)

                    Spacer()

                    Button(role: .destructive) {
                        appState.deleteScreenshot(id: item.id)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .buttonStyle(.bordered)

                Divider()

                // 信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("信息")
                        .font(.headline)

                    Grid(alignment: .leading, verticalSpacing: 8) {
                        GridRow {
                            Text("时间")
                                .foregroundColor(.secondary)
                            Text(item.timestamp.formatted())
                        }
                        GridRow {
                            Text("标签")
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

// MARK: - 翻译历史视图

struct TranslationHistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.translationHistory.isEmpty {
            EmptyDetailView(
                icon: "clock.arrow.circlepath",
                title: "暂无翻译历史",
                subtitle: "使用 ⌥T 划词翻译后会在这里显示"
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

// MARK: - 新建收藏表单

struct NewCollectionSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var type: CollectionType = .text
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var url: String = ""
    @State private var tagsInput: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text("新建收藏")
                    .font(.headline)

                Spacer()

                Button("保存") {
                    saveCollection()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || content.isEmpty)
            }
            .padding()

            Divider()

            // 表单
            Form {
                Picker("类型", selection: $type) {
                    ForEach(CollectionType.allCases, id: \.self) { t in
                        Label(t.displayName, systemImage: t.icon).tag(t)
                    }
                }

                TextField("标题", text: $title)

                if type == .link {
                    TextField("URL", text: $url)
                }

                Section("内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }

                TextField("标签（用逗号分隔）", text: $tagsInput)
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 500, height: 450)
    }

    private func saveCollection() {
        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        appState.addCollection(
            type: type,
            title: title,
            content: content,
            url: type == .link ? url : nil,
            tags: tags
        )
        dismiss()
    }
}

// MARK: - 截图缩略图

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

// MARK: - 空状态视图

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

// MARK: - CollectionType 扩展

extension CollectionType {
    var color: Color {
        switch self {
        case .text: return .blue
        case .link: return .green
        case .image: return .orange
        case .file: return .purple
        }
    }
}

#Preview {
    MainWindowView()
        .environmentObject(AppState())
}
