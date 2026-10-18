import SwiftUI
import AppKit

// MARK: - Pluma Design Tokens
//
// Single source of truth for the editor chrome. Views should reach for these
// instead of hardcoding hex values so light/dark mode and future re-theming
// stay consistent across the toolbar, panels, and canvas workspace.

public enum PlumaTheme {
    /// Brand terracotta — selection, primary actions, active tabs.
    public static let accent = Color(hex: "#C2410C")
    /// Warm amber used for secondary highlights (lock state, badges).
    public static let accentWarm = Color(hex: "#D97706")
    /// Tinted fill behind an active/selected control.
    public static let accentSoft = dynamic(light: "#C2410C", lightAlpha: 0.12, dark: "#F97316", darkAlpha: 0.20)
    /// Accent for text/icons sitting on `accentSoft` (brighter in dark mode for contrast).
    public static let accentOnSoft = dynamic(light: "#C2410C", dark: "#FB923C")

    /// The workspace behind the paper — light, warm neutral (Canva-like), not the
    /// heavy mid-grey of `underPageBackgroundColor`.
    public static let workspace = dynamic(light: "#ECEAE5", dark: "#1B1A19")
    /// Chrome surfaces (top bars, side panels).
    public static let chrome = Color(NSColor.windowBackgroundColor)
    /// Slightly raised surface for grouped controls inside the chrome.
    public static let control = dynamic(light: "#000000", lightAlpha: 0.05, dark: "#FFFFFF", darkAlpha: 0.08)
    public static let controlHover = dynamic(light: "#000000", lightAlpha: 0.09, dark: "#FFFFFF", darkAlpha: 0.13)
    /// Text-field / readout well inside panels.
    public static let field = dynamic(light: "#FFFFFF", dark: "#262422")
    /// Small uppercase section headers in panels.
    public static let sectionHeader = accentOnSoft
    /// Hairline separators.
    public static let hairline = dynamic(light: "#000000", lightAlpha: 0.10, dark: "#FFFFFF", darkAlpha: 0.12)

    /// Dashboard paper + ink (warm off-white / near-black, inverted in dark mode).
    public static let paper = dynamic(light: "#F6F3EC", dark: "#1F1D1B")
    public static let ink = dynamic(light: "#292524", dark: "#EDE8E0")

    public static let success = Color(hex: "#10B981")
    public static let danger = Color(hex: "#DC2626")

    // MARK: Type ramp
    //
    // Serif is reserved for display/brand moments (titles ≥ 13pt). Dense control
    // labels use the system UI face for legibility at small sizes.

    public static func label(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight)
    }

    public static func title(_ size: CGFloat = 14, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    public static func numeric(_ size: CGFloat = 11, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }

    // MARK: Helpers

    static func dynamic(light: String, lightAlpha: CGFloat = 1, dark: String, darkAlpha: CGFloat = 1) -> Color {
        Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light).withAlphaComponent(isDark ? darkAlpha : lightAlpha)
        })
    }
}

// MARK: - Toolbar group container

extension View {
    /// Wraps a cluster of toolbar controls in a soft rounded well.
    func plumaControlGroup(cornerRadius: CGFloat = 8) -> some View {
        self
            .padding(2)
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(PlumaTheme.control))
    }
}
