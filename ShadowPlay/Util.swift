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
