import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Shared document-import pipeline: open-panel content types, background
/// execution with a modal progress HUD, and the failure alert — used
/// identically by the toolbar, the media tab and the dashboard so the three
/// entry points can't drift apart again.
///
/// The importer previously ran synchronously on the main thread; a large deck
/// (hundreds of slides, embedded media) froze the whole window for minutes.
/// Now the heavy XML/zip work runs on a worker queue and only the result is
/// delivered back on the main actor.
@MainActor
public final class DocumentImportService: ObservableObject {
    public static let shared = DocumentImportService()

    /// Drives `ImportProgressOverlay` — true while any import is running.
    /// Counted, not a latch: concurrent calls must not be silently dropped
    /// (the importer is stateless — each run gets its own temp dir).
    @Published public private(set) var isImporting = false
    @Published public private(set) var statusText = "Importing…"
    private var activeImports = 0

    private init() {}

    /// The UTTypes every document open-panel accepts. Custom extensions
    /// (.pptx/.pluma/.canv) need filename-derived UTTypes — the system has no
    /// declared type for them.
    public static var allowedContentTypes: [UTType] {
        var types: [UTType] = [.pdf, .svg, .image, .png, .jpeg, .zip, .json]
        for ext in ["pptx", "pluma", "canv"] {
            if let t = UTType(filenameExtension: ext) { types.append(t) }
        }
        return types
    }

    /// Runs the importer on a worker thread; `completion` fires on the main
    /// actor with nil on failure (callers show `showFailureAlert`).
    ///
    /// Note: the importer resolves AppKit fonts/images off the main thread.
    /// NSTextStorage/NSLayoutManager instances created locally are safe off-
    /// main; the two NSFontManager.shared calls in TextMeasurement bounce to
    /// the main queue via `onMain` since the manager is main-thread-only.
    public func importDocument(from url: URL, completion: @escaping (CanvasProject?) -> Void) {
        activeImports += 1
        isImporting = true
        statusText = "Importing \(url.lastPathComponent)…"
        DispatchQueue.global(qos: .userInitiated).async {
            let project = CanvaDocumentImporter.importDocument(from: url)
            Task { @MainActor in
                self.activeImports -= 1
                if self.activeImports == 0 { self.isImporting = false }
                completion(project)
            }
        }
    }

    /// Shared failure feedback — identical copy at every entry point.
    public func showFailureAlert(file: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Import Failed"
        alert.informativeText = "\"\(file)\" could not be read.\n\nSupported formats: PowerPoint (.pptx), PDF, SVG, ZIP of images, PNG / JPEG / WebP / HEIC, and Pluma project files (.canv / .pluma / .json)."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

/// Modal progress HUD shown while `DocumentImportService` is importing.
/// Attach once at the root of the dashboard and the editor.
public struct ImportProgressOverlay: View {
    @ObservedObject private var service = DocumentImportService.shared

    public init() {}

    public var body: some View {
        if service.isImporting {
            ZStack {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .contentShape(Rectangle()) // block interaction while importing
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(service.statusText)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .frame(minWidth: 260)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 20)
            }
            .transition(.opacity)
        }
    }
}
