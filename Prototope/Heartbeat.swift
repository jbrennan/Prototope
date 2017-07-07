//
//  Heartbeat.swift
//  Prototope
//
//  Created by Andy Matuschak on 11/19/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

import QuartzCore

/** Allows you to run code once for every frame the display will render. */
open class Heartbeat {
	
	/** The heartbeat's handler won't be called when paused is true. Defaults to false. */
	open var paused: Bool {
		get { return displayLink.isPaused }
		set { displayLink.isPaused = newValue }
	}

	/** The current timestamp of the heartbeat. Only valid to call from the handler block. */
	open var timestamp: Timestamp {
		return Timestamp(displayLink.timestamp)
	}
	
	/** The previous timestamp of the heartbeat. See also `deltaTime`. Only valid to call from the handler block. */
	open var previousTimestamp: Timestamp
	
	
	/** The delta between the current and previous heartbeats. Only valid to call from the handler block. */
	open var deltaTime: TimeInterval {
		return timestamp - previousTimestamp
	}

	/** The handler will be invoked for every frame to be rendered. It will be passed the
		Heartbeat instance initialized by this constructor (which permits you to access its
		properties from within the closure). */
	public init(paused: Bool = false, handler: @escaping (Heartbeat) -> ()) {
		self.handler = handler
		self.previousTimestamp = Timestamp.currentTimestamp
		
		#if os(iOS)
		displayLink = SystemDisplayLink(target: self, selector: #selector(Heartbeat.handleDisplayLink(_:)))
			#else
			displayLink = SystemDisplayLink(displayLinkCallback: handleDisplayLink)
			#endif
		displayLink.isPaused = paused
		#if os(iOS)
			displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
		#endif
	}

	/** Permanently stops the heartbeat. */
	open func stop() {
		displayLink.invalidate()
	}

    // MARK: Private interfaces
    
    fileprivate let handler: (Heartbeat) -> ()
    fileprivate var displayLink: SystemDisplayLink!
    
    @objc fileprivate func handleDisplayLink(_ sender: SystemDisplayLink) {
        precondition(displayLink === sender)
        handler(self)
		previousTimestamp = timestamp
    }
}


#if os(iOS)
	import UIKit
	typealias SystemDisplayLink = CADisplayLink
	#else
	import AppKit
	typealias SystemDisplayLink = DisplayLink
#endif

