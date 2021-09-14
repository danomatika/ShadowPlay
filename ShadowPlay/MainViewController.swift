//
//  MainViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

import UIKit
import AVKit

class MainViewController: UIViewController, PdReceiverDelegate,
                      AVCaptureVideoDataOutputSampleBufferDelegate {
	var camera: AVCaptureDevice?

	let session = AVCaptureSession()
	var brightness: Float = 0
	var rawBrightness: Float = 0
	var range: ClosedRange<Float> = 6...11 // default outdoor
	let rawRange: ClosedRange<Float> = -16...16

	let controller = PdAudioController()
	let patch = PdFile()
	let qlister = Qlister()

	weak var calibrateViewController: CalibrateViewController?

	@IBOutlet weak var controlsView: ControlsView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		controlsView.mainViewController = self
		qlister.delegate = controlsView
		//controlsView.isHidden = true

		let defaults = UserDefaults.standard
		range = defaults.float(forKey: "rangeMin")...defaults.float(forKey: "rangeMax")
		if defaults.bool(forKey: "keepAwake") {
			UIApplication.shared.isIdleTimerDisabled = true // keep screen awake
		}

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
				printDebug("audio configuration successful")
		}
		#if DEBUG
		controller?.print()
		#endif
		PdBase.setDelegate(self)
		PdBase.subscribe("#app")
		let _ = openScene("theremin")
		if !qlister.open() {
			print("could not open qlister.pd")
		}
		controller?.isActive = true
		PdBase.computeAudio(true)

		// set up capture session, ref: https://stackoverflow.com/q/9856114
		session.sessionPreset = .high
		session.automaticallyConfiguresCaptureDeviceForWideColor = false

		let _ = setupCamera(position: .back)

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
	}

	// show tutorial on first launch
	override func viewDidAppear(_ animated: Bool) {
		let defaults = UserDefaults.standard
		if defaults.bool(forKey: "showTutorialOnLaunch") {
			self.performSegue(withIdentifier: "ShowTutorial", sender: self)
			defaults.set(false, forKey: "showTutorialOnLaunch")
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowScenes",
		   let scene = segue.destination as? UINavigationController,
		   let controller = scene.viewControllers.first as? ScenesViewController  {
			controller.mainViewController = self
		}
		else if segue.identifier == "ShowCalibrate",
		   let scene = segue.destination as? UINavigationController,
		   let controller = scene.viewControllers.first as? CalibrateViewController  {
			controller.mainViewController = self
		}
		else if segue.identifier == "ShowInfo",
		   let scene = segue.destination as? UINavigationController,
		   let controller = scene.viewControllers.first as? InfoViewController  {
			controller.mainViewController = self
		}
		else if segue.identifier == "ShowSettings",
		   let scene = segue.destination as? UINavigationController,
		   let controller = scene.viewControllers.first as? SettingsViewController  {
			controller.mainViewController = self
		}
	}

	func openScene(_ name: String) -> Bool {
		let path = AppDelegate.patchDirectory().appendingPathComponent(name).path
		if patch.isValid() {
			muteScene()
			Thread.sleep(forTimeInterval: 0.025) // let fade finish before closing
			self.patch.close()
		}
		if !patch.open("main.pd", path: path) {
			printDebug("could not open \(name) main.pd")
			// FIXME: show alert after 2 seconds to avoid UI transitions/animations
			let alert = UIAlertController(title: NSLocalizedString("Alert.OpenScene.title", comment: "Audio Error"),
										  message: String(format: NSLocalizedString("Alert.OpenScene.message", comment: "Could not open scene %@"), name),
										  preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok"), style: .default, handler: nil))
			alert.modalPresentationStyle = .overCurrentContext
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
				self.present(alert, animated: true, completion: nil)
			}
			return false
		}
		return true
	}

	func muteScene() {
		PdBase.sendList([0, 25], toReceiver: "#volume") // fade out to avoid clicks
	}

	func unmuteScene() {
		PdBase.sendList([1, 25], toReceiver: "#volume") // fade in to avoid clicks
	}

	func setupCamera(position: AVCaptureDevice.Position) -> Bool {
		let wasRunning = session.isRunning
		session.stopRunning()
		for input in session.inputs {
			session.removeInput(input)
		}
		camera = AVCaptureDevice.default(.builtInWideAngleCamera,
		                                 for: .video,
		                                 position: position)
		guard let camera = camera else {
			print("could not create camera")
			return false
		}
		do {
			let input = try AVCaptureDeviceInput(device: camera)
			session.addInput(input)
		}
		catch {
			print("could create device input: \(error)")
			return false
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
			print("camera configuration failed: \(error)")
			return false
		}
		if wasRunning {
			session.startRunning()
		}
		return true
	}

	// MARK: Actions

	/// show more actions
	@IBAction func showMoreActions(_ sender: Any) {
		printDebug("ViewController: showMoreActions")
		let alert = UIAlertController()
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel action"), style: .cancel, handler: { action in
			alert.dismiss(animated: true, completion: nil)
		})
		let calibrateAction = UIAlertAction(title: NSLocalizedString("Calibrate", comment: "Calibrate action"), style: .default, handler: { action in
			printDebug("show calibrate")
			alert.dismiss(animated: true, completion: nil)
			self.performSegue(withIdentifier: "ShowCalibrate", sender: self)
		})
		let infoAction = UIAlertAction(title: NSLocalizedString("Info", comment: "Info action"), style: .default, handler: { action in
			printDebug("show info")
			alert.dismiss(animated: true, completion: nil)
			self.performSegue(withIdentifier: "ShowInfo", sender: self)
		})
		let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings action"), style: .default, handler: { action in
			printDebug("show settings")
			self.performSegue(withIdentifier: "ShowSettings", sender: self)
			alert.dismiss(animated: true, completion: nil)
		})
		if #available(iOS 13.0, *) {
			// add system icons on iOS 13+
			calibrateAction.setValue(UIImage.init(systemName: "lightbulb"), forKey: "image")
			infoAction.setValue(UIImage.init(systemName: "info.circle"), forKey: "image")
			settingsAction.setValue(UIImage.init(systemName: "gear"), forKey: "image")
		}
		alert.addAction(cancelAction)
		alert.addAction(calibrateAction)
		alert.addAction(infoAction)
		alert.addAction(settingsAction)
		alert.modalPresentationStyle = .popover
		present(alert, animated: true, completion: nil)
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
		   let rawBrightness = exif[String(kCGImagePropertyExifBrightnessValue)] as? NSNumber {
			let brightness = rawBrightness.floatValue.clamped(to: range).mapped(from: range, to: 0...1)
			//printDebug("brightness \(brightness) raw \(rawBrightness.floatValue)")
			DispatchQueue.main.async {
				self.rawBrightness = rawBrightness.floatValue
				self.brightness = self.brightness.mavg(brightness, windowSize: 2)
				if !self.qlister.isPlaying {
					PdBase.sendList([self.brightness, rawBrightness.floatValue], toReceiver: "#brightness")
					self.view.backgroundColor = UIColor(white: CGFloat(self.brightness), alpha: 1)
				}
				self.calibrateViewController?.update(raw: rawBrightness.floatValue)
			}
		}
	}

}

