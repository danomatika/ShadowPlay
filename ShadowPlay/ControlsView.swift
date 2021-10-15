//
//  ControlsView.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

import UIKit

class ControlsView : UIView, QlisterDelegate {

	var recordControlsHidden: Bool {
		get {
			return recordButton.isHidden
		}
		set {
			playPauseButton.isHidden = newValue
			recordButton.isHidden = newValue
		}
	}

	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var recordButton: UIButton!

	weak var mainViewController: MainViewController?

	private var _timestamp: String = "" //< current timestamp when recording

	override func awakeFromNib() {
		let defaults = UserDefaults.standard
		recordControlsHidden = !defaults.bool(forKey: "showRecordControls")
		playPauseButton.isEnabled = false // not enabled until something is recorded
	}

	// MARK: Actions

	@IBAction func playPause(_ sender: Any) {
		printDebug("ControlsView: playPause")
		mainViewController?.audio.qlister.togglePlay()
	}

	@IBAction func record(_ sender: Any) {
		printDebug("ControlsView: record")
		mainViewController?.audio.qlister.toggleRecord()
		if mainViewController?.audio.qlister.isRecording ?? false {
			// start recording
			_timestamp = String.timestamp()
			let file = _timestamp + ".mp4"
			let url = URL.documents.appendingPathComponent(file)
			mainViewController?.camera.startRecording(to: url)
		}
		else {
			// stop recording
			mainViewController?.camera.stopRecording()
			let files = [_timestamp + ".txt", _timestamp + ".mp4"]
			printDebug("ControlsView: saving \(files.joined(separator: " "))")
			let url = URL.documents.appendingPathComponent(files[0])
			mainViewController?.audio.qlister.write(url)
			let title = NSLocalizedString("Alert.RecordSave.title", comment: "Record Finished")
			let message = NSLocalizedString("Alert.RecordSave.message", comment: "Saved")
			let alert = UIAlertController(
				title: title,
				message: message + "\n" + files.joined(separator: "\n"),
				preferredStyle: .alert
			)
			mainViewController?.show(alert, sender: nil)
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
				alert.dismiss(animated: true, completion: nil)
			}
		}
	}

	// MARK: QlisterDelegate

	func qlisterDidStartPlaying(_ qlister: Qlister) {
		printDebug("ControlsView: start playing")
		playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
		recordButton.isEnabled = false
	}

	func qlisterDidStopPlaying(_ qlister: Qlister) {
		printDebug("ControlsView: stop playing")
		playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
		recordButton.isEnabled = true
	}

	func qlisterDidStartRecording(_ qlister: Qlister) {
		printDebug("ControlsView: start recording")
		recordButton.tintColor = .systemRed
		playPauseButton.isEnabled = false
	}

	func qlisterDidStopRecording(_ qlister: Qlister) {
		printDebug("ControlsView: stop recording")
		recordButton.tintColor = self.tintColor
		playPauseButton.isEnabled = true
	}

}
