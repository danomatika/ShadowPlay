//
//  MainViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

import UIKit

class MainViewController: UIViewController, PdReceiverDelegate, CameraDelegate {

	let camera = Camera() //< camera brightness input
	var brightness: Float = 0 // normalized 0 - 1
	var range: ClosedRange<Float> = 6...11 // default outdoor

	let sceneList = SceneList()

	let controller = PdAudioController()
	let patch = PdFile() //< current scene main.pd
	let qlister = Qlister()

	weak var calibrateViewController: CalibrateViewController?

	@IBOutlet weak var controlsView: ControlsView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		controlsView.mainViewController = self
		qlister.delegate = controlsView

		let defaults = UserDefaults.standard
		range = defaults.float(forKey: "rangeMin")...defaults.float(forKey: "rangeMax")
		if defaults.bool(forKey: "keepAwake") {
			UIApplication.shared.isIdleTimerDisabled = true // keep screen awake
		}

		// load scene data
		sceneList.load()

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
		if let scene = sceneList.goto(name: "Theremin") {
			let _ = openScene(at: scene.url)
		}
		if !qlister.open() {
			print("could not open qlister.pd")
		}
		controller?.isActive = true
		PdBase.computeAudio(true)

		// camera
		camera.delegate = self
		camera.start()
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

	func openScene(at url: URL) -> Bool {
		if patch.isValid() {
			muteScene()
			Thread.sleep(forTimeInterval: 0.025) // let fade finish before closing
			self.patch.close()
		}
		if !patch.open("main.pd", path: url.path) {
			printDebug("could not open \(url.lastPathComponent) main.pd")
			// FIXME: show alert after 2 seconds to avoid UI transitions/animations
			let alert = UIAlertController(title: NSLocalizedString("Alert.OpenScene.title", comment: "Audio Error"),
										  message: String(format: NSLocalizedString("Alert.OpenScene.message", comment: "Could not open scene %@"), url.lastPathComponent),
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

	// MARK: CameraDelegate

	func cameraDidChange(rawBrightness: Float) {
		let brightness = rawBrightness.clamped(to: range).mapped(from: range, to: 0...1)
		//printDebug("brightness \(brightness) raw \(rawBrightness)")
		DispatchQueue.main.async {
			self.brightness = self.brightness.mavg(brightness, windowSize: 2)
				if !self.qlister.isPlaying {
					PdBase.sendList([self.brightness, rawBrightness], toReceiver: "#brightness")
					self.view.backgroundColor = UIColor(white: CGFloat(self.brightness), alpha: 1)
				}
				self.calibrateViewController?.update(rawBrightness: rawBrightness)
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

}
