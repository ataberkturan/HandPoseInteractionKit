//
//  HandPointerModifier.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//


import SwiftUI

/// A view modifier that overlays a pointer view at a given global point.
public struct HandPointerModifier<PointerView: View>: ViewModifier {
    @Binding var pointer: CGPoint?
    let pointerView: PointerView

    public init(pointer: Binding<CGPoint?>, pointerView: PointerView) {
        self._pointer = pointer
        self.pointerView = pointerView
    }

    public func body(content: Content) -> some View {
        ZStack {
            content
            if let pt = pointer {
                pointerView
                    .position(pt)
            }
        }
    }
}

public extension View {
    /**
     Overlays a hand pointer view at the location provided by `pointer`.
     
     - Parameters:
       - pointer: A binding to the pointer's global coordinates.
       - pointerView: A closure that returns a custom pointer view.
     - Returns: A view with the pointer overlay.
     */
    func handPointer<PointerView: View>(
        pointer: Binding<CGPoint?>,
        @ViewBuilder pointerView: () -> PointerView
    ) -> some View {
        self.modifier(HandPointerModifier(pointer: pointer, pointerView: pointerView()))
    }
    
    /**
     Overlays a default hand pointer view.
     
     - Parameters:
       - pointer: A binding to the pointer's global coordinates.
       - color: The pointer's color (default is red).
       - diameter: The pointer's diameter (default is 20).
     - Returns: A view with the pointer overlay.
     */
    func handPointer(
        pointer: Binding<CGPoint?>,
        color: Color = .red,
        diameter: CGFloat = 20
    ) -> some View {
        self.handPointer(pointer: pointer) {
            HandPointerView(color: color, diameter: diameter)
        }
    }
}
