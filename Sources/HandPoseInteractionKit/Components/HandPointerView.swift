//
//  HandPointerView.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//


import SwiftUI

/// A customizable pointer view for displaying a hand pointer.
/// You can set the color and diameter.
public struct HandPointerView: View {
    public var color: Color
    public var diameter: CGFloat

    public init(color: Color = .red, diameter: CGFloat = 20) {
        self.color = color
        self.diameter = diameter
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
    }
}
