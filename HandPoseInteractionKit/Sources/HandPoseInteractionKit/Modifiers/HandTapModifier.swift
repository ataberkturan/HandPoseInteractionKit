//
//  HandTapModifier.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//


import SwiftUI

/**
 A view modifier that triggers an action if either:
 1) The user taps the view normally (if `enableTouch` is true).
 2) The hand pointer (midpoint of index & thumb) enters the view's frame *while pinch is active*.
 */
public struct HandTapModifier: ViewModifier {
    private let action: () -> Void
    @Binding private var pointer: CGPoint?
    @Binding private var pinchDetected: Bool
    private let enableTouch: Bool
    
    @State private var frame: CGRect = .zero
    @State private var didTrigger = false

    /**
     - parameter action: The closure to invoke when triggered.
     - parameter pointer: A binding to the global pointer (in screen coordinates).
     - parameter pinchDetected: A binding indicating whether a pinch is active.
     - parameter enableTouch: If true, also respond to normal taps.
     */
    public init(action: @escaping () -> Void,
                pointer: Binding<CGPoint?>,
                pinchDetected: Binding<Bool>,
                enableTouch: Bool = true) {
        self.action = action
        self._pointer = pointer
        self._pinchDetected = pinchDetected
        self.enableTouch = enableTouch
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { frame = geo.frame(in: .global) }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                        }
                }
            )
            .if(enableTouch) { view in
                view.onTapGesture { action() }
            }
            .onChange(of: pointer) { _, newPoint in
                guard let p = newPoint, pinchDetected else {
                    didTrigger = false
                    return
                }
                if frame.contains(p) {
                    if !didTrigger {
                        didTrigger = true
                        action()
                    }
                } else {
                    didTrigger = false
                }
            }
    }
}

public extension View {
    /**
     Attach a "tap" style interaction that triggers `action` on normal tap or if the hand pointer enters this view’s frame while pinch is active.
     - parameter pointer: The global pointer in screen coords.
     - parameter pinchDetected: Whether pinch is active.
     - parameter enableTouch: Also respond to normal taps.
     - parameter action: The closure to call.
     */
    func handTap(pointer: Binding<CGPoint?>,
                 pinchDetected: Binding<Bool>,
                 enableTouch: Bool = true,
                 action: @escaping () -> Void) -> some View {
        self.modifier(HandTapModifier(action: action,
                                      pointer: pointer,
                                      pinchDetected: pinchDetected,
                                      enableTouch: enableTouch))
    }
}
