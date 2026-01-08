// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PDFShuffle",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "PDFShuffle",
            path: "Sources"
        )
    ]
)
