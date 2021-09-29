//
//  Audio.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/29/21.
//

import UIKit

/// pure data audio instance
class Audio: NSObject, PdReceiverDelegate {

	let controller = PdAudioController()
	let scenePatch = PdFile() //< current scene main.pd
	let calibratePatch = PdFile() //< calibrate scene main.pd
	let qlister = Qlister() //< qlist recorder

	private let _fade = 25.0 //< audio fade in ms

	override init() {
		controller?.allowBluetooth = true
		controller?.allowBluetoothA2DP = true
		controller?.allowAirPlay = true
		controller?.mixWithOthers = true
	}

	deinit {
		stop()
		scenePatch.close()
		calibratePatch.close()
		qlister.close()
		controller?.isActive = false
	}

	/// setup pd audio instance
	func setup() {
		let sampleRate = Int32(AVAudioSession.sharedInstance().sampleRate)
		let status = controller?.configurePlayback(withSampleRate: sampleRate,
												  inputChannels: 0,
												  outputChannels: 2,
												  inputEnabled: false)
		switch(status) {
			case PdAudioError:
				print("Audio: could not configure")
			case PdAudioPropertyChanged:
				print("Audio: some properties were changed during configuration")
			default:
				printDebug("Audio: configuration successful")
		}
		#if DEBUG
		controller?.print()
		#endif
		PdBase.setDelegate(self)
		PdBase.subscribe("#app")
		if !calibratePatch.open("main.pd", path: Audio.calibratePath()) {
			print("Audio: could not open _calibrate main.pd")
		}
		if !qlister.open() {
			print("Audio: could not open qlister.pd")
		}
		controller?.isActive = true
	}

	// MARK: DSP

	/// start audio dsp
	func start() {
		PdBase.computeAudio(true)
	}

	/// stop audio dsp
	func stop() {
		PdBase.computeAudio(false)
	}

	// MARK: Scene

	/// open audio scene main.pd patch from containing folder url,
	/// ex. /path/to/scene url opens /path/to/scene/main.pd
	/// returns true on success or false on failure
	func openScene(url: URL) -> Bool {
		closeScene()
		if !scenePatch.open("main.pd", path: url.path) {
			print("Audio: could not open scene \(url.lastPathComponent) main.pd")
			return false
		}
		printDebug("Audio: opened scene \(url.lastPathComponent) main.pd")
		return true
	}

	/// close current scene patch, if open
	func closeScene() {
		if !scenePatch.isValid() {return}
		muteScene()
		Thread.sleep(forTimeInterval: _fade / 1000) // let fade finish before closing
		scenePatch.close()
	}

	/// mute current scene, fades out to avoid clicks
	func muteScene() {
		PdBase.sendList([0, _fade], toReceiver: "#volume")
	}

	/// unmute current scene, fades in to avoid clicks
	func unmuteScene() {
		PdBase.sendList([1, _fade], toReceiver: "#volume")
	}

	/// send brightness to current scene
	func sendScene(brightness: Float, rawBrightness: Float) {
		PdBase.sendList([brightness, rawBrightness], toReceiver: "#brightness")
	}

	// MARK: Calibrate

	/// get path to calibrate scene directory
	static func calibratePath() -> String {
		return AppDelegate.patchDirectory().appendingPathComponent("_calibrate").path
	}

	/// enable/disable calibrate scene
	func sendCalibrate(enable: Bool) {
		PdBase.sendList(["on", (enable ? 1: 0)], toReceiver: "#calibrate")
	}

	/// send brightness to calibration scene
	func sendCalibrate(brightness: Float) {
		PdBase.send(brightness, toReceiver: "#calibrate")
	}

	// MARK: PdReceiverDelegate

	func receivePrint(_ message: String!) {
		print("Audio: \(message ?? "")")
	}

	func receiveBang(fromSource source: String!) {
		print("Audio: received bang from source: \(String(describing: source))")
	}

	func receive(_ received: Float, fromSource source: String!) {
		print("Audio: received float: \(received) from source: \(String(describing: source))")
	}

	func receiveSymbol(_ symbol: String!, fromSource source: String!) {
		print("Audio: received symbol: \(String(describing: symbol)) from source: \(String(describing: source))")
	}

	func receiveList(_ list: [Any]!, fromSource source: String!) {
		print("Audio: received list: \(String(describing: list)) from source: \(String(describing: source))")
	}

	func receiveMessage(_ message: String!, withArguments arguments: [Any]!, fromSource source: String!) {
		print("Audio: received message: \(String(describing: message)) \(String(describing: arguments)) from source: \(String(describing: source))")
		if message == "qlister" {
			DispatchQueue.main.async {
				self.qlister.receiveMessage(message, withArguments: arguments)
			}
		}
	}

}
