import SwiftUI

public struct LeftSidebarView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Tab Rail — scrollable: on short windows the bottom tabs overflowed
            // and were clipped outside the hit region — dead clicks AND dead hover.
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(SidebarTab.allCases) { tab in
                            SidebarRailTabButton(
                                tab: tab,
                                isSelected: viewModel.activeSidebarTab == tab,
                                action: {
                                    viewModel.activeSidebarTab = tab
                                }
                            )
                            if tab == .backgrounds || tab == .layers {
                                // Group separators: create · structure · developer
                                Rectangle().fill(PlumaTheme.hairline)
                                    .frame(width: 28, height: 1)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                // Halftone press-mark pinned at the foot of the tool rail
                HalftonePatternView(
                    ink: PlumaTheme.accent.opacity(0.25),
                    spacing: 8,
                    maxRadius: 1.9,
                    ramp: .linear(angle: 90, from: 0.0, to: 0.85)
                )
                .frame(width: 52, height: 44)
                .padding(.bottom, 8)
            }
            .frame(width: 66)
            .background(PlumaTheme.chrome)

            Divider()

            // Drawer Content
            VStack(spacing: 0) {
                switch viewModel.activeSidebarTab {
                case .pages:
                    PagesTabView(viewModel: viewModel)
                case .templates:
                    TemplatesTabView(viewModel: viewModel)
                case .code:
                    CodeTabView(viewModel: viewModel)
                case .elements:
                    ElementsTabView(viewModel: viewModel)
                case .text:
                    TextTabView(viewModel: viewModel)
                case .media:
                    MediaTabView(viewModel: viewModel)
                case .icons:
                    IconsTabView(viewModel: viewModel)
                case .brandKit:
                    BrandKitTabView(viewModel: viewModel)
                case .backgrounds:
                    BackgroundsTabView(viewModel: viewModel)
                case .layers:
                    LayersTabView(viewModel: viewModel)
                }
            }
            .frame(width: 280)
            .background(Color(NSColor.controlBackgroundColor))
            // Full teardown on tab switch so recycled lazy-grid cells can never
            // carry stale hit regions from the previous tab.
            .id(viewModel.activeSidebarTab)

            Divider()
        }
    }
}

// MARK: - Interactive Sidebar Rail Tab Button with Full Hit Target & Hover Animation

struct SidebarRailTabButton: View {
    let tab: SidebarTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(isSelected ? PlumaTheme.accentOnSoft : (isHovered ? .primary : .secondary))
                    .frame(width: 36, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? PlumaTheme.accentSoft : (isHovered ? PlumaTheme.controlHover : Color.clear))
                    )

                Text(tab.rawValue)
                    .font(PlumaTheme.label(10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 60, height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tab.rawValue)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Shared drawer typography

/// Title row at the top of a drawer panel.
struct SidebarPanelHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(PlumaTheme.label(13, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }
}

/// Small uppercase group label inside a drawer panel (matches the inspector).
struct SidebarSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(PlumaTheme.label(10, weight: .semibold))
            .tracking(0.6)
            .foregroundColor(.secondary)
            .padding(.top, 4)
    }
}
