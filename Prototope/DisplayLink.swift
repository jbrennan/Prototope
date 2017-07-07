//
//  DisplayLink.swift
//  Prototope
//
//  Created by Jason Brennan on 2015-08-10.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

/******************************************

OS X Only, folks
(also it's currently pretty broken, sorry!)

*/
import AppKit

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
	
	private var displayLink: CVDisplayLink?
	private let displayLinkCallback: HeartbeatDisplayLinkCallback
	
	init(displayLinkCallback: @escaping HeartbeatDisplayLinkCallback) {
		self.displayLinkCallback = displayLinkCallback
		super.init()
		prepareDisplayLink()
	}
	
	/** Starts the display link, but ignores the parameters. They only exist to keep a compatible API. */
	func add(to runLoop: RunLoop, forMode: String) {
		isPaused = false
	}
	
	
	/** Stops the display link. */
	func invalidate() {
		isPaused = true
	}
	
	private func prepareDisplayLink() {
		
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
	
	private func callTheCallback() {
		displayLinkCallback(self)
	}
}

typealias HeartbeatDisplayLinkCallback = (_ sender: SystemDisplayLink) -> Void
//
///** Crappy wrapper around CVDisplayLink to act pretty close to a CADisplayLink. Only OS X kids get this. */
//class DisplayLink: NSObject {
//
//
//
//
//	/** Initialize with a given callback. */
//	init(heartbeatCallback: @escaping HeartbeatDisplayLinkCallback) {
//
//		super.init()
//
//		let callback = {(
//			_:CVDisplayLink!,
//			_:UnsafePointer<CVTimeStamp>,
//			_:UnsafePointer<CVTimeStamp>,
//			_:CVOptionFlags,
//			_:UnsafeMutablePointer<CVOptionFlags>,
//			_:UnsafeMutablePointer<Void>)->Void in
//
//			heartbeatCallback(self)
//		}
//		type(of: self).DisplayLinkSetOutputCallback(self.displayLink!, callback: callback)
//	}
//
//
//}
//
//
//// Junk related to wrapping the CVDisplayLink callback function.
//extension DisplayLink {
//	private typealias DisplayLinkCallback = @objc_block ( CVDisplayLink?, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>, UnsafeMutablePointer<Void>)->Void
//
//	private class func DisplayLinkSetOutputCallback(displayLink:CVDisplayLink, callback:@escaping DisplayLinkCallback) {
//		let block:DisplayLinkCallback = callback
//		let myImp = imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
//		let callback = unsafeBitCast(myImp, CVDisplayLinkOutputCallback.self)
//
//		CVDisplayLinkSetOutputCallback(displayLink, callback, UnsafeMutablePointer<Void>())
//	}
//}
