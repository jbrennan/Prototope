//
//  Cursor.swift
//  Prototope
//
//  Created by Jason Brennan on 2017-08-20.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import Cocoa
import CoreGraphics

open class Cursor {
	open static func moveTo(screenPosition: Point) {
		CGWarpMouseCursorPosition(CGPoint(screenPosition))
	}
	
	open static func set(cursorAppearance: Appearance) {
		cursorAppearance.nsCursor.set()
	}
	
	public enum Appearance {
		case arrow
		case crosshair
		// case image(Image)
		
		var nsCursor: NSCursor {
			switch self {
			case .arrow: return NSCursor.arrow
			case .crosshair: return NSCursor.crosshair
			}
		}
	}
}
