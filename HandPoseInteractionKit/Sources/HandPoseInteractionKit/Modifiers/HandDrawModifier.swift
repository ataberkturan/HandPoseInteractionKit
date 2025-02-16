//
//  HandDrawModifier.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//


import SwiftUI

/**
 A view modifier that lets the user draw on a view using:
 - Normal finger drags, and
 - Hand pointer (with pinch active).
 
 The path is appended with line segments only while the pointer/finger is inside the view’s bounds.
 */
public struct HandDrawModifier: ViewModifier {
    @Binding private var path: Path
    @Binding private var pointer: CGPoint?
    @Binding private var pinchDetected: Bool
    
    @State private var lastFingerPoint: CGPoint? = nil
    @State private var lastHandPoint: CGPoint? = nil
    @State private var globalRect: CGRect = .zero
    
    /**
     - parameter path: The path to append to.
     - parameter pointer: The global pointer.
     - parameter pinchDetected: Whether pinch is active.
     */
    public init(path: Binding<Path>,
                pointer: Binding<CGPoint?>,
                pinchDetected: Binding<Bool>) {
        self._path = path
        self._pointer = pointer
        self._pinchDetected = pinchDetected
    }

    public func body(content: Content) -> some View {
        GeometryReader { geo in
            ZStack {
                content
                path.stroke(Color.blue, lineWidth: 3)
                    .allowsHitTesting(false)
            }
            .onAppear {
                globalRect = geo.frame(in: .global)
            }
            .onChange(of: geo.frame(in: .global)) { _, newFrame in
                globalRect = newFrame
            }
            // Finger drawing
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let local = value.location
                        // Make sure the local point is inside the local geometry
                        if local.x >= 0, local.x <= geo.size.width,
                           local.y >= 0, local.y <= geo.size.height {
                            if lastFingerPoint == nil {
                                path.move(to: local)
                            } else {
                                path.addLine(to: local)
                            }
                            lastFingerPoint = local
                        }
                    }
                    .onEnded { _ in
                        lastFingerPoint = nil
                    }
            )
            // Hand pointer drawing
            .onChange(of: pointer) { _, newPoint in
                guard let p = newPoint, pinchDetected else {
                    lastHandPoint = nil
                    return
                }
                // Check if pointer is in globalRect
                if globalRect.contains(p) {
                    // Convert to local coords
                    let local = CGPoint(x: p.x - globalRect.origin.x,
                                        y: p.y - globalRect.origin.y)
                    if lastHandPoint == nil {
                        path.move(to: local)
                    } else {
                        path.addLine(to: local)
                    }
                    lastHandPoint = local
                } else {
                    lastHandPoint = nil
                }
            }
        }
    }
}

public extension View {
    /**
     Attach a drawing modifier so the user can draw on this view with finger or hand pointer (pinch).
     - parameter path: The path to update.
     - parameter pointer: The global pointer in screen coords.
     - parameter pinchDetected: Whether pinch is active.
     */
    func handDraw(path: Binding<Path>,
                  pointer: Binding<CGPoint?>,
                  pinchDetected: Binding<Bool>) -> some View {
        self.modifier(HandDrawModifier(path: path,
                                       pointer: pointer,
                                       pinchDetected: pinchDetected))
    }
}
