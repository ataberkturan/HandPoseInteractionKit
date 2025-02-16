//
//  HandPoseConfiguration.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//


import SwiftUI
import Vision

/**
 A configuration struct for hand pose detection thresholds.
 
 - `pinchDistanceThreshold`: The max distance between index & thumb for pinch.
 - `handSizeThreshold`: Minimum distance from wrist to index to ensure hand is close enough.
 - `confidenceThreshold`: Minimum confidence for recognized landmarks.
 */
public struct HandPoseConfiguration {
    public var pinchDistanceThreshold: CGFloat
    public var handSizeThreshold: CGFloat
    public var confidenceThreshold: VNConfidence

    public init(pinchDistanceThreshold: CGFloat = 0.05,
                handSizeThreshold: CGFloat = 0.2,
                confidenceThreshold: VNConfidence = 0.5) {
        self.pinchDistanceThreshold = pinchDistanceThreshold
        self.handSizeThreshold = handSizeThreshold
        self.confidenceThreshold = confidenceThreshold
    }
}
