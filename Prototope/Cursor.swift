//
//  Cursor.swift
//  Prototope
//
//  Created by Jason Brennan on 2017-08-20.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import Foundation
import CoreGraphics

open class Cursor {
	open static func moveTo(screenPosition: Point) {
		CGWarpMouseCursorPosition(CGPoint(screenPosition))
	}
}
