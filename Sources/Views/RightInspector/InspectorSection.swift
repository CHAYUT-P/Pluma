import SwiftUI

/// Collapsible inspector group: a disclosure header (uppercase label) with an
/// optional trailing accessory that stays visible while collapsed (e.g. the
/// Border on/off switch). Each section remembers its collapsed state across
/// selections and launches, keyed by `key` (defaults to the title).
struct InspectorSection<Accessory: View, Content: View>: View {
    private let title: String
    private let accessory: Accessory
    private let content: Content
    @AppStorage private var isCollapsed: Bool

    init(
        _ title: String,
        key: String? = nil,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.accessory = accessory()
        self.content = content()
        _isCollapsed = AppStorage(wrappedValue: false, "inspector.collapsed.\(key ?? title.lowercased())")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.15)) { isCollapsed.toggle() }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                            .frame(width: 10)
                        Text(title.uppercased())
                            .font(PlumaTheme.label(10, weight: .semibold))
                            .tracking(0.6)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(isCollapsed ? "Show \(title.lowercased())" : "Hide \(title.lowercased())")

                accessory
            }

            if !isCollapsed {
                content
            }
        }
    }
}

extension InspectorSection where Accessory == EmptyView {
    init(_ title: String, key: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title, key: key, accessory: { EmptyView() }, content: content)
    }
}
