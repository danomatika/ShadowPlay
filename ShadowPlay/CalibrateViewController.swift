//
//  CalibrateViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class CalibrateViewController: UIViewController {
	var isCalibrating = false
	var rangeMin: Float = 0
	var rangeMax: Float = 0
	var valuesHidden: Bool {
		get {
			return labelContainer.isHidden
		}
		set {
			labelContainer.isHidden = newValue
		}
	}
	let patch = PdFile()

	weak var mainViewController: MainViewController? // required!

	@IBOutlet weak var rangeBarView: RangeBarView!

	@IBOutlet weak var labelContainer: UIStackView!
	@IBOutlet weak var rawBrightnessLabel: UILabel!
	@IBOutlet weak var rangeMinLabel: UILabel!
	@IBOutlet weak var rangeMaxLabel: UILabel!

	@IBOutlet weak var calibrateButton: UIButton!

	override func viewDidLoad() {
		view.backgroundColor = .black

		// camera preview
		let previewLayer = AVCaptureVideoPreviewLayer.init(session: mainViewController!.session)
		previewLayer.frame = view.bounds
		view.layer.addSublayer(previewLayer)
		for(subview) in view.subviews { // make sure subviews stay above
			view.bringSubviewToFront(subview)
		}

		rangeMin = mainViewController!.range.lowerBound
		rangeMax = mainViewController!.range.upperBound

		valuesHidden = !UserDefaults.standard.bool(forKey: "showCalibrationValues")

		calibrateButton.tintColor = .systemBackground
		calibrateButton.backgroundColor = .systemGreen
		calibrateButton.clipsToBounds = true
		calibrateButton.layer.cornerRadius = 5
	}

	override func viewWillAppear(_ animated: Bool) {
		mainViewController?.muteScene()
		mainViewController?.calibrateViewController = self
		let path = AppDelegate.patchDirectory().appendingPathComponent("_calibrate").path
		patch.open("main.pd", path: path)
		PdBase.sendList(["on", 1], toReceiver: "#calibrate")
	}

	override func viewDidDisappear(_ animated: Bool) {
		cancelCalibration()
		PdBase.sendList(["on", 0], toReceiver: "#calibrate")
		Thread.sleep(forTimeInterval: 0.025) // let fade finish before closing
		self.patch.close()
		mainViewController?.calibrateViewController = nil
		mainViewController?.unmuteScene()
	}

	func update(raw: Float) {
		if isCalibrating {
			if raw < rangeMin {
				rangeMin = raw
			}
			if raw > rangeMax {
				rangeMax = raw
			}
		}

		let range = rangeMin...rangeMax
		let brightness = raw.clamped(to: range).mapped(from: range, to: 0...1)
		PdBase.send(brightness, toReceiver: "#calibrate")
		//printDebug("calibrate min \(rangeMin) max \(rangeMax) brightness \(brightness)")

		rangeBarView.min = rangeMin.mapped(from: mainViewController!.rawRange, to: 0...1)
		rangeBarView.max = rangeMax.mapped(from: mainViewController!.rawRange, to: 0...1)
		rangeBarView.value = raw.mapped(from: mainViewController!.rawRange, to: 0...1)
		if !valuesHidden {
			rawBrightnessLabel.text = String(format: "%.2f", raw)
			rangeMinLabel.text = String(format: "%.2f", rangeMin)
			rangeMaxLabel.text = String(format: "%.2f", rangeMax)
		}
	}

	func startCalibration() {
		if isCalibrating {return}
		rangeMin = mainViewController!.rawRange.upperBound
		rangeMax = mainViewController!.rawRange.lowerBound
		isCalibrating = true
		calibrateButton.setTitle("Stop", for: .normal)
		calibrateButton.backgroundColor = .systemRed
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
															target: self,
															action: #selector(done))
		navigationItem.rightBarButtonItem?.style = .done
		printDebug("CalibrateViewController: start")
	}

	func stopCalibration() {
		if !isCalibrating {return}
		isCalibrating = false
		mainViewController!.range = rangeMin...rangeMax
		UserDefaults.standard.setValue(rangeMin, forKey: "rangeMin")
		UserDefaults.standard.setValue(rangeMax, forKey: "rangeMax")
		calibrateButton.setTitle("Start", for: .normal)
		calibrateButton.backgroundColor = .systemGreen
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
															target: self,
															action: #selector(done))
		navigationItem.rightBarButtonItem?.style = .done
		printDebug("CalibrateViewController: stop, range \(rangeMin) \(rangeMax)")
	}

	func cancelCalibration() {
		if !isCalibrating {return}
		isCalibrating = false
		calibrateButton.setTitle("Start", for: .normal)
		printDebug("CalibrateViewController: cancel")
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func toggleCalibration(_ sender: Any) {
		if isCalibrating {
			stopCalibration()
		}
		else {
			startCalibration()
		}
	}

	@IBAction func swapCamera(_ sender: Any) {
		if(mainViewController!.camera?.position == .front) {
			let _ = mainViewController!.setupCamera(position: .back)
		}
		else {
			let _ = mainViewController!.setupCamera(position: .front)
		}
	}

}
