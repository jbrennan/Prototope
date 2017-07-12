//
//  Shadow.swift
//  Prototope
//
//  Created by Andy Matuschak on 12/2/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

/** A simple specification of a layer shadow. */
public struct Shadow {
	public var color: Color
	#if os(iOS)
	/// Alpha of the shadow. iOS only (OS X uses the alpha of the shadow's `color`).
	public var alpha: Double
	#endif
	public var offset: Size
	public var radius: Double

	#if os(iOS)
	public init(color: Color, alpha: Double, offset: Size, radius: Double) {
		self.color = color
		self.alpha = alpha
		self.offset = offset
		self.radius = radius
	}
	#else
	public init(color: Color, offset: Size, radius: Double) {
		self.color = color
		self.offset = offset
		self.radius = radius
	}
	#endif
}

extension Shadow {
	var isVisible: Bool {
		#if os(iOS)
		return alpha > 0
		#else
		return color.systemColor.alphaComponent > 0
		#endif
	}
}

