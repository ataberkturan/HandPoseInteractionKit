//
//  ss.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//


import SwiftUI

/**
 A small extension to conditionally apply a transform in a ViewBuilder context.
 */
public extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                              transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/**
 Converts normalized coordinates (origin at bottom-left) to screen coordinates (origin at top-left).
 
 - parameter point: A point in normalized [0..1] coordinates.
 - parameter size: The size of the target coordinate space (e.g. screen).
 - returns: The corresponding point in the target space.
 */
public func convertNormalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(x: point.x * size.width,
            y: (1 - point.y) * size.height)
}
