//
//  FlippedView.swift
//  Prototope
//
//  Created by Jason Brennan on 2017-07-26.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import AppKit

/// A view whose coordinate space is "flipped" (for macOS targets).
public class FlippedView: SystemView {
	override public var isFlipped: Bool {
		return true
	}
	
	override public init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		wantsLayer = true
	}
	
	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
