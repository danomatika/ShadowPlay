//
//  RangeBarView.swift
//  ShadowPlay
//
//  Created by Dan Wilcox on 9/9/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

/// horizontal display for a normalized range min, max, and current value
class RangeBarView : UIView {

	var value: Float = 0 {
		didSet {
			value = value.clamped(to: 0...1)
			setNeedsDisplay()
		}
	}
	var min: Float = 0 {
		didSet {
			min = min.clamped(to: 0...1)
			setNeedsDisplay()
		}
	}
	var max: Float = 0 {
		didSet {
			max = max.clamped(to: 0...1)
			setNeedsDisplay()
		}
	}
	var valueColor = UIColor.systemPurple
	var rangeColor = UIColor.systemTeal
	var gradient: CGGradient?
	let inset: CGFloat = 4
	let valueWidth = 6

	override func awakeFromNib() {

		// clear backgroud used in Interface Builder
		backgroundColor = UIColor.clear

		// horz gradient
		gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
							  colors: [UIColor.black.cgColor, UIColor.white.cgColor] as CFArray,
							  locations: [0, 1])

		// rounded corners
		clipsToBounds = true
		layer.cornerRadius = 5
	}

	override func draw(_ rect: CGRect) {
		guard let context = UIGraphicsGetCurrentContext() else {return}
		let y = rect.origin.y + inset
		let w = rect.size.width - (inset * 2)
		let h = rect.size.height - (inset * 2)

		// background
		context.drawLinearGradient(gradient!,
								   start: CGPoint(x: 0, y: 0),
								   end: CGPoint(x: rect.size.width, y: 0),
								   options: [])

		// range
		let rx = w * CGFloat(min)
		let rw = w * CGFloat(max)
		let rbar = CGRect(x: rx + inset, y: y, width: rw - rx, height: h)
		context.setFillColor(rangeColor.cgColor)
		context.fill(rbar)

		// value
		let vx = (w * CGFloat(value)) - CGFloat(valueWidth) / 2
		let vbar = CGRect(x: vx, y: y, width: CGFloat(valueWidth), height: h)
		context.setFillColor(valueColor.cgColor)
		context.fill(vbar)
	}

}
