//
//  SettingsViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

	weak var mainViewController: MainViewController? // required!

	// display
	@IBOutlet weak var keepAwakeSwitch: UISwitch!
	@IBOutlet weak var showCalibrationValuesSwitch: UISwitch!
	@IBOutlet weak var showRecordControlsSwitch: UISwitch!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		tableView.tableFooterView = UIView(frame: .zero) // no empty rows

		let defaults = UserDefaults.standard
		keepAwakeSwitch.isOn = defaults.bool(forKey: "keepAwake")
		showCalibrationValuesSwitch.isOn = defaults.bool(forKey: "showCalibrationValues")
		showRecordControlsSwitch.isOn = defaults.bool(forKey: "showRecordControls")
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func keepAwakeChanged(_ sender: Any) {
		UserDefaults.standard.set(keepAwakeSwitch.isOn, forKey: "keepAwake")
		UIApplication.shared.isIdleTimerDisabled = keepAwakeSwitch.isOn
	}

	@IBAction func showCalibrationValuesChanged(_ sender: Any) {
		UserDefaults.standard.set(showCalibrationValuesSwitch.isOn, forKey: "showCalibrationValues")
	}

	@IBAction func showRecordControlsChanged(_ sender: Any) {
		UserDefaults.standard.set(showRecordControlsSwitch.isOn, forKey: "showRecordControls")
		mainViewController?.controlsView.recordControlsHidden = !showRecordControlsSwitch.isOn
	}

}
