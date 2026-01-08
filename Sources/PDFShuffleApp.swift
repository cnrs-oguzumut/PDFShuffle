import SwiftUI
import PDFKit

@main
struct PDFShuffleApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 600, minHeight: 800)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Toggle Dark/Light Mode") {
                    isDarkMode.toggle()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedPDF: URL?
    @Published var pageCount: Int = 0
    @Published var fileSize: Int64 = 0

    func loadPDF(_ url: URL) {
        selectedPDF = url
        // Get page count and file size
        if let pdfDocument = PDFDocument(url: url) {
            pageCount = pdfDocument.pageCount
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        }
    }
}
