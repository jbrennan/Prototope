//
//  Double+Extensions.swift
//  Prototope
//
//  Created by Jason Brennan on Apr-21-2015.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

public extension Double {
	
	/** If self is not a number (i.e., NaN), returns 0. Otherwise returns self. */
	var notNaNValue: Double {
		return self.isNaN ? 0 : self
	}
	
	public func toRadians() -> Double {
		return self * Double.pi / 180.0
	}
	
	public func toDegrees() -> Double {
		return self * 180.0 / Double.pi
	}
	
	/** Clamps the receiver between the lower and the upper bounds. Basically the same as `clip()` but with a nicer API tbh. */
	public func clamp(lower: Double, upper: Double) -> Double {
		if self < lower {
			return lower
		}
		
		if self > upper {
			return upper
		}
		
		return self
	}
}
