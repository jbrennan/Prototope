//
//  FlippedView.swift
//  Prototope
//
//  Created by Jason Brennan on 2017-07-26.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import AppKit

/// A view whose coordinate space is "flipped" (for macOS targets).
class FlippedView: SystemView {
	override var isFlipped: Bool {
		return true
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		wantsLayer = true
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
