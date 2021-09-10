//
//  ScenesViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

struct Scene {
	let url: URL
	let meta: SceneMeta
}

struct SceneMeta : Codable {
	let name: String
	let author: String
	let description: String
}

/// sound scenes list
class ScenesViewController: UITableViewController {

	var scenes: [Scene] = []

	weak var mainViewController: MainViewController? // required!

	@IBOutlet weak var doneButton: UIBarButtonItem!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		tableView.tableFooterView = UIView(frame: .zero) // no empty rows

		// load scenes from patch directory
		let manager = FileManager.default
		var contents: [URL] = []
		do {
			try contents = manager.contentsOfDirectory(at: AppDelegate.patchDirectory(),
			                                           includingPropertiesForKeys: nil,
			                                           options: [.skipsHiddenFiles])
		}
		catch {
			print("ScenesViewController: could not read patch directory: \(error)")
		}
		for url in contents {
			if url.hasDirectoryPath {
				let name = url.lastPathComponent
				if name == "calibrate" {continue}
				let main = url.appendingPathComponent("main.pd")
				let info = url.appendingPathComponent("info.json")
				if manager.fileExists(atPath: main.path) && manager.fileExists(atPath: info.path) {
					do {
						let data = try Data(contentsOf: info)
						let meta = try JSONDecoder().decode(SceneMeta.self, from: data)
						let scene = Scene(url: url, meta: meta)
						scenes.append(scene)
					}
					catch {
						print("ScenesViewController: could not parse info.json: \(error)")
					}
				}
			}
		}
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	// MARK: UITableViewController

	// table length
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return scenes.count
	}

	// create cells from playlist files
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "SceneCell", for: indexPath)
		let scene = scenes[indexPath.row]
		cell.textLabel?.text = scene.meta.name
		cell.detailTextLabel?.text = scene.meta.author
		return cell
	}

	/// open scene on selection
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		debugPrint("ScenesViewController: selected \(scenes[indexPath.row])")
		let scene = scenes[indexPath.row]
		let _ = mainViewController!.openScene(scene.url.lastPathComponent)
		dismiss(animated: true, completion: nil)
	}

	// no cells can be edited
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}

}
