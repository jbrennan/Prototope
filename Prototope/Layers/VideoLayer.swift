//
//  VideoLayer.swift
//  Prototope
//
//  Created by Jason Brennan on 2015-02-09.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import AppKit
import AVKit
#endif
import AVFoundation
import CoreMedia

/** This layer can play a video object. */
open class VideoLayer: Layer {
	
	/** The layer's current video. */
	var video: Video? {
		didSet {
			videoDidChange()
		}
	}
	
	/** Creates a video layer with the given video. */
	public init(parent: Layer? = nil, video: Video?) {
		self.video = video
		
		super.init(parent: parent, name: video?.name, viewClass: StandardVideoView.self)
		videoDidChange()
	}
	
	private func videoDidChange() {
		(view as! StandardVideoView).player = video?.player
	}
	
	/** Play the video. */
	open func play() {
		player?.play()
	}
	
	
	/** Pause the video. */
	open func pause() {
		player?.pause()
	}
	
	open var isPlaying: Bool {
		return player?.rate != 0.0
	}
	
	open var isFinished: Bool {
		return player?.currentTime() == player?.currentItem?.duration
	}
	
	open func restartFromBeginning() {
		player?.seek(to: CMTime.zero)
	}
	
	private var player: AVPlayer? {
		return video?.player
	}
	
	
	/** Underlying video view class. */
	fileprivate class VideoView: SystemView, InteractionHandling, DraggableView, ResizableView {
		#if os(iOS)
		override class var layerClass : AnyClass {
			return AVPlayerLayer.self
		}
		#else
		override func makeBackingLayer() -> CALayer {
			return AVPlayerLayer()
		}
		
		var dragBehavior: DragBehavior?
		var resizeBehavior: ResizeBehavior?
		
		var mouseInteractionEnabled = true

		var pointInside: ((Point) -> Bool)?

		override func isMousePoint(_ point: NSPoint, in rect: NSRect) -> Bool {
			if let pointInside = pointInside {
				return pointInside(Point(point))
			}

			return super.isMousePoint(point, in: rect)
		}
		
		var cursorAppearance: Cursor.Appearance? {
			didSet {
				setupTrackingAreaIfNeeded()
				window?.invalidateCursorRects(for: self)
			}
		}
		
		override func resetCursorRects() {
			super.resetCursorRects()
			if let cursor = cursorAppearance {
				addCursorRect(bounds, cursor: cursor.nsCursor)
			}
		}
		
		override func hitTest(_ point: NSPoint) -> NSView? {
			guard mouseInteractionEnabled else { return nil }
			
			return super.hitTest(point)
		}
		
		// We want the coordinates to be flipped so they're the same as on iOS.
		override var isFlipped: Bool {
			return true
		}
		
		var mouseDownHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseDown(with event: NSEvent) {
			// when changing this implementation, remember to update the impls in Scroll and ShapeLayer, etc
			let locationInView = convert(event.locationInWindow, from: nil)
			dragBehavior?.dragDidBegin(atLocationInLayer: Point(locationInView))
			
			let inputEvent = InputEvent(event: event)
			resizeBehavior?.mouseDown(with: inputEvent)
			mouseDownHandler?(inputEvent)
		}
		
		
		var mouseMovedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseMoved(with event: NSEvent) {
			let inputEvent = InputEvent(event: event)
			resizeBehavior?.mouseMoved(with: inputEvent)
			mouseMovedHandler?(inputEvent)
			// TODO: when there's no handler, or when the handler indicates it should not handle the event, call super.
		}
		
		
		var mouseUpHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseUp(with event: NSEvent) {
			resizeBehavior?.mouseUp()
			mouseUpHandler?(InputEvent(event: event))
		}
		
		var mouseDraggedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseDragged(with event: NSEvent) {
			// when changing this implementation, remember to update the impls in Scroll and ShapeLayer, etc
			let locationInSuperView = superview!.convert(event.locationInWindow, from: nil)
			dragBehavior?.dragDidChange(atLocationInParentLayer: Point(locationInSuperView))
			
			let inputEvent = InputEvent(event: event)
			resizeBehavior?.mouseDragged(with: inputEvent)
			mouseDraggedHandler?(inputEvent)
		}
		var mouseEnteredHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseEntered(with event: NSEvent) {
			mouseEnteredHandler?(InputEvent(event: event))
		}
		var mouseExitedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseExited(with event: NSEvent) {
			resizeBehavior?.mouseExited()
			mouseExitedHandler?(InputEvent(event: event))
		}
		
		
		var keyEquivalentHandler: Layer.KeyEquivalentHandler?
		override func performKeyEquivalent(with event: NSEvent) -> Bool {
			if let handler = keyEquivalentHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return true
				case .unhandled: break
				}
			}
			
