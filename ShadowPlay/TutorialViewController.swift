//
//  TutorialViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

/// usage tutorial presented as a series of "Tutorial#" pages in the storyboard
class TutorialViewController: UIPageViewController,
							  UIPageViewControllerDelegate,
							  UIPageViewControllerDataSource {

	var pages: [UIViewController] = []
	var index: Int = 0

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		self.delegate = self
		self.dataSource = self

		for(i) in 1...2 {
			let page: UIViewController! = storyboard?.instantiateViewController(identifier: String(format: "Tutorial%d", i))
			pages.append(page)
		}

		setViewControllers([pages[0]], direction: .forward, animated: true, completion: nil)
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	// MARK: UIPageViewControllerDelegate

	func presentationIndex(for pageViewController: UIPageViewController) -> Int {
		return pages.firstIndex(of: viewControllers![0])!
	}

	func presentationCount(for pageViewController: UIPageViewController) -> Int {
		return pages.count
	}

	// MARK: UIPageViewControllerDataSource

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		let currentIndex = pages.firstIndex(of: viewController)!
		let previousIndex = abs((currentIndex - 1) % pages.count)
		return pages[previousIndex]
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		let currentIndex = pages.firstIndex(of: viewController)!
		let nextIndex = abs((currentIndex + 1) % pages.count)
		return pages[nextIndex]
	}

}
