//
//  AppDelegate.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		// load defaults
		if let path = Bundle.main.path(forResource: "UserDefaults", ofType: "plist") {
			let defaults = NSDictionary(contentsOfFile: path)
			UserDefaults.standard.register(defaults: defaults as! [String : Any])
		}

		return true
	}

//	// fade out to avoid clicks
//	func applicationWillResignActive(_ application: UIApplication) {
//		PdBase.sendList([0, 25], toReceiver: "#volume")
//	}
//
//	// fade out to avoid clicks
//	func applicationWillEnterForeground(_ application: UIApplication) {
//		PdBase.sendList([1, 25], toReceiver: "#volume")
//	}

	/// don't open urls
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		return false
	}

// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

	// MARK: Util

	/// returns full url to app resources pd directory
	static func patchDirectory() -> URL {
		return Bundle.main.bundleURL.appendingPathComponent("pd")
	}

}
