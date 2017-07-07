//
//  DisplayLink.swift
//  Prototope
//
//  Created by Jason Brennan.
//


import AppKit

typealias HeartbeatDisplayLinkCallback = (_ sender: SystemDisplayLink) -> Void

/// Provides a lookalike for `CADisplayLink` on macOS. Losely based on https://3d.bk.tudelft.nl/ken/en/2016/11/05/swift-3-and-opengl.html
class DisplayLink: NSObject {
	
	/** Starts or stops the display link. */
	var isPaused: Bool {
		get { return CVDisplayLinkIsRunning(displayLink!) }
		set {
			if newValue {
				CVDisplayLinkStop(displayLink!)
			} else {
				CVDisplayLinkStart(displayLink!)
			}
		}
	}
	
	var timestamp: TimeInterval {
		var outTime: CVTimeStamp = CVTimeStamp()
		CVDisplayLinkGetCurrentTime(displayLink!, &outTime)
		
		// TODO(jb): I don't know if hostTime is what I want
		return TimeInterval(outTime.hostTime)
	}
	
	fileprivate var displayLink: CVDisplayLink?
	fileprivate let displayLinkCallback: HeartbeatDisplayLinkCallback
	
	init(displayLinkCallback: @escaping HeartbeatDisplayLinkCallback) {
		self.displayLinkCallback = displayLinkCallback
		super.init()
		prepareDisplayLink()
	}
	
	deinit {
		CVDisplayLinkStop(displayLink!)
	}
	
	/** Starts the display link, but ignores the parameters. They only exist to keep a compatible API. */
	func add(to runLoop: RunLoop, forMode: String) {
		isPaused = false
	}
	
	
	/** Stops the display link. */
	func invalidate() {
		isPaused = true
	}
	
}

fileprivate extension DisplayLink {
	func prepareDisplayLink() {
		
		func displayLinkOutputCallback(
			displayLink: CVDisplayLink,
			_ now: UnsafePointer<CVTimeStamp>,
			_ outputTime: UnsafePointer<CVTimeStamp>,
			_ flagsIn: CVOptionFlags,
			_ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
			_ displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn {
			
			// Call through to our helper method, that actually invokes the DisplayLink callback
			unsafeBitCast(displayLinkContext, to: DisplayLink.self).callTheCallback()
			return kCVReturnSuccess
		}
		
		CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
		CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
		CVDisplayLinkStart(displayLink!)
	}
	
	func callTheCallback() {
		displayLinkCallback(self)
	}
}

