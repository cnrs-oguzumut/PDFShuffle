import SwiftUI
import UniformTypeIdentifiers
import PDFKit

// MARK: - Split Mode View

struct SplitModeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedOption: SplitOption
    @Binding var rangeStart: String
    @Binding var rangeEnd: String
    @Binding var everyNPages: String
    @Binding var specificPages: String

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Choose Split Method")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if appState.selectedPDF != nil {
                    Button(action: { appState.selectedPDF = nil }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                            Text("Clear")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "f87171"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "1e293b").opacity(0.6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Split by Range
            OptionCard(
                isSelected: selectedOption == .byRange,
                icon: "doc.text.magnifyingglass",
                title: "Split by Page Range",
                description: "Extract specific page range"
            ) {
                selectedOption = .byRange
            } content: {
                if selectedOption == .byRange {
                    HStack(spacing: 12) {
                        Text("From page")
                            .foregroundColor(Color(hex: "94a3b8"))
                        TextField("1", text: $rangeStart)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Text("to")
                            .foregroundColor(Color(hex: "94a3b8"))
                        TextField("5", text: $rangeEnd)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }
                    .padding(.top, 8)
                }
            }

            // Split Every N Pages
            OptionCard(
                isSelected: selectedOption == .everyN,
                icon: "square.split.2x2",
                title: "Split Every N Pages",
                description: "Create multiple files with equal pages"
            ) {
                selectedOption = .everyN
            } content: {
                if selectedOption == .everyN {
                    HStack(spacing: 12) {
                        Text("Every")
                            .foregroundColor(Color(hex: "94a3b8"))
                        TextField("3", text: $everyNPages)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Text("pages")
                            .foregroundColor(Color(hex: "94a3b8"))
                    }
                    .padding(.top, 8)
                }
            }

            // Extract Specific Pages
            OptionCard(
                isSelected: selectedOption == .specific,
                icon: "list.number",
                title: "Extract Specific Pages",
                description: "Select pages like: 1, 3, 5-10"
            ) {
                selectedOption = .specific
            } content: {
                if selectedOption == .specific {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("e.g., 1, 3, 5-10, 15", text: $specificPages)
                            .textFieldStyle(.roundedBorder)
                        Text("Use commas to separate, dash for ranges")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "94a3b8"))
                    }
                    .padding(.top, 8)
                }
            }

            // Split into Single Pages
            OptionCard(
                isSelected: selectedOption == .singlePages,
                icon: "doc.on.doc",
                title: "Split into Single Pages",
                description: "Create one file per page"
            ) {
                selectedOption = .singlePages
            }

            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Merge Mode View

struct MergeModeView: View {
    @Binding var files: [URL]
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Add PDFs to Merge")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if !files.isEmpty {
                    Button(action: { files.removeAll() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Clear All")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "f87171"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "1e293b").opacity(0.6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Drop zone for multiple files
            VStack(spacing: 12) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "60a5fa"))

