//
//  Geometry.swift
//  Prototope
//
//  Created by Andy Matuschak on 10/7/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

import CoreGraphics

// MARK: - Point

/** Represents a 2D point (or vector). */
public struct Point: Equatable, Codable {
	public var x: Double
	public var y: Double

	/** Point(x: 0, y: 0). */
	static public let zero = Point(x: 0, y: 0)
	
	/** Point(x: 1, y: 1). */
	static public let one = Point(x: 1, y: 1)
	
	public init(x: Double = 0, y: Double = 0) {
		self.x = x
		self.y = y
	}

	/** Constructs a Point from a CGPoint. */
	public init(_ point: CGPoint) {
		self.x = Double(point.x)
		self.y = Double(point.y)
	}

	/** Computes traditional 2D (i.e. Euclidean) distance to another point. */
	public func distanceToPoint(_ point: Point) -> Double {
		let dx = point.x - self.x
		let dy = point.y - self.y
		return sqrt(dx*dx + dy*dy)
	}
	
	/// Computes the distance to the given `rect`. A distance of 0 means the point is touching or inside the rectangle.
	public func distance(to rect: Rect) -> Double {
		let dx = max(fabs(x - rect.center.x) - rect.size.width, 0)
		let dy = max(fabs(y - rect.center.y) - rect.size.height, 0)
		return (dx * dx + dy * dy).squareRoot()
	}
	
	
	/** Computes the slope between this point and the given point. Returns nil for infinite slopes (i.e., when the x values are the same). */
	public func slopeToPoint(_ point: Point) -> Double? {
		let dx = point.x - self.x
		let dy = point.y - self.y
		
		if dx == 0 {
			return nil
		}
		return dy/dx
	}

	/** Computes the magnitude of the point, interpreted as a vector. */
	public var length: Double {
		return sqrt(x*x + y*y)
	}
	
	/** Returns the dot product of the two points (both interpreted as vectors). */
	public func dotProduct(_ otherVector: Point) -> Double {
		return x * otherVector.x + y * otherVector.y
	}
}

public func ==(a: Point, b: Point) -> Bool {
	return a.x == b.x && a.y == b.y
}

extension Point: CustomStringConvertible {
	public var description: String {
		return "{x: \(x), y: \(y)}"
	}
}

/** Performs vector addition. */
public func +(a: Point, b: Point) -> Point {
	return Point(x: a.x + b.x, y: a.y + b.y)
}

/** Performs vector addition. */
public func +=(a: inout Point, b: Point) {
	a = a + b
}

/** Offsets the given point by the given size. */
public func +(point: Point, size: Size) -> Point {
	return Point(x: point.x + size.width, y: point.y + size.height)
}

/** Performs vector subtraction. */
public func -(a: Point, b: Point) -> Point {
	return Point(x: a.x - b.x, y: a.y - b.y)
}

/** Performs vector subtraction. */
public func -=(a: inout Point, b: Point) {
	a = a - b
}

/** Multiplies both point dimensions by scalar. */
public func *(a: Point, scalar: Double) -> Point {
	return Point(x: a.x * scalar, y: a.y * scalar)
}
public func *(scalar: Double, a: Point) -> Point {
    return a * scalar
}


/** Element-wise multiplication. */
public func *(a: Point, b: Point) -> Point {
	return Point(x: a.x * b.x, y: a.y * b.y)
}

/** Multiplies both point dimensions by scalar. */
public func *=(a: inout Point, scalar: Double) {
	a = a * scalar
}

/** Divides both point dimensions by scalar. */
public func /(a: Point, scalar: Double) -> Point {
	return a * (1.0 / scalar)
}

/** Divides both point dimensions by scalar. */
public func /=(a: inout Point, scalar: Double) {
	a = a / scalar
}

extension CGPoint {
	/** Constructs a CGPoint from a Point. */
	public init(_ point: Point) {
		self.init()
		self.x = CGFloat(point.x)
		self.y = CGFloat(point.y)
	}
}

public extension Point {
	
	/** Returns if the receiver is in the given rect. This is a different way of expressing `rect.contains(self)`. */
	func isIn(rect: Rect) -> Bool {
		return rect.contains(self)
	}
}


// MARK: - Size

/** Represents a size in 2D space. */
public struct Size: Equatable, Codable {
	public var width: Double
	public var height: Double

	/** Size(width: 0, height: 0). */
	static public let zero = Size(width: 0, height: 0)
	
	/// Size(width: 1, height: 1).
	static public let one = Size(squareLength: 1)
	
	public init(width: Double = 0, height: Double = 0) {
		self.width = width
		self.height = height
	}

	/** Constructs a Size from a CGSize. */
	public init(_ size: CGSize) {
		self.width = Double(size.width)
		self.height = Double(size.height)
	}
	
	/// Creates a square size with the given length.
	public init(squareLength: Double) {
		self.width = squareLength
		self.height = squareLength
	}
}

public func ==(a: Size, b: Size) -> Bool {
	return a.width == b.width && a.height == b.height
}

/** Returns a Size whose width is the sum of the two sizes' widths; ditto for height. */
public func +(a: Size, b: Size) -> Size {
	return Size(width: a.width + b.width, height: a.height + b.height)
}

