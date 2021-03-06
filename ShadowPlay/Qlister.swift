//
//  Qlister.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

/// qlister.pd patch event delegate
protocol QlisterDelegate {
	func qlisterDidStartPlaying(_ qlister: Qlister)
	func qlisterDidStopPlaying(_ qlister: Qlister)
	func qlisterDidStartRecording(_ qlister: Qlister)
	func qlisterDidStopRecording(_ qlister: Qlister)
}

/// communication wrapper for qlister.pd patch
class Qlister {

	var isPlaying = false
	var isRecording = false
	var delegate: QlisterDelegate?

	private let patch = PdFile()

	func open() -> Bool {
		return patch.open("qlister.pd", path: AppDelegate.patchDirectory().path)
	}

	func close() {
		patch.close()
	}

	func togglePlay() {
		isPlaying = !isPlaying
		PdBase.sendList(["play", (isPlaying ? 1 : 0)], toReceiver: "#qlister")
		if delegate != nil {
			if isPlaying {
				delegate?.qlisterDidStartPlaying(self)
			}
			else {
				delegate?.qlisterDidStopPlaying(self)
			}
		}
	}

	func toggleRecord() {
		isRecording = !isRecording
		PdBase.sendList(["record", (isRecording ? 1 : 0)], toReceiver: "#qlister")
		if delegate != nil {
			if isRecording {
				delegate?.qlisterDidStartRecording(self)
			}
			else {
				delegate?.qlisterDidStopRecording(self)
			}
		}
	}

	func read(_ url: URL) {
		PdBase.sendList(["read", url.path], toReceiver: "#qlister")
	}

	func write(_ url: URL) {
		PdBase.sendList(["write", url.path], toReceiver: "#qlister")
	}

	func receiveMessage(_ message: String!, withArguments arguments: [Any]!) {
		if arguments.isEmpty {return}
		if let command = arguments[0] as? String {
			if command == "done" { // done playing
				if !isPlaying {return}
				isPlaying = false
				if delegate != nil {
					delegate?.qlisterDidStopPlaying(self)
				}
			}
		}
	}

}
