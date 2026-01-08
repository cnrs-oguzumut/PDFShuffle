# PDFShuffle - PDF Split & Merge Tool

A modern, native macOS app for splitting and merging PDFs.

## Features

### Split Mode 🔪
- **Split by Page Range** - Extract specific pages (e.g., pages 1-5)
- **Split Every N Pages** - Create equal-sized chunks
- **Extract Specific Pages** - Select pages like "1, 3, 5-10"
- **Split into Single Pages** - One file per page

### Merge Mode 🔗
- **Merge Multiple PDFs** - Combine 2+ PDFs into one
- **Drag & Drop** - Easy file management
- **Preview** - See file count before merging

### Coming Soon
- **Extract Mode** - Visual page selector with thumbnails
- **Reorder Mode** - Drag to reorder pages, rotate, delete

## Build

```bash
./build.sh
```

The app will be created at `build/PDFShuffle.app`

## Tech Stack

- **Swift 5.9+** - Native macOS
- **SwiftUI** - Modern UI framework
- **PDFKit** - Apple's PDF framework (no external dependencies!)

## Version

- **Version**: 1.0.0
- **Build**: 1
- **Requirements**: macOS 13.0+

## Design

PDFShuffle uses the same visual design as GhostPDF+:
- Dark gradient background
- Card-based UI
- Blue/green color scheme
- Drag & drop interface
