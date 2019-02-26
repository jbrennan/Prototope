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
	
	public var mouseDelta: Point {
		return Point(CGPoint(x: event.deltaX, y: event.deltaY))
	}
	
	/// An array of modifier keys, if any, held during the event.
	public var modifierKeys: [ModifierKey] {
		return InputEvent.ModifierKey.fromNSModifierFlags(modifierFlags: event.modifierFlags)
	}
	
	/// The characters, if any, that were pressed on the keyboard during the event.
	public var characters: String? {
		return event.characters
	}
	
	/// The non-letter hardware key pressed, if any.
	public var keyCode: KeyCode? {
		return KeyCode(fromSystemKeyCode: Int(event.charactersIgnoringModifiers?.utf16.first ?? 0))
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
		
		fileprivate static func fromNSModifierFlags(modifierFlags: NSEvent.ModifierFlags) -> [ModifierKey] {
			var keys = [ModifierKey]()
			if modifierFlags.contains(NSEvent.ModifierFlags.shift) {
				keys.append(.shift)
			}
			
			if modifierFlags.contains(NSEvent.ModifierFlags.command) {
				keys.append(.command)
			}
			
			if modifierFlags.contains(NSEvent.ModifierFlags.option) {
				keys.append(.option)
			}
			
			if modifierFlags.contains(NSEvent.ModifierFlags.control) {
				keys.append(.control)
			}
			return keys
		}
	}
	
	/// For non-letter keyboard keys
	enum KeyCode {
		case leftArrow
		case rightArrow
		case upArrow
		case downArrow
		case space
		case delete
		
		fileprivate init?(fromSystemKeyCode keyCode: Int) {
			switch keyCode {
			case NSEvent.SpecialKey.leftArrow.rawValue: self = .leftArrow
			case NSEvent.SpecialKey.rightArrow.rawValue: self = .rightArrow
			case NSEvent.SpecialKey.upArrow.rawValue: self = .upArrow
			case NSEvent.SpecialKey.downArrow.rawValue: self = .downArrow
			case 0x20: self = .space
			case NSEvent.SpecialKey.deleteForward.rawValue, NSEvent.SpecialKey.delete.rawValue: self = .delete
			default: return nil
			}
		}
	}
	
}

public extension InputEvent {
	public var isDoubleClick: Bool { return clickCount >= 2 }
}
