//
//  ScenesViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

/// sound scenes list selector
class ScenesViewController: UITableViewController {

	weak var mainViewController: MainViewController? // required!

	@IBOutlet weak var doneButton: UIBarButtonItem!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		tableView.tableFooterView = UIView(frame: .zero) // no empty rows
	}

	override func viewWillAppear(_ animated: Bool) {
		selectCurrentScene()
	}

	func selectCurrentScene() {
		if let scenes = mainViewController?.sceneList, scenes.count > 0 {
			let indexPath = IndexPath(row: scenes.currentIndex, section: 0)
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			printDebug("ScenesViewController: selected row \(indexPath.row)")
		}
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func reload(_ sender: Any) {
		let scenes = mainViewController!.sceneList
		scenes.reload()
		if let scene = scenes.current {
			let _ = mainViewController!.openScene(at: scene.url)
		}
		self.tableView.reloadData()
		selectCurrentScene()
	}

	// MARK: UITableViewController

	// table length
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mainViewController!.sceneList.count
	}

	// create cells from scene data
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "SceneCell", for: indexPath)
		if let scene = mainViewController!.sceneList.scene(at: indexPath.row) {
			cell.textLabel?.text = scene.meta.name
			cell.detailTextLabel?.text = scene.meta.author
		}
		return cell
	}

	/// open scene on selection
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let scene = mainViewController!.sceneList.goto(index: indexPath.row) {
			printDebug("ScenesViewController: selected \(scene.meta.name)")
			let _ = mainViewController!.openScene(at: scene.url)
		}
		dismiss(animated: true, completion: nil)
	}

	// no cells can be edited
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}

}
