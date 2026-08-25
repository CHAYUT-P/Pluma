import SwiftUI

public struct TextTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TYPOGRAPHY & HEADINGS")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Masthead & Headline Buttons
                    Button(action: {
                        viewModel.addText(text: "THE DAILY DISPATCH", fontSize: 64, fontWeight: 900, fontFamily: "Playfair Display", color: .inkBlack)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Newspaper Masthead")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                                Text("Playfair 64pt • Woodblock Gothic")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(Color(hex: "#C2410C"))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                .hoverHighlight()

                    Button(action: {
                        viewModel.addText(text: "MACBOOK FREED FROM 10GB BLOAT!", fontSize: 36, fontWeight: 800, fontFamily: "Playfair Display", color: .inkBlack)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lead Front-Page Headline")
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                                Text("Bold Serif 36pt")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(Color(hex: "#C2410C"))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                .hoverHighlight()

                    Button(action: {
                        viewModel.addText(text: "A breakthrough for personal computing. Swift engineering slashes memory overhead to 40 MB.", fontSize: 16, fontWeight: 400, fontFamily: "Georgia", color: CodableColor(hex: "#292524"))
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Editorial Column Paragraph")
                                    .font(.system(size: 12, weight: .medium, design: .serif))
                                    .foregroundColor(.primary)
                                Text("Georgia 16pt • Justified Body")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(Color(hex: "#C2410C"))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                .hoverHighlight()

                    Button(action: {
                        viewModel.addText(text: "CONFIDENTIAL MEMO: 1924", fontSize: 18, fontWeight: 700, fontFamily: "Courier New", color: CodableColor(hex: "#3D3833"))
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Typewriter Letter")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.primary)
                                Text("Courier New 18pt • Mechanical")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(Color(hex: "#C2410C"))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                .hoverHighlight()

                    Text("SPECIAL INK STYLES")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#C2410C"))
                        .tracking(0.3)
                        .padding(.top, 6)

                    // Stamped & Letterpress Styles
                    Button(action: {
                        viewModel.saveHistoryState()
                        let elem = CanvasElement(
                            name: "Rubber Stamp Text",
                            payload: .text(TextContent(
                                text: "★ CERTIFIED NATIVE ★",
                                fontFamily: "Playfair Display",
                                fontSize: 24,
                                fontWeight: 900,
                                textColor: CodableColor.terracotta,
                                letterSpacing: 2.0,
                                effectKind: .stampDistressed,
                                effectColor: CodableColor.terracotta
                            )),
                            x: 200, y: 200, width: 340, height: 60
                        )
                        viewModel.currentPage.elements.append(elem)
                        viewModel.selectedElementIds = [elem.id]
                    }) {
                        HStack {
                            Text("★ RUBBER STAMP ★")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "#C2410C"))
                            Spacer()
                            Image(systemName: "seal.fill")
                                .foregroundColor(Color(hex: "#C2410C"))
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                .hoverHighlight()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }
}
