import SwiftUI

// MARK: - Shared Hover-Aware Button Styles
//
// Every interactive control in Pluma must:
//   1. Show clear hover feedback (so the user knows where they are aiming).
//   2. Provide a comfortable hit target (≥ 26pt) — no more pixel-hunting on icons.

/// Icon-only button with hover highlight and a guaranteed square hit target.
public struct HoverIconButtonStyle: ButtonStyle {
    public var side: CGFloat = 28
    public var cornerRadius: CGFloat = 7
    /// Fill color used when the button represents an active/selected state.
    public var selectedColor: Color = Color(hex: "#C2410C")
    public var isSelected: Bool = false
    /// Extra opacity applied to the icon when disabled.
    public var disabledOpacity: Double = 0.35

    public init(
        side: CGFloat = 28,
        cornerRadius: CGFloat = 7,
        selectedColor: Color = Color(hex: "#C2410C"),
        isSelected: Bool = false
    ) {
        self.side = side
        self.cornerRadius = cornerRadius
        self.selectedColor = selectedColor
        self.isSelected = isSelected
    }

    public func makeBody(configuration: Configuration) -> some View {
        HoverIconBody(
            configuration: configuration,
            side: side,
            cornerRadius: cornerRadius,
            selectedColor: selectedColor,
            isSelected: isSelected
        )
    }

    private struct HoverIconBody: View {
        let configuration: Configuration
        let side: CGFloat
        let cornerRadius: CGFloat
        let selectedColor: Color
        let isSelected: Bool
        @State private var hovering = false

        var body: some View {
            configuration.label
                .frame(minWidth: side, minHeight: side)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            configuration.isPressed
                                ? selectedColor.opacity(isSelected ? 0.9 : 0.22)
                                : isSelected
                                    ? selectedColor
                                    : (hovering ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
                .opacity(configuration.isPressed ? 0.9 : 1.0)
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.12)) {
                        self.hovering = hovering
                    }
                }
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

/// Pill / labeled button with hover lift (used for Import, Export, Duplicate, etc.).
public struct HoverPillButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat = 7
    /// Optional tint — when nil, neutral gray hover is used.
    public var tint: Color? = nil
    /// Renders a filled (primary) button instead of a soft tinted one.
    public var filled: Bool = false

    public init(cornerRadius: CGFloat = 7, tint: Color? = nil, filled: Bool = false) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.filled = filled
    }

    public func makeBody(configuration: Configuration) -> some View {
        HoverPillBody(
            configuration: configuration,
            cornerRadius: cornerRadius,
            tint: tint,
            filled: filled
        )
    }

    private struct HoverPillBody: View {
        let configuration: Configuration
        let cornerRadius: CGFloat
        let tint: Color?
        let filled: Bool
        @State private var hovering = false

        var body: some View {
            configuration.label
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(pillFill)
                )
                .opacity(configuration.isPressed ? 0.85 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.96 : hovering && !filled ? 1.02 : 1.0)
                .shadow(
                    color: filled && hovering ? Color.black.opacity(0.18) : .clear,
                    radius: 5, x: 0, y: 2
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.12)) {
                        self.hovering = hovering
                    }
                }
                .animation(.easeOut(duration: 0.12), value: hovering)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
        }

        private var pillFill: Color {
            let base = tint ?? Color(hex: "#C2410C")
            if configuration.isPressed { return filled ? base.opacity(0.8) : base.opacity(0.22) }
            if filled { return base }
            return hovering ? base.opacity(0.2) : base.opacity(0.12)
        }
    }
}

