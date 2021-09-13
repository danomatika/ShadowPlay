//
//  Util.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 8/25/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import Foundation

// MARK: Global Helpers

/// print that is ignored in release builds
func printDebug(_ msg: String) {
#if DEBUG
	print(msg)
#endif
}

// MARK: Class Extensions

extension URL {

	/// app Documents url getter
	static var documents: URL {
		return FileManager
			.default
			.urls(for: .documentDirectory, in: .userDomainMask)[0]
	}

}

extension StringProtocol {

	/// access individual characters via []: let char = string[2]
	subscript(offset: Int) -> Character {
		self[index(startIndex, offsetBy: offset)]
	}

}

extension String {

	/// returns a timestamp string for the current date & time
	static func timestamp() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
		return formatter.string(from: Date())
	}

}

extension Comparable {

	/// clamp to range: number.clamped(to: 0...10)
	func clamped(to limits: ClosedRange<Self>) -> Self {
		return min(max(self, limits.lowerBound), limits.upperBound)
	}

}

extension Float {

	/// map from range to new range linearly:
	/// number.mapped(from: 100...0, to: 0...1)
	func mapped(from: ClosedRange<Float>, to: ClosedRange<Float>) -> Float {
		if(abs(from.lowerBound - from.upperBound) < Float.ulpOfOne) {
			return to.lowerBound
		}
		return ((self - from.lowerBound) / (from.upperBound - from.lowerBound) *
					(to.upperBound - to.lowerBound) + to.lowerBound)
	}

	/// moving average with window size:
	/// number = number.mavg(newvalue, 5)
	func mavg(_ new: Float, windowSize: UInt) -> Float {
		return self * ((Float(windowSize) - 1.0) / Float(windowSize)) + new * (1.0 / Float(windowSize))
	}
}
