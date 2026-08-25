import SwiftUI

public struct ShadowEffect: Codable, Equatable, Hashable {
    public var isEnabled: Bool
    public var color: CodableColor
    public var radius: Double
    public var x: Double
    public var y: Double

    public init(
        isEnabled: Bool = false,
        color: CodableColor = CodableColor(red: 0, green: 0, blue: 0, opacity: 0.25),
        radius: Double = 8.0,
        x: Double = 0.0,
        y: Double = 4.0
    ) {
        self.isEnabled = isEnabled
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }

    public static let none = ShadowEffect(isEnabled: false)
    public static let subtle = ShadowEffect(isEnabled: true, color: CodableColor(red: 0, green: 0, blue: 0, opacity: 0.15), radius: 6, x: 0, y: 3)
    public static let elevated = ShadowEffect(isEnabled: true, color: CodableColor(red: 0, green: 0, blue: 0, opacity: 0.3), radius: 16, x: 0, y: 8)
    public static let neonGlow = ShadowEffect(isEnabled: true, color: CodableColor(hex: "#6366F1"), radius: 20, x: 0, y: 0)
}

public struct ImageFilterOptions: Codable, Equatable, Hashable {
    public var brightness: Double // -1.0 to 1.0 (default 0)
    public var contrast: Double   // 0.0 to 2.0 (default 1)
    public var saturation: Double // 0.0 to 2.0 (default 1)
    public var exposure: Double   // -2.0 to 2.0 (default 0)
    public var sepia: Double      // 0.0 to 1.0 (default 0)
    public var grayscale: Double  // 0.0 to 1.0 (default 0)
    public var invert: Bool       // default false
    public var blur: Double       // 0 to 20 (default 0)
    public var vignette: Double   // 0 to 1.0 (default 0)

    public init(
        brightness: Double = 0,
        contrast: Double = 1.0,
        saturation: Double = 1.0,
        exposure: Double = 0,
        sepia: Double = 0,
        grayscale: Double = 0,
        invert: Bool = false,
        blur: Double = 0,
        vignette: Double = 0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.exposure = exposure
        self.sepia = sepia
        self.grayscale = grayscale
        self.invert = invert
        self.blur = blur
        self.vignette = vignette
    }

    public static let `default` = ImageFilterOptions()

    public var isNeutral: Bool {
        brightness == 0 &&
        contrast == 1.0 &&
        saturation == 1.0 &&
        exposure == 0 &&
        sepia == 0 &&
        grayscale == 0 &&
        !invert &&
        blur == 0 &&
        vignette == 0
    }
}
