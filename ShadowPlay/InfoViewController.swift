//
//  InfoViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

/// basic app info txt file loaded into a text view
class InfoViewController: UIViewController {

	@IBOutlet weak var textView: UITextView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		// load txt into text view
		if let path = Bundle.main.url(forResource: "AppInfo", withExtension: "txt") {
			do {
				let text: String = try String(contentsOf: path, encoding: .utf8)
				self.textView.text = text
			}
			catch let error {
				print("InfoViewController: could not open AppInfo.txt: \(error)")
			}
		}
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

}

