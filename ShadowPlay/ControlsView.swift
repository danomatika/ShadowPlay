//
//  ControlsView.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

import UIKit

class ControlsView : UIView, QlisterDelegate {

	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var saveButton: UIButton!

	weak var mainViewController: ViewController?

	@IBAction func playPause(_ sender: Any) {
		printDebug("ControlsView: playPause")
		mainViewController?.qlister.togglePlay()
	}

	@IBAction func record(_ sender: Any) {
		printDebug("ControlsView: record")
		mainViewController?.qlister.toggleRecord()
	}

	@IBAction func save(_sender: Any) {
		let file = String.timestamp() + ".txt"
		printDebug("ControlsView: saving \(file)")
		let url = URL.documents.appendingPathComponent(file)
		mainViewController?.qlister.write(url)
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
		saveButton.isEnabled = false
	}

	func qlisterDidStopRecording(_ qlister: Qlister) {
		printDebug("ControlsView: stop recording")
		recordButton.tintColor = self.tintColor
		playPauseButton.isEnabled = true
		saveButton.isEnabled = true
	}

}