			return super.performKeyEquivalent(with: event)
		}
		
		var keyDownHandler: Layer.KeyEquivalentHandler?
		override func keyDown(with event: NSEvent) {
			if let handler = keyDownHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return
				case .unhandled: break
				}
			}
			
			return super.keyDown(with: event)
		}
		
		var flagsChangedHandler: Layer.KeyEquivalentHandler?
		override func flagsChanged(with event: NSEvent) {
			if let handler = flagsChangedHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return
				case .unhandled: break
				}
			}
			return super.flagsChanged(with: event)
		}
		
		override var acceptsFirstResponder: Bool {
			return true
		}
		
		override func becomeFirstResponder() -> Bool {
			return true
		}
		
		#endif
	}
	
	#if os(macOS)
	private class StandardVideoView: AVPlayerView, InteractionHandling, DraggableView, ResizableView {
		override func scrollWheel(with event: NSEvent) {
			nextResponder?.scrollWheel(with: event)
			// effectively disables the "scroll to seek in the video" functionality
			return
		}
		
		var dragBehavior: DragBehavior?
		var resizeBehavior: ResizeBehavior?
		
		var mouseInteractionEnabled = true

		var pointInside: ((Point) -> Bool)?

		override func isMousePoint(_ point: NSPoint, in rect: NSRect) -> Bool {
			if let pointInside = pointInside {
				return pointInside(Point(point))
			}

			return super.isMousePoint(point, in: rect)
		}
		
		var cursorAppearance: Cursor.Appearance? {
			didSet {
				setupTrackingAreaIfNeeded()
				resetCursorRects()
			}
		}
		
		override func resetCursorRects() {
			super.resetCursorRects()
			if let cursor = cursorAppearance {
				addCursorRect(bounds, cursor: cursor.nsCursor)
			}
		}
		
		override func hitTest(_ point: NSPoint) -> NSView? {
			guard mouseInteractionEnabled else { return nil }
			
			return super.hitTest(point)
		}
		
		// We want the coordinates to be flipped so they're the same as on iOS.
		override var isFlipped: Bool {
			return true
		}
		
		var mouseDownHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseDown(with event: NSEvent) {
			// when changing this implementation, remember to update the impls in Scroll and ShapeLayer, etc
			let locationInView = convert(event.locationInWindow, from: nil)
			dragBehavior?.dragDidBegin(atLocationInLayer: Point(locationInView))
			
			let inputEvent = InputEvent(event: event)
			resizeBehavior?.mouseDown(with: inputEvent)
			
			if let mouseDownHandler = mouseDownHandler {
				mouseDownHandler(inputEvent)
			} else {
				super.mouseDown(with: event)
			}
		}
		
		
		var mouseMovedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseMoved(with event: NSEvent) {
			let inputEvent = InputEvent(event: event)
			resizeBehavior?.mouseMoved(with: inputEvent)
			
			if let mouseMovedHandler = mouseMovedHandler {
				mouseMovedHandler(inputEvent)
			} else {
				super.mouseMoved(with: event)
			}
		}
		
		
		var mouseUpHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseUp(with event: NSEvent) {
			let inputEvent = InputEvent(event: event)
			resizeBehavior?.mouseUp()
			
			if let mouseUpHandler = mouseUpHandler {
				mouseUpHandler(inputEvent)
			} else {
				super.mouseUp(with: event)
			}
		}
		
		var mouseDraggedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseDragged(with event: NSEvent) {
			// when changing this implementation, remember to update the impls in Scroll and ShapeLayer, etc
			let locationInSuperView = superview!.convert(event.locationInWindow, from: nil)
			dragBehavior?.dragDidChange(atLocationInParentLayer: Point(locationInSuperView))
			
			let inputEvent = InputEvent(event: event)
			resizeBehavior?.mouseDragged(with: inputEvent)
			
			if let mouseDraggedHandler = mouseDraggedHandler {
				mouseDraggedHandler(inputEvent)
			} else {
				super.mouseDragged(with: event)
			}
			
		}
		var mouseEnteredHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseEntered(with event: NSEvent) {
			
			if let mouseEnteredHandler = mouseEnteredHandler {
				mouseEnteredHandler(InputEvent(event: event))
			} else {
				super.mouseEntered(with: event)
			}
		}
		var mouseExitedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseExited(with event: NSEvent) {
			resizeBehavior?.mouseExited()
			
			if let mouseExitedHandler = mouseExitedHandler {
				mouseExitedHandler(InputEvent(event: event))
			} else {
				super.mouseExited(with: event)
			}
		}
		
		
		var keyEquivalentHandler: Layer.KeyEquivalentHandler?
		override func performKeyEquivalent(with event: NSEvent) -> Bool {
			if let handler = keyEquivalentHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return true
				case .unhandled: break
				}
			}
			
			return super.performKeyEquivalent(with: event)
		}
		
		var keyDownHandler: Layer.KeyEquivalentHandler?
		override func keyDown(with event: NSEvent) {
			if let handler = keyDownHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return
				case .unhandled: break
				}
			}
			
			return super.keyDown(with: event)
		}
		
		var flagsChangedHandler: Layer.KeyEquivalentHandler?
		override func flagsChanged(with event: NSEvent) {
			if let handler = flagsChangedHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return
				case .unhandled: break
				}
			}
			return super.flagsChanged(with: event)
		}
		
		override var acceptsFirstResponder: Bool {
			return true
		}
		
		override func becomeFirstResponder() -> Bool {
			return true
		}
	}
	#endif
	
}