                Text("Drop multiple PDFs here\nor click to add")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "94a3b8"))
                    .multilineTextAlignment(.center)

                if !files.isEmpty {
                    Text("\(files.count) files selected")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "4ade80"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isTargeted ? Color.blue.opacity(0.1) : Color(hex: "1e293b").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isTargeted ? Color.blue : Color(hex: "94a3b8").opacity(0.4),
                                style: StrokeStyle(lineWidth: 2, dash: [8])
                            )
                    )
            )
            .onTapGesture {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.pdf]
                panel.allowsMultipleSelection = true
                if panel.runModal() == .OK {
                    files.append(contentsOf: panel.urls)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                var newFiles: [URL] = []
                let group = DispatchGroup()

                for provider in providers {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                        defer { group.leave() }
                        guard let data = data as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil),
                              url.pathExtension.lowercased() == "pdf" else { return }
                        newFiles.append(url)
                    }
                }

                group.notify(queue: .main) {
                    files.append(contentsOf: newFiles)
                }

                return true
            }

            // File list
            if !files.isEmpty {
                VStack(spacing: 8) {
                    ForEach(files.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(Color(hex: "60a5fa"))
                            Text("\(index + 1). \(files[index].lastPathComponent)")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { files.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(hex: "f87171"))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Color(hex: "1e293b").opacity(0.6))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Extract Mode View

struct ExtractModeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedPages: Set<Int>
    @State private var pdfDocument: PDFDocument?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Select Pages to Extract")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if !selectedPages.isEmpty {
                    HStack(spacing: 12) {
                        Button(action: { selectedPages.removeAll() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                Text("Clear")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "f87171"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "1e293b").opacity(0.6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button(action: selectAll) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                Text("Select All")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "4ade80"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "1e293b").opacity(0.6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let pdf = pdfDocument {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 12)
                    ], spacing: 12) {
                        ForEach(0..<pdf.pageCount, id: \.self) { index in
                            PageThumbnailView(
                                page: pdf.page(at: index),
                                pageNumber: index + 1,
                                isSelected: selectedPages.contains(index)
                            ) {
                                togglePage(index)
                            }
                        }
                    }
                    .padding(4)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "94a3b8"))

                    Text("Drop a PDF to see page thumbnails")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "94a3b8"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !selectedPages.isEmpty {
                Text("\(selectedPages.count) page\(selectedPages.count == 1 ? "" : "s") selected")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "60a5fa"))
            }
        }
        .padding(16)
        .onChange(of: appState.selectedPDF) { newValue in
            if let url = newValue {
                pdfDocument = PDFDocument(url: url)
                selectedPages.removeAll()
            } else {
                pdfDocument = nil
                selectedPages.removeAll()
            }
        }
        .onAppear {
            if let url = appState.selectedPDF {
                pdfDocument = PDFDocument(url: url)
            }
        }
    }

    private func togglePage(_ index: Int) {
        if selectedPages.contains(index) {
            selectedPages.remove(index)
        } else {
            selectedPages.insert(index)
        }
    }

    private func selectAll() {
        guard let pdf = pdfDocument else { return }
        selectedPages = Set(0..<pdf.pageCount)
    }
}

// MARK: - Page Thumbnail View

struct PageThumbnailView: View {
    let page: PDFPage?
    let pageNumber: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    if let page = page {
                        PDFPageView(page: page)
                            .frame(height: 150)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color(hex: "3b82f6") : Color(hex: "94a3b8").opacity(0.3), lineWidth: isSelected ? 3 : 1)
                            )
                    } else {
                        Rectangle()
                            .fill(Color(hex: "1e293b").opacity(0.6))
                            .frame(height: 150)
                            .cornerRadius(8)
                    }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "3b82f6"))
                            .background(Circle().fill(Color.white))
                            .padding(6)
                    }
                }

                Text("Page \(pageNumber)")
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "3b82f6") : Color(hex: "94a3b8"))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PDF Page View

struct PDFPageView: NSViewRepresentable {
    let page: PDFPage

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.contents = nil

        let pageBounds = page.bounds(for: .mediaBox)
        let targetHeight: CGFloat = 150
        let scale = targetHeight / pageBounds.height
        let targetSize = CGSize(width: pageBounds.width * scale, height: targetHeight)

        let image = NSImage(size: targetSize)
        image.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(NSColor.white.cgColor)
        context?.fill(CGRect(origin: .zero, size: targetSize))

        context?.saveGState()
        context?.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context!)
        context?.restoreGState()

        image.unlockFocus()

        nsView.layer?.contents = image
        nsView.layer?.contentsGravity = .resizeAspect
    }
}

// MARK: - Reorder Mode View

