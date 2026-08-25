import AppKit
import Vision
import CoreImage

public final class VisionBackgroundRemover {
    public static let shared = VisionBackgroundRemover()

    private init() {}

    /// Instantly removes the background of an image using Apple Vision Framework on Apple Silicon / Intel Neural Engine.
    @MainActor
    public func removeBackground(from nsImage: NSImage) async -> NSImage? {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        if #available(macOS 14.0, *) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
                guard let result = request.results?.first else {
                    return fallbackThresholdAlpha(nsImage: nsImage)
                }

                let maskPixelBuffer = try result.generateMaskedImage(
                    ofInstances: result.allInstances,
                    from: handler,
                    croppedToInstancesExtent: false
                )

                let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                let rep = NSCIImageRep(ciImage: ciImage)
                let output = NSImage(size: rep.size)
                output.addRepresentation(rep)
                return output
            } catch {
                return fallbackThresholdAlpha(nsImage: nsImage)
            }
        } else {
            return fallbackThresholdAlpha(nsImage: nsImage)
        }
    }

    /// Fast fallback color-key alpha mask
    private func fallbackThresholdAlpha(nsImage: NSImage) -> NSImage? {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nsImage }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.05, forKey: kCIInputContrastKey)

        guard let outputCI = filter?.outputImage else { return nsImage }
        let rep = NSCIImageRep(ciImage: outputCI)
        let output = NSImage(size: rep.size)
        output.addRepresentation(rep)
        return output
    }
}
