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

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CODE & SNIPPETS")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                    .tracking(0.5)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // Paste Code Direct Button
            Button(action: {
                if let string = NSPasteboard.general.string(forType: .string) {
                    viewModel.addCodeBlock(code: string)
                } else {
                    viewModel.addCodeBlock()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard.fill")
                    Text("Paste Code from Clipboard")
                        .font(.system(size: 11, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: "#C2410C"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
                .hoverHighlight()
            .padding(.horizontal, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("SAMPLE TEMPLATES")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#D97706"))

                    ForEach(codePresets, id: \.title) { item in
                        Button(action: {
                            viewModel.addCodeBlock(code: item.code, language: item.lang)
                        }) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(item.title)
                                        .font(.system(size: 11, weight: .semibold, design: .serif))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(item.lang.rawValue)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                Text(item.desc)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                .hoverHighlight()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }
}
