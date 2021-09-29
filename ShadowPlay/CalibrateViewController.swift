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
		let previewLayer = mainViewController!.camera.createPreviewLayer()
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
		mainViewController?.audio.muteScene()
		mainViewController?.calibrateViewController = self
		mainViewController?.audio.sendCalibrate(enable: true)
	}

	override func viewDidDisappear(_ animated: Bool) {
		cancelCalibration()
		mainViewController?.audio.sendCalibrate(enable: false)
		mainViewController?.calibrateViewController = nil
		mainViewController?.audio.unmuteScene()
	}

	func update(rawBrightness: Float) {
		if isCalibrating {
			if rawBrightness < rangeMin {
				rangeMin = rawBrightness
			}
			if rawBrightness > rangeMax {
				rangeMax = rawBrightness
			}
		}

		let range = rangeMin...rangeMax
		let brightness = rawBrightness.clamped(to: range).mapped(from: range, to: 0...1)
		mainViewController?.audio.sendCalibrate(brightness: brightness)
		//printDebug("calibrate min \(rangeMin) max \(rangeMax) brightness \(brightness)")

		rangeBarView.min = rangeMin.mapped(from: Camera.rawRange, to: 0...1)
		rangeBarView.max = rangeMax.mapped(from: Camera.rawRange, to: 0...1)
		rangeBarView.value = rawBrightness.mapped(from: Camera.rawRange, to: 0...1)
		if !valuesHidden {
			rawBrightnessLabel.text = String(format: "%.2f", rawBrightness)
			rangeMinLabel.text = String(format: "%.2f", rangeMin)
			rangeMaxLabel.text = String(format: "%.2f", rangeMax)
		}
	}

	func startCalibration() {
		if isCalibrating {return}
		rangeMin = Camera.rawRange.upperBound
		rangeMax = Camera.rawRange.lowerBound
		isCalibrating = true
		calibrateButton.setTitle(NSLocalizedString("Stop", comment: "Start button"), for: .normal)
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
		calibrateButton.setTitle(NSLocalizedString("Start", comment: "Start button"), for: .normal)
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
		calibrateButton.setTitle(NSLocalizedString("Start", comment: "Start button"), for: .normal)
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
		mainViewController!.camera.swap()
	}

}
