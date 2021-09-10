//
//  ScenesViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

/// sound scenes list
class ScenesViewController: UITableViewController {

	let data: [String] = ["theremin", "sequence"]

	weak var mainViewController: MainViewController? // required!

	@IBOutlet weak var doneButton: UIBarButtonItem!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		tableView.tableFooterView = UIView(frame: .zero) // no empty rows
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	// MARK: UITableViewController

	// table length
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}

	// create cells from playlist files
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "SceneCell", for: indexPath)
		cell.textLabel?.text = data[indexPath.row]
		return cell
	}

	/// open scene on selection
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		debugPrint("ScenesViewController: selected \(data[indexPath.row])")
		let _ = mainViewController!.openScene(data[indexPath.row])
		dismiss(animated: true, completion: nil)
	}

	// no cells can be edited
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}

}
