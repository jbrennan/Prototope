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

/// Represents input from a person, like pointer (mouse) or keyboard.
/// TODO: This could be broken up into a protocol with implementations for Key and Mouse events.
public struct InputEvent {
	let event: NSEvent
	
	/// The location of the event relative to the root layer.
	public var globalLocation: Point {
		let rootLayer = Environment.currentEnvironment!.rootLayer
		return locationInLayer(layer: rootLayer)
	}
	
	/// The click count of the event.
	public var clickCount: Int {
		return event.clickCount
	}
	
	/// The location of the event in the given layer.
	public func locationInLayer(layer: Layer) -> Point {
		return layer.convertGlobalPointToLocalPoint(Point(event.locationInWindow))
	}
	
	/// An array of modifier keys, if any, held during the event.
	public var modifierKeys: [ModifierKey] {
		return InputEvent.ModifierKey.fromNSModifierFlags(modifierFlags: event.modifierFlags)
	}
	
	/// The characters, if any, that were pressed on the keyboard during the event.
	public var characters: String? {
		return event.characters
	}
}

public extension InputEvent {
	
	/// Keys that might be held down with other keys, usually for keyboard shortcuts.
	enum ModifierKey {
		
		/// The command key.
		case command
		
		/// The shift key.
		case shift
		
		/// The option key.
		case option
		
		/// The control key.
		case control
		
		fileprivate static func fromNSModifierFlags(modifierFlags: NSEventModifierFlags) -> [ModifierKey] {
			var keys = [ModifierKey]()
			if modifierFlags.contains(.shift) {
				keys.append(.shift)
			}
			
			if modifierFlags.contains(.command) {
				keys.append(.command)
			}
			
			if modifierFlags.contains(.option) {
				keys.append(.option)
			}
			
			if modifierFlags.contains(.control) {
				keys.append(.control)
			}
			return keys
		}
	}
	
}

public extension InputEvent {
	public var isDoubleClick: Bool { return clickCount >= 2 }
}
