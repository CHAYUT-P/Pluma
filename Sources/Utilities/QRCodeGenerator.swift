import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

public enum QRCodeGenerator {
    /// Generates a crisp, vector-scaled QR code image from a given text or URL string.
    public static func generate(
        from string: String,
        darkColor: CodableColor = .inkBlack,
        lightColor: CodableColor = .white,
        size: CGFloat = 512
    ) -> NSImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputCI = filter?.outputImage else { return nil }

        // Colorize the QR code using CIFalseColor
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setValue(outputCI, forKey: kCIInputImageKey)
        colorFilter?.setValue(CIColor(color: darkColor.nsColor) ?? CIColor.black, forKey: "inputColor0")
        colorFilter?.setValue(CIColor(color: lightColor.nsColor) ?? CIColor.white, forKey: "inputColor1")

        guard let colorizedCI = colorFilter?.outputImage else { return nil }

        // Scale to desired high-res pixel dimensions with crisp nearest-neighbor interpolation
        let scale = size / colorizedCI.extent.width
        let scaledCI = colorizedCI.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let rep = NSCIImageRep(ciImage: scaledCI)
        let nsImage = NSImage(size: NSSize(width: size, height: size))
        nsImage.addRepresentation(rep)
        return nsImage
    }

    public static func generateBase64(
        from string: String,
        darkColor: CodableColor = .inkBlack,
        lightColor: CodableColor = .white,
        size: CGFloat = 512
    ) -> String? {
        guard let img = generate(from: string, darkColor: darkColor, lightColor: lightColor, size: size) else { return nil }
        return ImageUtils.base64String(from: img)
    }
}
