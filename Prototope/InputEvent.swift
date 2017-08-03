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
	
	public var modifierKeys: [ModifierKey] {
		return InputEvent.ModifierKey.fromNSModifierFlags(modifierFlags: event.modifierFlags)
	}
}

public extension InputEvent {
	enum ModifierKey {
		case shift
		
		fileprivate static func fromNSModifierFlags(modifierFlags: NSEventModifierFlags) -> [ModifierKey] {
			var keys = [ModifierKey]()
			if modifierFlags.contains(.shift) {
				keys.append(.shift)
			}
			return keys
		}
	}
	
}

public extension InputEvent {
	public var isDoubleClick: Bool { return clickCount >= 2 }
}
