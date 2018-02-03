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
		case horizontalResizer
		case verticalResizer
		case upwardDiagonalResizer
		case downwardDiagonalResizer
		// case image(Image)
		
		var nsCursor: NSCursor {
			switch self {
			case .arrow: return NSCursor.arrow
			case .crosshair: return NSCursor.crosshair
			case .horizontalResizer: return NSCursor.value(forKey: "_windowResizeEastWestCursor") as! NSCursor
			case .verticalResizer: return NSCursor.value(forKey: "_windowResizeNorthSouthCursor") as! NSCursor
			case .upwardDiagonalResizer:
				return NSCursor.value(forKey: "_windowResizeNorthEastSouthWestCursor") as! NSCursor
			case .downwardDiagonalResizer:
				return NSCursor.value(forKey: "_windowResizeNorthWestSouthEastCursor") as! NSCursor
			}
		}
	}
}