/// Toolbar tool toggle (Select / Hand / Text / Pen …) with hover ring.
public struct ToolToggleButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat = 6
    public var selectedColor: Color = Color(hex: "#C2410C")
    public var isSelected: Bool

    public init(isSelected: Bool, selectedColor: Color = Color(hex: "#C2410C"), cornerRadius: CGFloat = 6) {
        self.isSelected = isSelected
        self.selectedColor = selectedColor
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        ToolToggleBody(
            configuration: configuration,
            cornerRadius: cornerRadius,
            selectedColor: selectedColor,
            isSelected: isSelected
        )
    }

    private struct ToolToggleBody: View {
        let configuration: Configuration
        let cornerRadius: CGFloat
        let selectedColor: Color
        let isSelected: Bool
        @State private var hovering = false

        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            configuration.isPressed
                                ? (isSelected ? selectedColor.opacity(0.85) : Color.primary.opacity(0.18))
                                : isSelected
                                    ? selectedColor
                                    : (hovering ? Color.primary.opacity(0.12) : Color.clear)
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.12)) {
                        self.hovering = hovering
                    }
                }
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

/// Segmented control segment (layout mode switcher etc.) with hover feedback.
public struct SegmentedSegmentStyle: ButtonStyle {
    public var isSelected: Bool
    public var selectedColor: Color = Color(hex: "#C2410C")

    public init(isSelected: Bool, selectedColor: Color = Color(hex: "#C2410C")) {
        self.isSelected = isSelected
        self.selectedColor = selectedColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        SegmentBody(configuration: configuration, isSelected: isSelected, selectedColor: selectedColor)
    }

    private struct SegmentBody: View {
        let configuration: Configuration
        let isSelected: Bool
        let selectedColor: Color
        @State private var hovering = false

        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            configuration.isPressed
                                ? (isSelected ? selectedColor.opacity(0.85) : Color.primary.opacity(0.16))
                                : isSelected
                                    ? selectedColor
                                    : (hovering ? Color.primary.opacity(0.1) : Color.clear)
                        )
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.12)) {
                        self.hovering = hovering
                    }
                }
        }
    }
}

// MARK: - Small circular icon button (page header pills, zoom dock)

public struct CircleHoverButtonStyle: ButtonStyle {
    public var side: CGFloat = 26
    public var isSelected: Bool = false
    public var danger: Bool = false

    public init(side: CGFloat = 26, isSelected: Bool = false, danger: Bool = false) {
        self.side = side
        self.isSelected = isSelected
        self.danger = danger
    }

    public func makeBody(configuration: Configuration) -> some View {
        CircleHoverBody(configuration: configuration, side: side, isSelected: isSelected, danger: danger)
    }

    private struct CircleHoverBody: View {
        let configuration: Configuration
        let side: CGFloat
        let isSelected: Bool
        let danger: Bool
        @State private var hovering = false

        var body: some View {
            configuration.label
                .frame(minWidth: side, minHeight: side)
                .background(
                    Circle().fill(
                        configuration.isPressed
                            ? (danger ? Color.red.opacity(0.3) : Color.primary.opacity(0.2))
                            : isSelected
                                ? Color(hex: "#C2410C")
                                : (hovering ? Color.primary.opacity(0.14) : Color.primary.opacity(0.06))
                    )
                )
                .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
                .contentShape(Circle())
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.12)) {
                        self.hovering = hovering
                    }
                }
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

// MARK: - Universal Hover Highlight Modifier
// Adds a soft hover glow to any control (used to retrofit hover feedback onto
// existing buttons without restructuring their internals).

public struct HoverHighlightModifier: ViewModifier {
    public var cornerRadius: CGFloat = 6
    public var opacity: Double = 0.1
    public var scaleOnHover: Bool = false
    @State private var hovering = false

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.primary.opacity(hovering ? opacity : 0))
            )
            .scaleEffect(hovering && scaleOnHover ? 1.03 : 1.0)
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

extension View {
    /// Adds hover feedback (soft highlight) to any view — guarantees the user can
    /// always see which control the cursor is aimed at.
    public func hoverHighlight(cornerRadius: CGFloat = 6, opacity: Double = 0.1, scale: Bool = false) -> some View {
        modifier(HoverHighlightModifier(cornerRadius: cornerRadius, opacity: opacity, scaleOnHover: scale))
    }
}
