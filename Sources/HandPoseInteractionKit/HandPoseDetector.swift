//
//  HandPoseDetector.swift
//  HandPoseInteractionKit
//
//  Created by Ataberk Turan on 16/02/2025.
//

import SwiftUI
import AVFoundation
import Vision

/*
 A class that uses the front camera + Vision to detect a single hand's index and thumb tips,
 and publishes a boolean flag if a pinch is detected (i.e., the tips are close enough).
 
 - indexTip, thumbTip: Normalized coordinates in the range (0..1), origin at bottom-left.
 - pinchDetected: True if the distance between index & thumb is below configuration.pinchDistanceThreshold.
 - configuration: Tweak thresholds and confidence requirements.
 */

@MainActor public final class HandPoseDetector: NSObject, ObservableObject {
    @Published public var indexTip: CGPoint? = nil
    @Published public var thumbTip: CGPoint? = nil
    @Published public var pinchDetected: Bool = false
    
    public var configuration: HandPoseConfiguration

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let sessionQueue = DispatchQueue(label: "HandPoseDetectorQueue")

    /*
     Creates a hand pose detector with the default configuration.
     */
    public override init() {
        self.configuration = HandPoseConfiguration()
        super.init()
        handPoseRequest.maximumHandCount = 1
        configureSession()
    }

    /*
     Creates a hand pose detector with a custom configuration.
     */
    public init(configuration: HandPoseConfiguration) {
        self.configuration = configuration
        super.init()
        handPoseRequest.maximumHandCount = 1
        configureSession()
    }

    private func configureSession() {
        captureSession.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("HandPoseDetector: Unable to access the front camera.")
            return
        }
        captureSession.beginConfiguration()
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        captureSession.commitConfiguration()
    }

    /*
     Starts the camera capture session.
     */
    public func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    /*
     Stops the camera capture session.
     */
    public func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    /*
     Returns the midpoint between indexTip and thumbTip (normalized), or nil if not available.
     */
    public var globalPointerNormalized: CGPoint? {
        guard let i = indexTip, let t = thumbTip else { return nil }
        return CGPoint(x: (i.x + t.x)/2, y: (i.y + t.y)/2)
    }

    private func process(sampleBuffer: CMSampleBuffer) async {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .upMirrored,
                                            options: [:])
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                await MainActor.run {
                    self.indexTip = nil
                    self.thumbTip = nil
                    self.pinchDetected = false
                }
                return
            }
            let points = try observation.recognizedPoints(.all)
            guard let idx = points[.indexTip],
                  let thb = points[.thumbTip],
                  let wst = points[.wrist],
                  idx.confidence > configuration.confidenceThreshold,
                  thb.confidence > configuration.confidenceThreshold
            else {
                await MainActor.run {
                    self.indexTip = nil
                    self.thumbTip = nil
                    self.pinchDetected = false
                }
                return
            }
            let handSize = hypot(idx.location.x - wst.location.x,
                                 idx.location.y - wst.location.y)
            if handSize < configuration.handSizeThreshold {
                await MainActor.run {
                    self.indexTip = nil
                    self.thumbTip = nil
                    self.pinchDetected = false
                }
                return
            }

            // Create Sendable (value type) copies of the locations
            let idxLocation = idx.location
            let thbLocation = thb.location
            
            await MainActor.run {
                self.indexTip = idxLocation
                self.thumbTip = thbLocation
            }

            // Calculate distance using value type copies
            let dx = idxLocation.x - thbLocation.x
            let dy = idxLocation.y - thbLocation.y
            let distance = sqrt(dx * dx + dy * dy)
            let threshold = configuration.pinchDistanceThreshold
            let isPinched = distance < threshold

            await MainActor.run {
                self.pinchDetected = isPinched
            }
        } catch {
            print("HandPoseDetector error: \(error)")
        }
    }
}

extension HandPoseDetector: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
     public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        Task {
            await process(sampleBuffer: sampleBuffer)
        }
    }
}
