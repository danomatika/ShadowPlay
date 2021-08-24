//
//  ViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

import UIKit
import AVKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

	let session = AVCaptureSession()
	var brightness: Float = 0
	let range: ClosedRange<Float> = -4...4

	// set up capture session, ref: https://stackoverflow.com/q/9856114
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		session.sessionPreset = .high
		session.automaticallyConfiguresCaptureDeviceForWideColor = false

//		let previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
//		previewLayer.frame = view.bounds
//		view.layer.addSublayer(previewLayer)

		let position = AVCaptureDevice.Position.front
		guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
												   for: .video,
												   position: position) else {
			print("could not create camera")
			return
		}
		do {
			let input = try AVCaptureDeviceInput(device: camera)
			session.addInput(input)
		}
		catch {
			print("could create device input: \(error)")
			return
		}

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

		NotificationCenter.default.addObserver(forName: .AVCaptureSessionRuntimeError, object: self, queue: .main) { Notification in
			print("capture session runtime error")
		}

		session.startRunning()

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
			print("camera configuration failed: \(error)")
		}
	}

	// read brightness level from frame EXIF metadata,
	// ref: https://stackoverflow.com/a/22836060
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		let metadata = sampleBuffer.attachments.propagated
		if let exif = metadata[String(kCGImagePropertyExifDictionary)] as? [String: Any],
		   let brightness = exif[String(kCGImagePropertyExifBrightnessValue)] as? NSNumber {
			let normalized = brightness.floatValue.clamped(to: range).mapped(from: range, to: 0...1)
			//debugPrint("brightness \(brightness.floatValue) normalized \(normalized)")
			DispatchQueue.main.async {
				self.brightness = self.brightness.mavg(normalized, windowSize: 2)
				self.view.backgroundColor = UIColor(white: CGFloat(self.brightness), alpha: 1)
			}
		}
	}

}

