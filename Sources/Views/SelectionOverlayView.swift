import SwiftUI
import AppKit

public struct SelectionOverlayView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    let element: CanvasElement
    /// Name of the page-level coordinate space ("canvasSpace_\(pageIndex)").
    /// Gestures MUST resolve into this space so drag translations are in canvas units.
    let coordinateSpaceName: String

    private let visibleHandleSize: CGFloat = 11
    private let touchTargetSize: CGFloat = 28
    private let accentColor = Color(hex: "#C2410C") // Burnt studio terracotta

    public init(viewModel: CanvasDocumentViewModel, element: CanvasElement, coordinateSpaceName: String) {
        self.viewModel = viewModel
        self.element = element
        self.coordinateSpaceName = coordinateSpaceName
    }

    public var body: some View {
        ZStack {
            // Selection Bounding Box (Visual Only - Never blocks clicks)
            Rectangle()
                .stroke(accentColor, lineWidth: 1.5 / max(0.5, viewModel.zoomScale))
                .frame(width: element.width, height: element.height)
                .allowsHitTesting(false)

            // Resize Handles with Large Hit Targets (28x28px)
            if !element.isLocked {
                // Top-Left Handle
                handleNode(position: .topLeft)
                    .offset(x: -element.width / 2, y: -element.height / 2)

                // Top Handle
                handleNode(position: .top)
                    .offset(x: 0, y: -element.height / 2)

                // Top-Right Handle
                handleNode(position: .topRight)
                    .offset(x: element.width / 2, y: -element.height / 2)

                // Left Handle
                handleNode(position: .left)
                    .offset(x: -element.width / 2, y: 0)

                // Right Handle
                handleNode(position: .right)
                    .offset(x: element.width / 2, y: 0)

                // Bottom-Left Handle
                handleNode(position: .bottomLeft)
                    .offset(x: -element.width / 2, y: element.height / 2)

                // Bottom Handle
                handleNode(position: .bottom)
                    .offset(x: 0, y: element.height / 2)

                // Bottom-Right Handle
                handleNode(position: .bottomRight)
                    .offset(x: element.width / 2, y: element.height / 2)

                // Rotation Stem & Large Dial (constant on-screen size at any zoom)
                VStack(spacing: 0) {
                    ZStack {
                        // Large hit target
                        Color.clear
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())

                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(accentColor, lineWidth: 2)
                            )
                            .overlay(
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(accentColor)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .named(coordinateSpaceName))
                            .onChanged { value in
                                if !viewModel.isRotatingElement {
                                    viewModel.beginRotation(id: element.id, startLocation: value.startLocation)
                                }
                                viewModel.updateRotation(id: element.id, currentLocation: value.location)
                            }
                            .onEnded { _ in
                                viewModel.endRotation()
                            }
                    )

                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 1.5, height: 14)
                }
                .scaleEffect(1.0 / max(0.5, viewModel.zoomScale), anchor: .bottom)
                .offset(y: -element.height / 2 + 3)

                // Dimensions & Rotation Tooltip Tag
                VStack {
                    Spacer()
                    Text("\(Int(element.width)) × \(Int(element.height)) px • \(Int(element.rotation))°")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .scaleEffect(1.0 / max(0.5, viewModel.zoomScale), anchor: .top)
                        .offset(y: 22 / max(0.5, viewModel.zoomScale))
                }
                .frame(width: element.width, height: element.height)
                .allowsHitTesting(false)
            }
        }
        .frame(width: element.width, height: element.height)
        .rotationEffect(.degrees(element.rotation))
        .position(x: element.x + element.width / 2, y: element.y + element.height / 2)
    }

    private func handleNode(position: ResizeHandlePosition) -> some View {
        ZStack {
            // Large invisible hit target (28x28px) so clicking is effortless!
            Color.clear
                .frame(width: touchTargetSize, height: touchTargetSize)
                .contentShape(Rectangle())

            // Visible node (11x11px) — constant screen size regardless of canvas zoom
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white)
                .frame(width: visibleHandleSize, height: visibleHandleSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 2.5)
                        .stroke(accentColor, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                .scaleEffect(1.0 / max(0.5, viewModel.zoomScale))
        }
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .named(coordinateSpaceName))
                .onChanged { value in
                    if viewModel.activeResizeInitialFrame == nil {
                        viewModel.beginResize(id: element.id, handle: position)
                    }
                    viewModel.updateResize(
                        id: element.id,
                        handle: position,
                        translation: value.translation,
                        lockAspectRatio: NSEvent.modifierFlags.contains(.shift)
                    )
                }
                .onEnded { _ in
                    viewModel.endResize()
                }
        )
    }
}
