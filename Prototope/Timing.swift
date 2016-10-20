//
//  Timing.swift
//  Prototope
//
//  Created by Andy Matuschak on 10/8/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

import QuartzCore

/** Represents an interval between two times. */
public typealias TimeInterval = Foundation.TimeInterval

/** Represents an instant in time. */
public struct Timestamp: Comparable, Hashable {
	public let nsTimeInterval: Foundation.TimeInterval

	public static var currentTimestamp: Timestamp {
		return Timestamp(CACurrentMediaTime())
	}

	public init(_ nsTimeInterval: Foundation.TimeInterval) {
		self.nsTimeInterval = nsTimeInterval
	}

	public var hashValue: Int {
		return nsTimeInterval.hashValue
	}
}

public func <(a: Timestamp, b: Timestamp) -> Bool {
	return a.nsTimeInterval < b.nsTimeInterval
}

public func ==(a: Timestamp, b: Timestamp) -> Bool {
	return a.nsTimeInterval == b.nsTimeInterval
}

public func -(a: Timestamp, b: Timestamp) -> TimeInterval {
	return a.nsTimeInterval - b.nsTimeInterval
}


// MARK: -

/** Performs an action after a duration. */
public func afterDuration(_ duration: TimeInterval, action: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: action)
}
