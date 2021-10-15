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
	@IBOutlet weak var recordVideoSwitch: UISwitch!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		tableView.tableFooterView = UIView(frame: .zero) // no empty rows

		let defaults = UserDefaults.standard
		keepAwakeSwitch.isOn = defaults.bool(forKey: "keepAwake")
		showCalibrationValuesSwitch.isOn = defaults.bool(forKey: "showCalibrationValues")
		showRecordControlsSwitch.isOn = defaults.bool(forKey: "showRecordControls")
		recordVideoSwitch.isOn = defaults.bool(forKey: "recordVideo")

		recordVideoSwitch.isEnabled = showRecordControlsSwitch.isOn
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
		recordVideoSwitch.isEnabled = showRecordControlsSwitch.isOn
	}

	@IBAction func recordVideoChanged(_ sender: Any) {
		UserDefaults.standard.set(recordVideoSwitch.isOn, forKey: "recordVideo")
	}

	@IBAction func deleteAll() {
		let title = NSLocalizedString("Alert.RecordDelete.title", comment: "Delete Recordings")
		let message = NSLocalizedString("Alert.RecordDelete.message", comment: "Delete all recordings in Documents?")
		let alert = UIAlertController(
			title: title,
			message: message,
			preferredStyle: .alert
		)
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
		alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { action in
			self._deleteAllRecordings()
		}))
		mainViewController?.show(alert, sender: nil)
	}

	// MARK: Private

	/// delete all recordings in the Documents directory
	private func _deleteAllRecordings() {
		let manager = FileManager.default
		var contents: [URL] = []
		var count: UInt = 0
		do {
			try contents = manager.contentsOfDirectory(at: URL.documents,
													   includingPropertiesForKeys: nil,
													   options: [.skipsHiddenFiles])
		}
		catch {
			print("Settings: could not read Documents directory: \(error)")
		}
		for url in contents {
			if url.isFileURL {
				if url.pathExtension == "txt" || url.pathExtension == "mp4" {
					do {
						try manager.removeItem(at: url)
						count += 1
						printDebug("Settings: removed \(url.lastPathComponent)")
					}
					catch {
						print("Settings: unable to remove \(url.lastPathComponent)")
					}
				}
			}
		}
		printDebug("Settings: removed \(count) recordings from Documents directory")
	}

}
