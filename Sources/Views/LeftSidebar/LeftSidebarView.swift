import SwiftUI

public struct LeftSidebarView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Tab Rail (With Large Interactive Hover Button Cards)
            VStack(spacing: 4) {
                ForEach(SidebarTab.allCases) { tab in
                    SidebarRailTabButton(
                        tab: tab,
                        isSelected: viewModel.activeSidebarTab == tab,
                        action: {
                            viewModel.activeSidebarTab = tab
                        }
                    )
                }

                Spacer()
            }
            .frame(width: 72)
            .padding(.top, 8)
            .background(Color(NSColor.windowBackgroundColor))

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
                case .draw:
                    DrawingTabView(viewModel: viewModel)
                case .layers:
                    LayersTabView(viewModel: viewModel)
                }
            }
            .frame(width: 280)
            .background(Color(NSColor.controlBackgroundColor))

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
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "#C2410C") : (isHovered ? .primary : .secondary))

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .serif))
                    .foregroundColor(isSelected ? .primary : (isHovered ? .primary : .secondary))
                    .lineLimit(1)
            }
            .frame(width: 64, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#C2410C").opacity(0.14) : (isHovered ? Color.secondary.opacity(0.1) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#C2410C").opacity(0.4) : (isHovered ? Color.secondary.opacity(0.18) : Color.clear), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
                .hoverHighlight()
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
