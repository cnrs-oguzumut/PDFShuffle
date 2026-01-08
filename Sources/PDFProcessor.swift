import Foundation
import PDFKit
import AppKit

enum PDFProcessorError: Error {
    case invalidPDF
    case invalidPageRange
    case saveFailed
    case noPages

    var localizedDescription: String {
        switch self {
        case .invalidPDF: return "Invalid PDF file"
        case .invalidPageRange: return "Invalid page range"
        case .saveFailed: return "Failed to save PDF"
        case .noPages: return "No pages to process"
        }
    }
}

struct PDFProcessor {

    // MARK: - Split Operations

    static func splitByRange(input: URL, output: URL, start: Int, end: Int) throws {
        guard let pdfDocument = PDFDocument(url: input) else {
            throw PDFProcessorError.invalidPDF
        }

        let newPDF = PDFDocument()
        let pageCount = pdfDocument.pageCount

        guard start >= 1 && end <= pageCount && start <= end else {
            throw PDFProcessorError.invalidPageRange
        }

        for pageIndex in (start - 1)..<end {
            if let page = pdfDocument.page(at: pageIndex) {
                newPDF.insert(page, at: newPDF.pageCount)
            }
        }

        guard newPDF.write(to: output) else {
            throw PDFProcessorError.saveFailed
        }
    }

    static func splitEveryNPages(input: URL, outputDirectory: URL, every: Int) throws -> [URL] {
        guard let pdfDocument = PDFDocument(url: input) else {
            throw PDFProcessorError.invalidPDF
        }

        let pageCount = pdfDocument.pageCount
        guard every > 0 else {
            throw PDFProcessorError.invalidPageRange
        }

        var outputURLs: [URL] = []
        let baseName = input.deletingPathExtension().lastPathComponent

        var partNumber = 1
        var currentPageIndex = 0

        while currentPageIndex < pageCount {
            let newPDF = PDFDocument()
            let endIndex = min(currentPageIndex + every, pageCount)

            for pageIndex in currentPageIndex..<endIndex {
                if let page = pdfDocument.page(at: pageIndex) {
                    newPDF.insert(page, at: newPDF.pageCount)
                }
            }

            let outputURL = outputDirectory.appendingPathComponent("\(baseName)_part\(partNumber).pdf")
            guard newPDF.write(to: outputURL) else {
                throw PDFProcessorError.saveFailed
            }

            outputURLs.append(outputURL)
            currentPageIndex = endIndex
            partNumber += 1
        }

        return outputURLs
    }

    static func splitIntoSinglePages(input: URL, outputDirectory: URL) throws -> [URL] {
        guard let pdfDocument = PDFDocument(url: input) else {
            throw PDFProcessorError.invalidPDF
        }

        let pageCount = pdfDocument.pageCount
        var outputURLs: [URL] = []
        let baseName = input.deletingPathExtension().lastPathComponent

        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            let newPDF = PDFDocument()
            newPDF.insert(page, at: 0)

            let outputURL = outputDirectory.appendingPathComponent("\(baseName)_page\(pageIndex + 1).pdf")
            guard newPDF.write(to: outputURL) else {
                throw PDFProcessorError.saveFailed
            }

            outputURLs.append(outputURL)
        }

        return outputURLs
    }

    static func extractSpecificPages(input: URL, output: URL, pageNumbers: [Int]) throws {
        guard let pdfDocument = PDFDocument(url: input) else {
            throw PDFProcessorError.invalidPDF
        }

        let newPDF = PDFDocument()
        let pageCount = pdfDocument.pageCount

        for pageNum in pageNumbers {
            let pageIndex = pageNum - 1 // Convert to 0-based index
            guard pageIndex >= 0 && pageIndex < pageCount else {
                throw PDFProcessorError.invalidPageRange
            }

            if let page = pdfDocument.page(at: pageIndex) {
                newPDF.insert(page, at: newPDF.pageCount)
            }
        }

        guard newPDF.pageCount > 0 else {
            throw PDFProcessorError.noPages
        }

        guard newPDF.write(to: output) else {
            throw PDFProcessorError.saveFailed
        }
    }

    // MARK: - Reorder Operation

    static func reorderPages(input: URL, output: URL, order: [Int]) throws {
        guard let pdfDocument = PDFDocument(url: input) else {
            throw PDFProcessorError.invalidPDF
        }

        let pageCount = pdfDocument.pageCount

        // Validate all page numbers
        for pageNum in order {
            guard pageNum >= 1 && pageNum <= pageCount else {
                throw PDFProcessorError.invalidPageRange
            }
        }

        let reorderedPDF = PDFDocument()

        for pageNum in order {
            let pageIndex = pageNum - 1
            if let page = pdfDocument.page(at: pageIndex) {
                reorderedPDF.insert(page, at: reorderedPDF.pageCount)
            }
        }

        guard reorderedPDF.pageCount > 0 else {
            throw PDFProcessorError.noPages
        }

        guard reorderedPDF.write(to: output) else {
            throw PDFProcessorError.saveFailed
        }
    }

    // MARK: - Merge Operation

    static func mergePDFs(inputs: [URL], output: URL) throws {
        guard !inputs.isEmpty else {
            throw PDFProcessorError.noPages
        }

        let mergedPDF = PDFDocument()

        for inputURL in inputs {
            guard let pdfDocument = PDFDocument(url: inputURL) else {
                throw PDFProcessorError.invalidPDF
            }

            for pageIndex in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: pageIndex) {
                    mergedPDF.insert(page, at: mergedPDF.pageCount)
                }
            }
        }

        guard mergedPDF.pageCount > 0 else {
            throw PDFProcessorError.noPages
        }

        guard mergedPDF.write(to: output) else {
            throw PDFProcessorError.saveFailed
        }
    }

    // MARK: - Helper Functions

    static func parsePageNumbers(_ input: String) -> [Int]? {
        var pages: [Int] = []
        let components = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        for component in components {
            if component.contains("-") {
                // Range like "5-10"
                let rangeParts = component.split(separator: "-")
                guard rangeParts.count == 2,
                      let start = Int(rangeParts[0]),
                      let end = Int(rangeParts[1]),
                      start <= end else {
                    return nil
                }
                pages.append(contentsOf: start...end)
            } else {
                // Single page
                guard let page = Int(component) else {
                    return nil
                }
                pages.append(page)
            }
        }

        return pages.isEmpty ? nil : pages
    }

    static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
