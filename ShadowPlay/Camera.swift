//
//  Camera.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/26/21.
//

import UIKit
import AVKit

/// camera capture session delegate
protocol CameraDelegate {
	func camera(_ camera: Camera, didChange rawBrightness: Float)
}

/// camera capture session to read per-frame brightness level
class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

	let session = AVCaptureSession()
	var camera: AVCaptureDevice?
	var rawBrightness: Float = 0 //< current EXIF brightness level
	static let rawRange: ClosedRange<Float> = -16...16 //< EXIF brightness range

	var delegate: CameraDelegate?

	fileprivate var _observer: Any? //< notification observer key

	// set up capture session and video output, ref: https://stackoverflow.com/q/9856114
	override init() {
		super.init()

		session.sessionPreset = .high
		session.automaticallyConfiguresCaptureDeviceForWideColor = false

		let videoDataOutput = AVCaptureVideoDataOutput()
		videoDataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA]
		videoDataOutput.alwaysDiscardsLateVideoFrames = true
		let queue = DispatchQueue.init(label: "cameraQueue",
									   qos: .userInteractive,
									   attributes: .concurrent,
									   autoreleaseFrequency: .inherit,
									   target: .none)
		videoDataOutput.setSampleBufferDelegate(self, queue: queue)
		session.addOutput(videoDataOutput)

		_observer = NotificationCenter.default.addObserver(forName: .AVCaptureSessionRuntimeError,
											   object: self, queue: .main) { notification in
			let error: NSError = notification.userInfo?[AVCaptureSessionErrorKey] as! NSError
			print("Camera: capture session runtime error: \(error.localizedDescription)")
		}
	}

	deinit {
		if _observer != nil {
			NotificationCenter.default.removeObserver(_observer!)
		}
	}

	/// setup camera input, either from .front or .back position
	func setup(position: AVCaptureDevice.Position) {
		let wasRunning = session.isRunning
		session.stopRunning()
		for input in session.inputs {
			session.removeInput(input)
		}
		camera = AVCaptureDevice.default(.builtInWideAngleCamera,
										 for: .video,
										 position: position)
		guard let camera = camera else {
			print("Camera: could not create capture device")
			return
		}
		do {
			let input = try AVCaptureDeviceInput(device: camera)
			session.addInput(input)
		}
		catch {
			print("Camera: could not create device input: \(error)")
			return
		}
		do {
			try camera.lockForConfiguration()
			camera.whiteBalanceMode = .continuousAutoWhiteBalance
			camera.exposureMode = .continuousAutoExposure
			if camera.isFocusModeSupported(.continuousAutoFocus) {
				camera.focusMode = .continuousAutoFocus
			}
			camera.unlockForConfiguration()
		}
		catch {
			print("Camera: configuration failed: \(error)")
			return
		}
		if wasRunning {
			session.startRunning()
		}
		return
	}

	/// swap the camera position
	func swap() {
		if(camera?.position == .front) {
			setup(position: .back)
		}
		else {
			setup(position: .front)
		}
	}

	/// start the capture session
	func start() {
		session.startRunning()
	}

	/// stop the capture session
	func stop() {
		session.stopRunning()
	}

	/// create preview layer for current camera input
	func createPreviewLayer() -> AVCaptureVideoPreviewLayer {
		return AVCaptureVideoPreviewLayer.init(session: session)
	}

	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

	/// read brightness level from frame EXIF metadata,
	/// ref: https://stackoverflow.com/a/22836060
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		let metadata = sampleBuffer.attachments.propagated
		if let exif = metadata[String(kCGImagePropertyExifDictionary)] as? [String: Any],
		   let rawBrightness = exif[String(kCGImagePropertyExifBrightnessValue)] as? NSNumber {
			self.rawBrightness = rawBrightness.floatValue
			self.delegate?.camera(self, didChange: self.rawBrightness)
		}
	}

}
