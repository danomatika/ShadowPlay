//
//  TutorialViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/6/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

extension UIViewController {

	/// textviews don't seem to load their own localizations automatically, so
	/// force it by using the text string's storyboard ID in the textview's
	/// restoraztion ID in IB the calling NSLocalizedString
	/// from https://stackoverflow.com/a/34452658
	func localizeUITextViewsFromStoryboard(storyboardName: String) {
		for view in self.view.subviews {
			if let textView = view as? UITextView,
				let restorationIdentifier = textView.restorationIdentifier {
				let key = "\(restorationIdentifier).text"
				let localizedText = NSLocalizedString(key, tableName: storyboardName, comment: "")
				if localizedText != key {
					textView.text = localizedText
				}

			}
		}
	}

}

/// usage tutorial presented as a series of 0-indexed "Tutorial#" pages in the storyboard
class TutorialViewController: UIPageViewController,
							  UIPageViewControllerDelegate,
							  UIPageViewControllerDataSource {

	var pages: [UIViewController] = []
	var index: Int = 0

	static let numPages = 8

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		self.delegate = self
		self.dataSource = self

		for(i) in 0..<TutorialViewController.numPages {
			let id =  String(format: "Tutorial%d", i)
			let page: UIViewController! = storyboard?.instantiateViewController(identifier: id)
			pages.append(page)
		}

		pages[0].localizeUITextViewsFromStoryboard(storyboardName: "Main") // localize!
		setViewControllers([pages[0]], direction: .forward, animated: true, completion: nil)
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	// MARK: UIPageViewControllerDelegate

	func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		navigationItem.title = pendingViewControllers[0].title
		pendingViewControllers[0].localizeUITextViewsFromStoryboard(storyboardName: "Main")
	}

	func presentationIndex(for pageViewController: UIPageViewController) -> Int {
		return pages.firstIndex(of: viewControllers![0])!
	}

	func presentationCount(for pageViewController: UIPageViewController) -> Int {
		return pages.count
	}

	// MARK: UIPageViewControllerDataSource

	/// go to previous page, stop at beginning
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		let index = pages.firstIndex(of: viewController)!
		if index == 0 {return nil}
		let newIndex = abs((index - 1) % pages.count)
		return pages[newIndex]
	}

	/// go to next page, stop at end
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		let index = pages.firstIndex(of: viewController)!
		if index == pages.count - 1 {return nil}
		let newIndex = abs((index + 1) % pages.count)
		return pages[newIndex]
	}

}
