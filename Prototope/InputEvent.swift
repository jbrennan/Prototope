//
//  InputEvent.swift
//  Prototope
//
//  Created by Jason Brennan on 2015-08-17.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

/////////////////////////////////////////////
// OS X Only
/////////////////////////////////////////////

import AppKit

/* Represents input from a person, like pointer (mouse) or keyboard. */
public struct InputEvent {
	let event: NSEvent
	
	public var globalLocation: Point {
		let rootLayer = Environment.currentEnvironment!.rootLayer
		return locationInLayer(layer: rootLayer)
	}
	
	public var clickCount: Int {
		return event.clickCount
	}
	
	public func locationInLayer(layer: Layer) -> Point {
		return Point(layer.view.convert(event.locationInWindow, from: nil))
	}
}

public extension InputEvent {
	public var isDoubleClick: Bool { return clickCount >= 2 }
}
