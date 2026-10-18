import SwiftUI

public struct CodeSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        if let element = viewModel.primarySelectedElement,
           case .code(let codeContent) = element.payload {
            InspectorSection("Code", accessory: {
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(codeContent.code, forType: .string)
                        viewModel.showTemporaryToast("📋 Code Copied to Clipboard!")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
            }) {
                // Language Picker
                Picker("Language", selection: Binding(
                    get: { codeContent.language },
                    set: { newLang in
                        viewModel.updateSelectedElement { elem in
                            if case .code(var c) = elem.payload {
                                c.language = newLang
                                if c.windowTitle.contains(".") || c.windowTitle.isEmpty {
                                    c.windowTitle = "snippet.\(newLang.fileExtension)"
                                }
                                elem.payload = .code(c)
                            }
                        }
                    }
                )) {
                    ForEach(CodeLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.menu)

                // Theme Picker
                Picker("Color Theme", selection: Binding(
                    get: { codeContent.theme },
                    set: { newTheme in
                        viewModel.updateSelectedElement { elem in
                            if case .code(var c) = elem.payload {
                                c.theme = newTheme
                                elem.payload = .code(c)
                            }
                        }
                    }
                )) {
                    ForEach(CodeTheme.allCases) { th in
                        Text(th.rawValue).tag(th)
                    }
                }
                .pickerStyle(.menu)

                // Window Title
                HStack {
                    Text("Title")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("File title", text: Binding(
                        get: { codeContent.windowTitle },
                        set: { newTitle in
                            viewModel.updateSelectedElement { elem in
                                if case .code(var c) = elem.payload {
                                    c.windowTitle = newTitle
                                    elem.payload = .code(c)
                                }
                            }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                }

                // Toggles
                Toggle("Window header", isOn: Binding(
                    get: { codeContent.showWindowHeader },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .code(var c) = elem.payload {
                                c.showWindowHeader = val
                                elem.payload = .code(c)
                            }
                        }
                    }
                ))
                .font(.system(size: 11))

                Toggle("Line numbers", isOn: Binding(
                    get: { codeContent.showLineNumbers },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .code(var c) = elem.payload {
                                c.showLineNumbers = val
                                elem.payload = .code(c)
                            }
                        }
                    }
                ))
                .font(.system(size: 11))

                // Font Size Slider
                HStack {
                    Text("Font Size")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { codeContent.fontSize },
                        set: { val in
                            viewModel.updateSelectedElement { elem in
                                if case .code(var c) = elem.payload {
                                    c.fontSize = val
                                    elem.payload = .code(c)
                                }
                            }
                        }
                    ), in: 10...28, step: 1)
                    Text("\(Int(codeContent.fontSize)) pt")
                        .font(.system(size: 10.5, design: .monospaced))
                        .frame(width: 32)
                }

                // Paste from clipboard button
                Button(action: {
                    if let string = NSPasteboard.general.string(forType: .string) {
                        viewModel.saveHistoryState()
                        viewModel.updateSelectedElement { elem in
                            if case .code(var c) = elem.payload {
                                c.code = string
                                elem.payload = .code(c)
                                elem.height = CanvasDocumentViewModel.calculateCodeBlockHeight(for: c)
                            }
                        }
                        viewModel.showTemporaryToast("📥 Pasted Code from Clipboard!")
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Paste from Clipboard")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(PlumaTheme.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)

                // Inline Code Editor
                VStack(alignment: .leading, spacing: 4) {
                    Text("Code Editor")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(.secondary)

                    TextEditor(text: Binding(
                        get: { codeContent.code },
                        set: { newCode in
                            viewModel.updateCodeAndFitHeight(id: element.id, newCode: newCode)
                        }
                    ))
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 140)
                    .padding(4)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                }
            }
        }
    }
}
