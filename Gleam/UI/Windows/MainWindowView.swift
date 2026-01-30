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
        .searchable(text: $appState.searchText, prompt: "Search collections, screenshots...")
        .sheet(isPresented: $appState.showNewCollectionSheet) {
            NewCollectionSheet()
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: $appState.selectedTab) {
            Section("Content") {
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

            Section("Tags") {
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

// MARK: - Detail View

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

// MARK: - Collections View

struct CollectionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: CollectionItem?

    var body: some View {
        HSplitView {
            // List
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

            // Detail
            if let item = selectedItem {
                CollectionDetailView(item: item)
                    .frame(minWidth: 300)
            } else {
                EmptyDetailView(
                    icon: "star",
                    title: "Select a Collection",
                    subtitle: "Click on the list to view details"
                )
                .frame(minWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    appState.showNewCollectionSheet = true
                } label: {
                    Label("Add Collection", systemImage: "plus")
                }

                Spacer()

                Picker("Sort", selection: .constant("date")) {
                    Text("By Date").tag("date")
                    Text("By Title").tag("title")
                    Text("By Type").tag("type")
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
        }
    }
}

// MARK: - Collection Card

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

// MARK: - Collection Detail

struct CollectionDetailView: View {
    let item: CollectionItem
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: item.type.icon)
                        .font(.largeTitle)
                        .foregroundColor(item.type.color)

                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Created on \(item.createdAt.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Menu {
                        Button("Edit", systemImage: "pencil") {}
                        Button("Copy", systemImage: "doc.on.doc") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.content, forType: .string)
                        }
                        Divider()
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            appState.deleteCollection(id: item.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                    .menuStyle(.borderlessButton)
                }

                Divider()

                // Content
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

                // Tags
                if !item.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
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
                title: "No Translation History",
                subtitle: "Use ⌥T to translate selected text"
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

// MARK: - New Collection Sheet

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
            // Title bar
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text("New Collection")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    saveCollection()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || content.isEmpty)
            }
            .padding()

            Divider()

            // Form
            Form {
                Picker("Type", selection: $type) {
                    ForEach(CollectionType.allCases, id: \.self) { t in
                        Label(t.displayName, systemImage: t.icon).tag(t)
                    }
                }

                TextField("Title", text: $title)

                if type == .link {
                    TextField("URL", text: $url)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }

                TextField("Tags (comma separated)", text: $tagsInput)
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

// MARK: - CollectionType Extension

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
