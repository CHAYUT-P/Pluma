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
            // Global-space translation divided by zoom → canvas units, matching
            // the element-drag path. (The old `.named` translation was in screen
            // points, so resizes at zoom != 100% moved the wrong distance and
            // felt laggy/jumpy while producing wrong sizes.)
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    if viewModel.activeResizeInitialFrame == nil {
                        viewModel.beginResize(id: element.id, handle: position)
                    }
                    let zoom = max(0.05, viewModel.zoomScale)
                    viewModel.updateResize(
                        id: element.id,
                        handle: position,
                        translation: CGSize(
                            width: value.translation.width / zoom,
                            height: value.translation.height / zoom
                        ),
                        lockAspectRatio: NSEvent.modifierFlags.contains(.shift)
                    )
                }
                .onEnded { _ in
                    viewModel.endResize()
                }
        )
    }
}

// MARK: - Multi-Selection Group Box (Figma-style collective transform)

/// One collective bounding box around every selected element. Dragging a handle
/// scales ALL members proportionally about the stationary anchor, and the dial
/// rotates the whole selection around its shared center — so composite objects
/// (browser windows, device frames, grouped art) transform as a single unit.
public struct GroupSelectionOverlayView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    let coordinateSpaceName: String

    private let visibleHandleSize: CGFloat = 11
    private let touchTargetSize: CGFloat = 28
    private let accentColor = Color(hex: "#C2410C")

    public init(viewModel: CanvasDocumentViewModel, coordinateSpaceName: String) {
        self.viewModel = viewModel
        self.coordinateSpaceName = coordinateSpaceName
    }

    public var body: some View {
        let bounds = viewModel.selectionBounds
        ZStack {
            // Collective bounding box (visual only — never blocks clicks)
            Rectangle()
                .stroke(accentColor, lineWidth: 1.5 / max(0.5, viewModel.zoomScale))
                .frame(width: bounds.width, height: bounds.height)
                .allowsHitTesting(false)

            // Resize handles — scale every member about the opposite anchor
            handleNode(position: .topLeft).offset(x: -bounds.width / 2, y: -bounds.height / 2)
            handleNode(position: .top).offset(x: 0, y: -bounds.height / 2)
            handleNode(position: .topRight).offset(x: bounds.width / 2, y: -bounds.height / 2)
            handleNode(position: .left).offset(x: -bounds.width / 2, y: 0)
            handleNode(position: .right).offset(x: bounds.width / 2, y: 0)
            handleNode(position: .bottomLeft).offset(x: -bounds.width / 2, y: bounds.height / 2)
            handleNode(position: .bottom).offset(x: 0, y: bounds.height / 2)
            handleNode(position: .bottomRight).offset(x: bounds.width / 2, y: bounds.height / 2)

            // Rotation stem & dial — orbits every member around the shared center
            VStack(spacing: 0) {
                ZStack {
                    Color.clear
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(accentColor, lineWidth: 2))
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
                            if !viewModel.isRotatingGroup {
                                viewModel.beginGroupRotation(startLocation: value.startLocation)
                            }
                            viewModel.updateGroupRotation(currentLocation: value.location)
                        }
                        .onEnded { _ in
                            viewModel.endGroupRotation()
                        }
                )
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 1.5, height: 14)
            }
            .scaleEffect(1.0 / max(0.5, viewModel.zoomScale), anchor: .bottom)
            .offset(y: -bounds.height / 2 + 3)

            // Collective dimensions tag
            VStack {
                Spacer()
                Text("\(Int(bounds.width)) × \(Int(bounds.height)) px • \(viewModel.selectedElementIds.count) items")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .scaleEffect(1.0 / max(0.5, viewModel.zoomScale), anchor: .top)
                    .offset(y: 22 / max(0.5, viewModel.zoomScale))
            }
            .frame(width: bounds.width, height: bounds.height)
            .allowsHitTesting(false)
        }
        .frame(width: bounds.width, height: bounds.height)
        .position(x: bounds.midX, y: bounds.midY)
    }

    private func handleNode(position: ResizeHandlePosition) -> some View {
        ZStack {
            Color.clear
                .frame(width: touchTargetSize, height: touchTargetSize)
                .contentShape(Rectangle())
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
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    if viewModel.groupResizeInitialBounds == nil {
                        viewModel.beginGroupResize()
                    }
                    let zoom = max(0.05, viewModel.zoomScale)
                    viewModel.updateGroupResize(
                        handle: position,
                        translation: CGSize(
                            width: value.translation.width / zoom,
                            height: value.translation.height / zoom
                        ),
                        lockAspectRatio: NSEvent.modifierFlags.contains(.shift)
                    )
                }
                .onEnded { _ in
                    viewModel.endGroupResize()
                }
        )
    }
}
