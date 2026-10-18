import SwiftUI

public struct CodeTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    private let codePresets: [(title: String, desc: String, lang: CodeLanguage, code: String)] = [
        ("SwiftUI View", "Native Apple Silicon UI", .swift, """
        struct ContentView: View {
            var body: some View {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.tint)
                    Text("CanvaNative Studio")
                        .font(.headline)
                }
                .padding()
            }
        }
        """),

        ("Python Script", "Clean Python Logic", .python, """
        import numpy as np

        def calculate_velocity(mass, acceleration):
            \"\"\"Calculate kinetic momentum\"\"\"
            velocity = np.sqrt(2 * acceleration * mass)
            return velocity

        print(f"Velocity: {calculate_velocity(10, 9.8):.2f} m/s")
        """),

        ("React / TypeScript", "Modern Web Component", .typescript, """
        import React, { useState } from 'react';

        export const Counter = () => {
            const [count, setCount] = useState<number>(0);
            return (
                <button onClick={() => setCount(c => c + 1)}>
                    Count: {count}
                </button>
            );
        };
        """),

        ("Rust Function", "Memory Safe Systems", .rust, """
        fn main() {
            let message = "Ultra fast native canvas";
            println!("{}", message);
        }
        """),

        ("JSON Schema", "Structured Data Payload", .json, """
        {
            "appName": "CanvaNative",
            "version": "2.0.0",
            "ramUsageMB": 42.5,
            "offline": true
        }
        """)
    ]

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    /// One developer drawer (formerly separate Code and Dev tabs): code
    /// snippets on top, then software-engineering building blocks — windows,
    /// chips & badges, and one-click diagram stamps.
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SidebarPanelHeader("Code")

            Button(action: {
                if let string = NSPasteboard.general.string(forType: .string) {
                    viewModel.addCodeBlock(code: string)
                } else {
                    viewModel.addCodeBlock()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste Code as Snippet")
                        .font(PlumaTheme.label(12, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
            }
            .buttonStyle(HoverPillButtonStyle(filled: true))
            .help("Creates a code block from the clipboard text")
            .padding(.horizontal, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    SidebarSectionHeader("Snippets")

                    ForEach(codePresets, id: \.title) { item in
                        Button(action: {
                            viewModel.addCodeBlock(code: item.code, language: item.lang)
                        }) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(PlumaTheme.label(12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(item.desc)
                                        .font(PlumaTheme.label(10.5, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(item.lang.rawValue)
                                    .font(PlumaTheme.label(10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.control))
                        }
                        .buttonStyle(.plain)
                        .hoverHighlight(cornerRadius: 7)
                    }

                    SidebarSectionHeader("Windows & Hardware")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        presetButton(title: "Terminal", icon: "terminal.fill") { DevKitPresets.terminalWindow() }
                        presetButton(title: "Browser", icon: "safari.fill") { DevKitPresets.browserWindow() }
                        presetButton(title: "Database", icon: "cylinder.fill") { DevKitPresets.databaseCylinder() }
                        presetButton(title: "Server", icon: "server.rack") { DevKitPresets.serverUnit() }
                    }

                    SidebarSectionHeader("Chips & Badges")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        presetButton(title: "GET Chip", icon: "network") {
                            DevKitPresets.apiChip(method: "GET", path: "/api/v1/users")
                        }
                        presetButton(title: "POST Chip", icon: "network.badge.shield.half.filled") {
                            DevKitPresets.apiChip(method: "POST", path: "/api/v1/deploy")
                        }
                        presetButton(title: "Badge ✓", icon: "checkmark.seal.fill") { DevKitPresets.statusBadge() }
                        presetButton(title: "Badge cov", icon: "percent") {
                            DevKitPresets.statusBadge(left: "coverage", right: "94%")
                        }
                        presetButton(title: "Keycap ⌘", icon: "command.square.fill") { DevKitPresets.keyCap("⌘") }
                        presetButton(title: "TODO Note", icon: "checklist") { DevKitPresets.todoSticky() }
                    }

                    SidebarSectionHeader("Diagram Stamps")
                    VStack(spacing: 8) {
                        diagramButton(title: "Client → API → DB Flow", icon: "arrow.triangle.swap", desc: "Request lifecycle with labeled arrows") {
                            DevKitPresets.requestFlowDiagram()
                        }
                        diagramButton(title: "CI/CD Pipeline", icon: "gearshape.2.fill", desc: "Commit → build → test → deploy chain") {
                            DevKitPresets.cicdPipeline()
                        }
                        diagramButton(title: "Kanban Board", icon: "rectangle.3.group.fill", desc: "3-column sprint board with cards") {
                            DevKitPresets.kanbanBoard()
                        }
                        diagramButton(title: "Git Branch Flow", icon: "point.topleft.down.to.point.bottomright.curvepath.fill", desc: "main + feature branch commits & merge") {
                            DevKitPresets.gitFlow()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    private func presetButton(title: String, icon: String, bundle: @escaping () -> [CanvasElement]) -> some View {
        Button(action: {
            viewModel.insertElements(bundle(), name: title)
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(PlumaTheme.accentOnSoft)
                Text(title)
                    .font(PlumaTheme.label(10.5))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.control))
        }
        .buttonStyle(.plain)
        .hoverHighlight(cornerRadius: 7)
    }

    private func diagramButton(title: String, icon: String, desc: String, bundle: @escaping () -> [CanvasElement]) -> some View {
        Button(action: {
            viewModel.insertElements(bundle(), name: title)
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(PlumaTheme.accentOnSoft)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(PlumaTheme.label(12, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(desc)
                        .font(PlumaTheme.label(10.5, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.control))
        }
        .buttonStyle(.plain)
        .hoverHighlight(cornerRadius: 7)
    }
}
