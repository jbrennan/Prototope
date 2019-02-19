//
//  DrawingLayer.swift
//  Prototope
//
//  Created by Jason Brennan on 2018-04-16.
//  Copyright © 2018 Jason Brennan. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

/// Layer class for drawing custom content. If you don't require drawing custom bitmap drawing, you're probs better off using a plain old `Layer`.
open class DrawingLayer: Layer {
	
	public typealias DrawingBlock = (DrawingLayer) -> Void
	
	public init(parent: Layer? = nil, name: String? = nil) {
		super.init(parent: parent, name: name, viewClass: DrawingView.self)
		drawingView.drawingLayer = self
	}
	
	public var drawingBlock: DrawingBlock? {
		get { return drawingView.drawingBlock }
		set { drawingView.drawingBlock = newValue }
	}
	
	public func setNeedsRedraw() {
		drawingView.setNeedsDisplay()
	}
	
	public func redrawIfNeeded() {
		drawingView.displayIfNeeded()
	}
	
	private var drawingView: DrawingView {
		return view as! DrawingView
	}
}

private extension DrawingLayer {
	
	class DrawingView: SystemView, InteractionHandling {
		weak var drawingLayer: DrawingLayer?
		var drawingBlock: DrawingBlock?
		
		override func draw(_ rect: CGRect) {
			drawingBlock?(drawingLayer!)
		}
		
		// note: nothing sets this to false, but leaving here in case I ever need to make it work
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
//			let locationInView = convert(event.locationInWindow, from: nil)
//			dragBehavior?.dragDidBegin(atLocationInLayer: Point(locationInView))
			mouseDownHandler?(InputEvent(event: event))
		}
		
		
		var mouseMovedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseMoved(with event: NSEvent) {
			mouseMovedHandler?(InputEvent(event: event))
			// TODO: when there's no handler, or when the handler indicates it should not handle the event, call super.
		}
		
		
		var mouseUpHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseUp(with event: NSEvent) {
			mouseUpHandler?(InputEvent(event: event))
		}
		
		var mouseDraggedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseDragged(with event: NSEvent) {
			// when changing this implementation, remember to update the impls in Scroll and ShapeLayer, etc
//			let locationInSuperView = superview!.convert(event.locationInWindow, from: nil)
//			dragBehavior?.dragDidChange(atLocationInParentLayer: Point(locationInSuperView))
			mouseDraggedHandler?(InputEvent(event: event))
		}
		var mouseEnteredHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseEntered(with event: NSEvent) {
			mouseEnteredHandler?(InputEvent(event: event))
		}
		var mouseExitedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseExited(with event: NSEvent) {
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
	}
}
