//
//  Camera.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/26/21.
//

import UIKit
import AVKit

extension UIWindow {

	/// get current interface orientation taking into account orientation lock
	static var interfaceOrientation: UIInterfaceOrientation {
		// assumes single window application
		return UIApplication.shared.windows
			.first?
			.windowScene?
			.interfaceOrientation ?? .unknown
	}
}

/// camera capture session delegate
protocol CameraDelegate {
	func camera(_ camera: Camera, didChange rawBrightness: Float)
}

/// camera capture session to read per-frame brightness level
class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {

	let session = AVCaptureSession()
	var camera: AVCaptureDevice?
	var rawBrightness: Float = 0 //< current EXIF brightness level
	static let rawRange: ClosedRange<Float> = -16...16 //< EXIF brightness range

	var delegate: CameraDelegate?

	private var _assetWriter: AVAssetWriter?
	private var _assetWriterInput: AVAssetWriterInput?
	fileprivate var _observer: Any? //< notification observer key

	// set up capture session and video output, ref: https://stackoverflow.com/q/9856114
	override init() {
		super.init()

		session.sessionPreset = .high
		session.automaticallyConfiguresCaptureDeviceForWideColor = false

		// frame output
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

		// error print
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
			DispatchQueue.global().async {
				self.session.startRunning()
			}
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
		DispatchQueue.global().async {
			self.session.startRunning()
		}
	}

	/// stop the capture session
	func stop() {
		session.stopRunning()
	}

	/// create preview layer for current camera input
	func createPreviewLayer() -> AVCaptureVideoPreviewLayer {
		return AVCaptureVideoPreviewLayer.init(session: session)
	}

	// MARK: Recording

	/// starting recording to file at url, extension should be "mp4"
	func startRecording(to url: URL) {

		// create asset writer
		let settings: [String : Any] = [
			AVVideoCodecKey : AVVideoCodecType.h264,
			AVVideoWidthKey : camera!.activeFormat.formatDescription.dimensions.width,
			AVVideoHeightKey : camera!.activeFormat.formatDescription.dimensions.height
		]
		_assetWriterInput = AVAssetWriterInput(mediaType: .video,
		                                       outputSettings: settings)
		_assetWriterInput?.expectsMediaDataInRealTime = true

		// captureOutput callback always returns buffer in landscape,
		// so set transform metadata to try to keep relative orientation
		// instead of rotating pixel buffer itself
		var angle: CGFloat = 0
		switch(UIWindow.interfaceOrientation) {
			case .portrait: angle = .pi/2
			case .landscapeLeft: angle = .pi
			case .portraitUpsideDown: angle = -.pi/2
			case .landscapeRight: angle = -.pi
			default: break;
		}
		_assetWriterInput?.transform = CGAffineTransform(rotationAngle: angle)

		// open url for writing
		do {
			_assetWriter = try AVAssetWriter(url: url, fileType: .mp4)
			if _assetWriter!.canAdd(_assetWriterInput!) {
				_assetWriter?.add(_assetWriterInput!)
			}
			else {
				print("Camera: could not add asset writer input")
				_assetWriter = nil
				_assetWriterInput = nil
				return
			}
		}
		catch let error {
			print("Camera: could not start recording: \(error)")
			_assetWriter = nil
			_assetWriterInput = nil
			return
		}
		printDebug("Camera: started recording to \(url)")
	}

	/// finish recording
	func stopRecording() {
		guard _assetWriter != nil else {return}
		_assetWriterInput?.markAsFinished()
		_assetWriter?.finishWriting(completionHandler: {
			printDebug("Camera: completed recording to \(self._assetWriter!.outputURL)")
			self._assetWriter = nil
			self._assetWriterInput = nil
		})
	}

	/// returns true if recording
	var isRecording: Bool {
		get {return _assetWriter != nil}
	}

	/// write frame to recording, if open
	private func _write(sampleBuffer: CMSampleBuffer) {
		guard _assetWriter != nil else {return}
		if _assetWriter?.status == .unknown {
			if _assetWriter!.startWriting() {
				let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
				_assetWriter?.startSession(atSourceTime: presentationTime)
			}
			else {
				print("Camera: error writing initial frame")
			}
		}
		if _assetWriter?.status == .writing {
			if _assetWriterInput!.isReadyForMoreMediaData {
				_assetWriterInput?.append(sampleBuffer)
			}
		}
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
		self._write(sampleBuffer: sampleBuffer)
	}

	// MARK: AVCaptureFileOutputRecordingDelegate

	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		printDebug("Camera: finished recording to \(outputFileURL), error: \(error?.localizedDescription ?? "none")")
	}

}
