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
	public static func moveTo(screenPosition: Point) {
		CGWarpMouseCursorPosition(CGPoint(screenPosition))
	}
	
	public static func set(cursorAppearance: Appearance) {
		let cursor = cursorAppearance.nsCursor
		cursor.set()
	}
	
	public static func hide() {
		NSCursor.hide()
	}
	
	public static func unhide() {
		NSCursor.unhide()
	}
	
	public enum Appearance {
		case arrow
		case openHand
		case closedHand
		case crosshair
		case horizontalResizer
		case verticalResizer
		case upwardDiagonalResizer
		case downwardDiagonalResizer
		case image(Image)
		
		var nsCursor: NSCursor {
			switch self {
			case .arrow: return NSCursor.arrow
			case .openHand: return NSCursor.openHand
			case .closedHand: return NSCursor.closedHand
			case .crosshair: return NSCursor.crosshair
			case .horizontalResizer: return NSCursor.value(forKey: "_windowResizeEastWestCursor") as! NSCursor
			case .verticalResizer: return NSCursor.value(forKey: "_windowResizeNorthSouthCursor") as! NSCursor
			case .upwardDiagonalResizer:
				return NSCursor.value(forKey: "_windowResizeNorthEastSouthWestCursor") as! NSCursor
			case .downwardDiagonalResizer:
				return NSCursor.value(forKey: "_windowResizeNorthWestSouthEastCursor") as! NSCursor
			case let .image(image): return NSCursor(image: image.systemImage, hotSpot: NSPoint(x: 1, y: 1))
			}
		}
	}
}