/** Adds the argument's width to the receiver's width; ditto for width. */
public func +=(a: inout Size, b: Size) {
	a = a + b
}

/** Computes a new Size by multiplying the size's width and height by scalar. */
public func *(a: Size, scalar: Double) -> Size {
	return Size(width: a.width * scalar, height: a.height * scalar)
}

/** Multiplies the size's width and height by scalar (in place). */
public func *=(a: inout Size, scalar: Double) {
	a = a * scalar
}

extension CGSize {
	/** Constructs a CGSize from a Size. */
	public init(_ size: Size) {
		self.init()
		self.width = CGFloat(size.width)
		self.height = CGFloat(size.height)
	}
}

extension Size: CustomStringConvertible {
	public var description: String {
		return "{width: \(width), height: \(height)}"
	}
}


// MARK: - Rect

/** Represents a rectangle in 2D space. */
public struct Rect: Equatable, Codable {
	/** The rectangle's corners are formed by adding its size to this origin, which represents
		the corner without either size dimension added to it. */
	public var origin: Point

	/** The rectangle's corners are formed by adding the components of this size to its origin. */
	public var size: Size

	/** The smallest X value touched by this rectangle. */
	public var minX: Double { return Double(CGRect(self).minX) }

	/** The X value at the middle of this rectangle. */
	public var midX: Double { return Double(CGRect(self).midX) }

	/** The largest X value touched by this rectangle. */
	public var maxX: Double { return Double(CGRect(self).maxX) }

	/** The smallest Y value touched by this rectangle. */
	public var minY: Double { return Double(CGRect(self).minY) }

	/** The Y value at the middle of this rectangle. */
	public var midY: Double { return Double(CGRect(self).midY) }

	/** The largest Y value touched by this rectangle. */
	public var maxY: Double { return Double(CGRect(self).maxY) }

	/** The center of the rectangle. */
	public var center: Point {
		get { return Point(x: midX, y: midY) }
		set { origin += newValue - center }
	}

	/** Rect(x: 0, y: 0, width: 0, height: 0). */
	public static let zero = Rect(x: 0, y: 0, width: 0, height: 0)

	public init(x: Double = 0, y: Double = 0, width: Double = 0, height: Double = 0) {
		origin = Point(x: x, y: y)
		size = Size(width: width, height: height)
	}

	/** Constructs a Rect from a CGRect. */
	public init(_ rect: CGRect) {
		origin = Point(rect.origin)
		size = Size(rect.size)
	}
    
    /** Returns a Rect constructed by insetting the receiver. */
    public func inset(top: Double = 0, right: Double = 0, bottom: Double = 0, left: Double = 0) -> Rect {
        if top + bottom > size.height {
            Environment.currentEnvironment?.exceptionHandler("Trying to inset \(self) with vertical insets (\(top),\(bottom)) greater than the height")
        } else if left + right > size.width {
            Environment.currentEnvironment?.exceptionHandler("Trying to inset \(self) with horizontal insets (\(left),\(right)) greater than the width")
        }
        
        var newRect = self
        newRect.origin.x += left
        newRect.size.width -= left + right
        newRect.origin.y += top
        newRect.size.height -= top + bottom
        
        return newRect
    }
	
	/// Returns a version of the receiver with either the original origin, or a 0 origin if the origin was infinite.
	public func nonInfinite() -> Rect {
		var r = self
		r.origin.x = r.origin.x.isFinite ? r.origin.x : 0
		r.origin.y = r.origin.y.isFinite ? r.origin.y : 0
		
		return r
	}
    
    /** Convenience function. Returns a Rect constructed by insetting the receiver. */
    public func inset(vertical: Double = 0, horizontal: Double = 0) -> Rect {
        return inset(top: vertical, right: horizontal, bottom: vertical, left: horizontal)
    }
    
    /** Convenience function. Returns a Rect constructed by insetting the receiver. */
    public func inset(value: Double = 0) -> Rect {
        return inset(top: value, right: value, bottom: value, left: value)
    }
	
	/// Returns the union of `self` and the given rect.
	public func union(with other: Rect) -> Rect {
		return Rect(CGRect(self).union(CGRect(other)))
	}
    
    /** Determines whether this rectangle contains the specified point. */
    public func contains(_ point: Point) -> Bool {
        let r = CGRect(self)
        let p = CGPoint(point)
        return r.contains(p)
    }
	
	
	/** Determines whether this rectagle entirely contains the given rectangle. */
	public func contains(_ rect: Rect) -> Bool {
		let r = CGRect(self)
		let otherRect = CGRect(rect)
		return r.contains(otherRect)
	}
	
	/** Returns if the other rect intersects with the receiver. */
	public func intersectsRect(_ rect: Rect) -> Bool {
		let r = CGRect(self)
		let otherRect = CGRect(rect)
		return r.intersects(otherRect)
	}
}

public func ==(a: Rect, b: Rect) -> Bool {
	return a.origin == b.origin && a.size == b.size
}

extension CGRect {
	/** Constructs a CGRect from a Rect. */
	public init(_ rect: Rect) {
		self.init()
		self.origin = CGPoint(rect.origin)
		self.size = CGSize(rect.size)
	}
}


extension Rect: CustomStringConvertible {
	public var description: String {
		return "{origin: \(origin), size: \(size)}"
	}
}
