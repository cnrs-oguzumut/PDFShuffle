import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var selectedMode: OperationMode = .split
    @State private var splitOption: SplitOption = .byRange
    @State private var rangeStart = "1"
    @State private var rangeEnd = "5"
    @State private var everyNPages = "3"
    @State private var specificPages = "1, 3, 5-10"
    @State private var extractSelectedPages: Set<Int> = []
    @State private var reorderedPages: [Int] = []
    @State private var isProcessing = false
    @State private var statusMessage = ""
    @State private var statusIsError = false
    @State private var showingResult = false
    @State private var mergeFiles: [URL] = []

    var body: some View {
        ZStack {
            // Adaptive gradient background
            LinearGradient(
                colors: isDarkMode
                    ? [Color(hex: "0f172a"), Color(hex: "1e293b")]
                    : [Color(hex: "ffffff"), Color(hex: "f1f5f9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Title with theme toggle
                HStack {
                    Spacer()

                    Text("PDFShuffle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "0f172a"))

                    Spacer()

                    Button(action: { isDarkMode.toggle() }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isDarkMode ? Color(hex: "fbbf24") : Color(hex: "475569"))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? Color(hex: "1e293b").opacity(0.6) : Color(hex: "e2e8f0"))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 24)
                }
                .padding(.top, 24)

                // Drop Zone
                DropZoneView()
                    .padding(.horizontal, 24)

                // Mode Tabs
                Picker("Mode", selection: $selectedMode) {
                    Text("Split").tag(OperationMode.split)
                    Text("Merge").tag(OperationMode.merge)
                    Text("Extract").tag(OperationMode.extract)
                    Text("Reorder").tag(OperationMode.reorder)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                // Mode-specific content
                ScrollView {
                    switch selectedMode {
                    case .split:
                        SplitModeView(
                            selectedOption: $splitOption,
                            rangeStart: $rangeStart,
                            rangeEnd: $rangeEnd,
                            everyNPages: $everyNPages,
                            specificPages: $specificPages
                        )
                    case .merge:
                        MergeModeView(files: $mergeFiles)
                    case .extract:
                        ExtractModeView(selectedPages: $extractSelectedPages)
                    case .reorder:
                        ReorderModeView(reorderedPages: $reorderedPages)
                    }
                }
                .padding(.horizontal, 24)

                // Status message
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 13))
                        .foregroundColor(statusIsError ? Color(hex: "f87171") : Color(hex: "4ade80"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Process button
                Button(action: process) {
                    HStack {
                        Text("Process PDF")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: canProcess
                                ? [Color(hex: "3b82f6"), Color(hex: "2563eb")]
                                : [Color(hex: "94a3b8").opacity(0.3), Color(hex: "94a3b8").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                }
                .disabled(!canProcess)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    var canProcess: Bool {
        switch selectedMode {
        case .split:
            return appState.selectedPDF != nil && !isProcessing
        case .extract:
            return appState.selectedPDF != nil && !extractSelectedPages.isEmpty && !isProcessing
        case .merge:
            return mergeFiles.count >= 2 && !isProcessing
        case .reorder:
            return appState.selectedPDF != nil && !reorderedPages.isEmpty && !isProcessing
        }
    }

    func process() {
        isProcessing = true
        statusMessage = "Processing..."
        statusIsError = false

        Task {
            do {
                switch selectedMode {
                case .split:
                    try await performSplit()
                case .merge:
                    try await performMerge()
                case .extract:
                    try await performExtract()
                case .reorder:
                    try await performReorder()
                }

                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Success!"
                    statusIsError = false
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Error: \(error.localizedDescription)"
                    statusIsError = true
                }
            }
        }
    }

    func performSplit() async throws {
        guard let inputURL = appState.selectedPDF else { return }

        let panel = NSSavePanel()

        switch splitOption {
        case .byRange:
            panel.nameFieldStringValue = inputURL.deletingPathExtension().lastPathComponent + "_pages\(rangeStart)-\(rangeEnd).pdf"
            panel.allowedContentTypes = [.pdf]

            guard panel.runModal() == .OK, let outputURL = panel.url else { return }
            guard let start = Int(rangeStart), let end = Int(rangeEnd) else {
                throw PDFProcessorError.invalidPageRange
            }

            try PDFProcessor.splitByRange(input: inputURL, output: outputURL, start: start, end: end)
            PDFProcessor.revealInFinder(outputURL)

        case .everyN:
            let dirPanel = NSOpenPanel()
            dirPanel.canCreateDirectories = true
            dirPanel.canChooseDirectories = true
            dirPanel.canChooseFiles = false
            dirPanel.prompt = "Choose Output Folder"

            guard dirPanel.runModal() == .OK, let outputDir = dirPanel.url else { return }
            guard let n = Int(everyNPages), n > 0 else {
                throw PDFProcessorError.invalidPageRange
            }

            let urls = try PDFProcessor.splitEveryNPages(input: inputURL, outputDirectory: outputDir, every: n)
            if let firstURL = urls.first {
                PDFProcessor.revealInFinder(firstURL)
            }

        case .specific:
            guard let pageNumbers = PDFProcessor.parsePageNumbers(specificPages) else {
                throw PDFProcessorError.invalidPageRange
            }

            panel.nameFieldStringValue = inputURL.deletingPathExtension().lastPathComponent + "_extracted.pdf"
            panel.allowedContentTypes = [.pdf]

            guard panel.runModal() == .OK, let outputURL = panel.url else { return }

            try PDFProcessor.extractSpecificPages(input: inputURL, output: outputURL, pageNumbers: pageNumbers)
            PDFProcessor.revealInFinder(outputURL)

        case .singlePages:
            let dirPanel = NSOpenPanel()
            dirPanel.canCreateDirectories = true
            dirPanel.canChooseDirectories = true
            dirPanel.canChooseFiles = false
            dirPanel.prompt = "Choose Output Folder"

            guard dirPanel.runModal() == .OK, let outputDir = dirPanel.url else { return }

            let urls = try PDFProcessor.splitIntoSinglePages(input: inputURL, outputDirectory: outputDir)
            if let firstURL = urls.first {
                PDFProcessor.revealInFinder(firstURL)
            }
        }
    }

    func performMerge() async throws {
        guard mergeFiles.count >= 2 else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "merged.pdf"
        panel.allowedContentTypes = [.pdf]

        guard panel.runModal() == .OK, let outputURL = panel.url else { return }

        try PDFProcessor.mergePDFs(inputs: mergeFiles, output: outputURL)
        PDFProcessor.revealInFinder(outputURL)
    }

    func performExtract() async throws {
        guard let inputURL = appState.selectedPDF else { return }
        guard !extractSelectedPages.isEmpty else {
            throw PDFProcessorError.noPages
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = inputURL.deletingPathExtension().lastPathComponent + "_extracted.pdf"
        panel.allowedContentTypes = [.pdf]

        guard panel.runModal() == .OK, let outputURL = panel.url else { return }

        // Convert Set<Int> to sorted array of page numbers (1-based)
        let pageNumbers = extractSelectedPages.sorted().map { $0 + 1 }

        try PDFProcessor.extractSpecificPages(input: inputURL, output: outputURL, pageNumbers: pageNumbers)
        PDFProcessor.revealInFinder(outputURL)
    }

    func performReorder() async throws {
        guard let inputURL = appState.selectedPDF else { return }
        guard !reorderedPages.isEmpty else {
            throw PDFProcessorError.noPages
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = inputURL.deletingPathExtension().lastPathComponent + "_reordered.pdf"
        panel.allowedContentTypes = [.pdf]

        guard panel.runModal() == .OK, let outputURL = panel.url else { return }

        // Convert reordered indices to page numbers (1-based)
        let pageNumbers = reorderedPages.map { $0 + 1 }

        try PDFProcessor.reorderPages(input: inputURL, output: outputURL, order: pageNumbers)
        PDFProcessor.revealInFinder(outputURL)
    }
}

// MARK: - Drop Zone

struct DropZoneView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Image(systemName: appState.selectedPDF != nil ? "checkmark.circle.fill" : "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(appState.selectedPDF != nil ? Color.green : Color(hex: "94a3b8"))

                if let file = appState.selectedPDF {
                    Text(file.lastPathComponent)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 40)

                    HStack(spacing: 16) {
                        Text("\(appState.pageCount) pages")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "60a5fa"))

                        Text("•")
                            .foregroundColor(Color(hex: "94a3b8"))

                        Text(String(format: "%.2f MB", Double(appState.fileSize) / (1024 * 1024)))
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "60a5fa"))
                    }
                } else {
                    Text("Drop PDF here\nor click to browse")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "94a3b8"))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)

            // Clear button
            if appState.selectedPDF != nil {
                Button(action: { appState.selectedPDF = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "f87171"))
                        .background(Circle().fill(Color(hex: "1e293b")))
                }
                .buttonStyle(.plain)
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appState.selectedPDF != nil
                    ? Color.green.opacity(0.1)
                    : (isTargeted ? Color.blue.opacity(0.1) : Color(hex: "1e293b").opacity(0.6)))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            appState.selectedPDF != nil
                                ? Color.green
                                : (isTargeted ? Color.blue : Color(hex: "94a3b8").opacity(0.4)),
                            style: StrokeStyle(lineWidth: 2, dash: appState.selectedPDF != nil ? [] : [8])
                        )
                )
        )
        .onTapGesture {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.pdf]
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.url {
                appState.loadPDF(url)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "pdf" else { return }
                DispatchQueue.main.async {
                    appState.loadPDF(url)
                }
            }
            return true
        }
    }
}

// MARK: - Supporting Types

enum OperationMode: String {
    case split, merge, extract, reorder
}

enum SplitOption {
    case byRange, everyN, specific, singlePages
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