struct ReorderModeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var reorderedPages: [Int]
    @State private var pdfDocument: PDFDocument?
    @State private var draggedPage: Int?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Reorder Pages")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if !reorderedPages.isEmpty {
                    HStack(spacing: 12) {
                        Button(action: resetOrder) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "60a5fa"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "1e293b").opacity(0.6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button(action: reverseOrder) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Reverse")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "4ade80"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "1e293b").opacity(0.6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let pdf = pdfDocument {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 12)
                    ], spacing: 12) {
                        ForEach(reorderedPages.indices, id: \.self) { index in
                            let pageIndex = reorderedPages[index]
                            ReorderPageThumbnailView(
                                page: pdf.page(at: pageIndex),
                                pageNumber: pageIndex + 1,
                                currentPosition: index + 1,
                                isDragging: draggedPage == index
                            )
                            .onDrag {
                                self.draggedPage = index
                                return NSItemProvider(object: String(index) as NSString)
                            }
                            .onDrop(of: [.text], delegate: ReorderDropDelegate(
                                currentIndex: index,
                                draggedIndex: $draggedPage,
                                pages: $reorderedPages
                            ))
                        }
                    }
                    .padding(4)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "94a3b8"))

                    Text("Drop a PDF to reorder pages")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "94a3b8"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !reorderedPages.isEmpty && pdfDocument != nil {
                Text("Drag pages to reorder • \(reorderedPages.count) pages total")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "60a5fa"))
            }
        }
        .padding(16)
        .onChange(of: appState.selectedPDF) { newValue in
            if let url = newValue {
                pdfDocument = PDFDocument(url: url)
                if let pdf = pdfDocument {
                    reorderedPages = Array(0..<pdf.pageCount)
                }
            } else {
                pdfDocument = nil
                reorderedPages = []
            }
        }
        .onAppear {
            if let url = appState.selectedPDF {
                pdfDocument = PDFDocument(url: url)
                if let pdf = pdfDocument {
                    reorderedPages = Array(0..<pdf.pageCount)
                }
            }
        }
    }

    private func resetOrder() {
        guard let pdf = pdfDocument else { return }
        reorderedPages = Array(0..<pdf.pageCount)
    }

    private func reverseOrder() {
        reorderedPages.reverse()
    }
}

// MARK: - Reorder Page Thumbnail View

struct ReorderPageThumbnailView: View {
    let page: PDFPage?
    let pageNumber: Int
    let currentPosition: Int
    let isDragging: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                if let page = page {
                    PDFPageView(page: page)
                        .frame(height: 150)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "94a3b8").opacity(0.3), lineWidth: 1)
                        )
                        .opacity(isDragging ? 0.5 : 1.0)
                } else {
                    Rectangle()
                        .fill(Color(hex: "1e293b").opacity(0.6))
                        .frame(height: 150)
                        .cornerRadius(8)
                }

                // Position badge
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: 10))
                    Text("\(currentPosition)")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "3b82f6"))
                .cornerRadius(6)
                .padding(6)
            }

            HStack(spacing: 4) {
                Text("Page \(pageNumber)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "94a3b8"))
                if pageNumber != currentPosition {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "60a5fa"))
                    Text("Pos \(currentPosition)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "60a5fa"))
                }
            }
        }
    }
}

// MARK: - Drop Delegate for Reordering

struct ReorderDropDelegate: DropDelegate {
    let currentIndex: Int
    @Binding var draggedIndex: Int?
    @Binding var pages: [Int]

    func performDrop(info: DropInfo) -> Bool {
        draggedIndex = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedIndex = draggedIndex,
              draggedIndex != currentIndex else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let fromIndex = draggedIndex
            let toIndex = currentIndex

            let movedPage = pages[fromIndex]
            pages.remove(at: fromIndex)
            pages.insert(movedPage, at: toIndex)

            self.draggedIndex = toIndex
        }
    }
}

// MARK: - Option Card Component

struct OptionCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let isSelected: Bool
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? (colorScheme == .dark ? .white : Color(hex: "2563eb")) : Color(hex: "60a5fa"))
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "0f172a"))
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "94a3b8") : Color(hex: "64748b"))
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? Color(hex: "4ade80") : (colorScheme == .dark ? Color(hex: "94a3b8") : Color(hex: "cbd5e1")))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            content
                .padding(.horizontal, 16)
                .padding(.bottom, isSelected ? 12 : 0)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected
                    ? LinearGradient(colors: [Color(hex: "3b82f6").opacity(colorScheme == .dark ? 0.2 : 0.15), Color(hex: "2563eb").opacity(colorScheme == .dark ? 0.2 : 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: colorScheme == .dark
                        ? [Color(hex: "1e293b").opacity(0.6), Color(hex: "1e293b").opacity(0.6)]
                        : [Color(hex: "f8fafc"), Color(hex: "f8fafc")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(hex: "3b82f6") : (colorScheme == .dark ? Color(hex: "94a3b8").opacity(0.2) : Color(hex: "cbd5e1")), lineWidth: isSelected ? 2 : 1)
        )
    }
}

// Placeholder content for OptionCard without extra content
extension OptionCard where Content == EmptyView {
    init(isSelected: Bool, icon: String, title: String, description: String, action: @escaping () -> Void) {
        self.isSelected = isSelected
        self.icon = icon
        self.title = title
        self.description = description
        self.action = action
        self.content = EmptyView()
    }
}
