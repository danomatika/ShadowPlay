//
//  ScenesViewController.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/15/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

struct Scene {
	let url: URL           //< dir url, ie. url + main.pd, url + info.json, etc
	let meta: SceneMeta    //< metadata
}

struct SceneMeta : Codable {
	let name: String        //< scene name
	let author: String      //< author's name
	let description: String //< scene description, usage, etc
	let url: String         //< author website
}

/// scene list data source
class SceneList {

	var scenes: [Scene] = []   //< loaded scene data
	var current: Scene?        //< current scene
	var currentIndex: Int = -1 //< current scene index
	var count: Int {           //< loaded scenes count
		get {scenes.count}
	}

	func load() {
		let _ = loadDirectory(at: AppDelegate.patchDirectory())
		let _ = loadDirectory(at: URL.documents)
	}

	// load scenes from a directory url
	func loadDirectory(at: URL) -> UInt {
		let manager = FileManager.default
		var contents: [URL] = []
		var count: UInt = 0
		do {
			try contents = manager.contentsOfDirectory(at: at,
													   includingPropertiesForKeys: nil,
													   options: [.skipsHiddenFiles])
		}
		catch {
			print("SceneList: could not read directory \(at.lastPathComponent): \(error)")
		}
		for url in contents {
			if url.hasDirectoryPath {
				let name = url.lastPathComponent
				if name.count == 0 || name[0] == "_" {continue} // skip dirs starting with _
				let main = url.appendingPathComponent("main.pd")
				let info = url.appendingPathComponent("info.json")
				if manager.fileExists(atPath: main.path) && manager.fileExists(atPath: info.path) {
					do {
						let data = try Data(contentsOf: info)
						let meta = try JSONDecoder().decode(SceneMeta.self, from: data)
						let scene = Scene(url: url, meta: meta)
						scenes.append(scene)
						count += 1
					}
					catch {
						print("SceneList: could not parse \(name) info.json: \(error)")
					}
				}
			}
		}
		printDebug("ScenesList: loaded \(count) scenes from \(at.lastPathComponent)")
		return count
	}

	/// clear scenes
	func clear() {
		scenes = []
		current = nil
		currentIndex = -1
	}

	// reload scenes, try keep current selection
	func reload() {
		let url: URL? = current?.url ?? nil
		clear()
		load()
		if let url = url {
			var index = 0
			for scene in scenes {
				if scene.url == url {
					currentIndex = index
					current = scenes[index]
					return
				}
				index += 1
			}
		}
	}

	/// change to current scene at index
	func goto(index: Int) -> Scene? {
		if(index >= scenes.count) {return nil}
		currentIndex = index
		current = scenes[currentIndex]
		return current
	}

	/// change to current scene by name
	func goto(name: String) -> Scene? {
		var index = 0
		for scene in scenes {
			if scene.meta.name == name {
				currentIndex = index
				current = scene
				return current
			}
			index += 1
		}
		return nil
	}

	/// return scene at index
	func scene(at: Int) -> Scene? {
		if(at >= scenes.count) {return nil}
		return scenes[at]
	}

}
