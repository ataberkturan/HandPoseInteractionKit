//
//  HandDragModifier.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//


import SwiftUI

/**
 A view modifier that lets a view be dragged by the hand pointer (with pinch) if the pointer is inside the view’s frame.
 Optionally, can also enable normal finger dragging.
 */
public struct HandDragModifier: ViewModifier {
    @Binding private var offset: CGSize
    @Binding private var pointer: CGPoint?
    @Binding private var pinchDetected: Bool
    private let allowTouchDrag: Bool
    
    @State private var initialPointer: CGPoint? = nil
    @State private var initialOffset: CGSize = .zero
    @State private var frame: CGRect = .zero
    @State private var isDragging = false

    /**
     - parameter offset: The view’s offset.
     - parameter pointer: The global pointer.
     - parameter pinchDetected: Whether pinch is active.
     - parameter allowTouchDrag: If true, also allow normal finger dragging.
     */
    public init(offset: Binding<CGSize>,
                pointer: Binding<CGPoint?>,
                pinchDetected: Binding<Bool>,
                allowTouchDrag: Bool = false) {
        self._offset = offset
        self._pointer = pointer
        self._pinchDetected = pinchDetected
        self.allowTouchDrag = allowTouchDrag
    }

    public func body(content: Content) -> some View {
        content
            .offset(offset)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                        }
                }
            )
            .if(allowTouchDrag) { view in
                view.gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                )
            }
            // Listen for pointer changes
            .onChange(of: pointer) { _, newPoint in
                guard let p = newPoint else {
                    // pointer is gone
                    isDragging = false
                    initialPointer = nil
                    return
                }
                if !pinchDetected {
                    // If pinch isn't active, stop dragging
                    isDragging = false
                    initialPointer = nil
                    return
                }
                // Check if pointer is inside
                if frame.contains(p) {
                    if !isDragging {
                        isDragging = true
                        initialPointer = p
                        initialOffset = offset
                    } else {
                        if let start = initialPointer {
                            let dx = p.x - start.x
                            let dy = p.y - start.y
                            offset = CGSize(width: initialOffset.width + dx,
                                            height: initialOffset.height + dy)
                        }
                    }
                } else {
                    // pointer outside
                    isDragging = false
                    initialPointer = nil
                }
            }
    }
}

public extension View {
    /**
     Makes this view draggable by the hand pointer (with pinch) if the pointer is inside the view’s frame.
     Optionally also allow normal finger dragging.
     - parameter offset: A binding to the view’s offset.
     - parameter pointer: The global pointer in screen coords.
     - parameter pinchDetected: Whether pinch is active.
     - parameter allowTouchDrag: Also allow normal finger drag if true.
     */
    func handDrag(offset: Binding<CGSize>,
                  pointer: Binding<CGPoint?>,
                  pinchDetected: Binding<Bool>,
                  allowTouchDrag: Bool = false) -> some View {
        self.modifier(HandDragModifier(offset: offset,
                                       pointer: pointer,
                                       pinchDetected: pinchDetected,
                                       allowTouchDrag: allowTouchDrag))
    }
}
