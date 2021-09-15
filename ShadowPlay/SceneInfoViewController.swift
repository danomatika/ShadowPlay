//
//  SceneInfoViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/15/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

/// show scene meta data
class SceneInfoViewController : UIViewController {

	var scene: Scene?

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var authorLabel: UILabel!
	@IBOutlet weak var descriptionTextView: UITextView!
	@IBOutlet weak var websiteTextView: UITextView!

	override func viewDidLoad() {
		if let scene = scene {
			nameLabel.text = scene.meta.name
			authorLabel.text = scene.meta.author
			descriptionTextView.text = scene.meta.description
			websiteTextView.text = scene.meta.url
		}
	}

}
