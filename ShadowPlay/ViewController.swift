//
//  ViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

import UIKit
import AVKit

class ViewController: UIViewController, PdReceiverDelegate,
                      AVCaptureVideoDataOutputSampleBufferDelegate {

	let session = AVCaptureSession()
	var brightness: Float = 0
	let range: ClosedRange<Float> = -4...4

	let controller = PdAudioController()
	let patch = PdFile()
	let qlister = Qlister()

	@IBOutlet weak var controlsView: ControlsView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		controlsView.mainViewController = self
		qlister.delegate = controlsView

		// set up pure data
		controller?.allowBluetooth = true
		controller?.allowBluetoothA2DP = true
		controller?.allowAirPlay = true
		controller?.mixWithOthers = true
		let sampleRate = Int32(AVAudioSession.sharedInstance().sampleRate)
		let status = controller?.configurePlayback(withSampleRate: sampleRate,
		                                          inputChannels: 0,
		                                          outputChannels: 2,
		                                          inputEnabled: false)
		switch(status) {
			case PdAudioError:
				print("could not configure audio")
			case PdAudioPropertyChanged:
				print("some of the audio properties were changed during configuration")
			default:
				debugPrint("audio configuration successful")
		}
		#if DEBUG
		controller?.print()
		#endif
		PdBase.setDelegate(self)
		PdBase.subscribe("#app")
		if !patch.open("main.pd", path: AppDelegate.patchDirectoryPath()) {
			debugPrint("could not open main.pd")
		}
		if !qlister.open() {
			debugPrint("could not open qlister.pd")
		}
		controller?.isActive = true
		PdBase.computeAudio(true)

		// set up capture session, ref: https://stackoverflow.com/q/9856114
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

		NotificationCenter.default.addObserver(forName: .AVCaptureSessionRuntimeError,
		                                       object: self, queue: .main) { Notification in
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

	// MARK: PdReceiverDelegate

	func receivePrint(_ message: String!) {
		print(message ?? "")
	}

	func receiveBang(fromSource source: String!) {
		receivePrint("received bangfrom source: \(String(describing: source))")
	}

	func receive(_ received: Float, fromSource source: String!) {
		receivePrint("received float: \(received) from source: \(String(describing: source))")
	}

	func receiveSymbol(_ symbol: String!, fromSource source: String!) {
		receivePrint("received symbol: \(String(describing: symbol)) from source: \(String(describing: source))")
	}

	func receiveList(_ list: [Any]!, fromSource source: String!) {
		receivePrint("received list: \(String(describing: list)) from source: \(String(describing: source))")
	}

	func receiveMessage(_ message: String!, withArguments arguments: [Any]!, fromSource source: String!) {
		receivePrint("received message: \(String(describing: message)) \(String(describing: arguments)) from source: \(String(describing: source))")
		if message == "qlister" {
			DispatchQueue.main.async {
				self.qlister.receiveMessage(message, withArguments: arguments)
			}
		}
	}

	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

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
				if !self.qlister.isPlaying {
					PdBase.send(self.brightness, toReceiver: "#brightness")
				}
				self.view.backgroundColor = UIColor(white: CGFloat(self.brightness), alpha: 1)
			}
		}
	}

}

