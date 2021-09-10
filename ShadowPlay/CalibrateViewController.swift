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
		let previewLayer = AVCaptureVideoPreviewLayer.init(session: mainViewController!.session)
		previewLayer.frame = view.bounds
		view.layer.addSublayer(previewLayer)
		for(subview) in view.subviews { // make sure subviews stay above
			view.bringSubviewToFront(subview)
		}

		rangeMin = mainViewController!.range.lowerBound
		rangeMax = mainViewController!.range.upperBound

		//labelContainer.isHidden = true

		calibrateButton.tintColor = .systemBackground
		calibrateButton.backgroundColor = .systemGreen
		calibrateButton.clipsToBounds = true
		calibrateButton.layer.cornerRadius = 5
	}

	override func viewWillAppear(_ animated: Bool) {
		mainViewController?.calibrateViewController = self
	}

	override func viewDidDisappear(_ animated: Bool) {
		mainViewController?.calibrateViewController = nil
	}

	func update() {
		if isCalibrating {
			if mainViewController!.rawBrightness < rangeMin {
				rangeMin = mainViewController!.rawBrightness
			}
			if mainViewController!.rawBrightness > rangeMax {
				rangeMax = mainViewController!.rawBrightness
			}
		}
		rangeBarView.min = rangeMin.mapped(from: mainViewController!.rawRange, to: 0...1)
		rangeBarView.max = rangeMax.mapped(from: mainViewController!.rawRange, to: 0...1)
		rangeBarView.value = mainViewController!.rawBrightness.mapped(from: mainViewController!.rawRange, to: 0...1)
		if !valuesHidden {
			rawBrightnessLabel.text = String(format: "%.2f", mainViewController!.rawBrightness)
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
		debugPrint("CalibrateViewController: start")
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
		debugPrint("CalibrateViewController: stop, range \(rangeMin) \(rangeMax)")
	}

	func cancelCalibration() {
		if !isCalibrating {return}
		isCalibrating = false
		calibrateButton.setTitle("Start", for: .normal)
		debugPrint("CalibrateViewController: cancel")
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		cancelCalibration()
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

}
