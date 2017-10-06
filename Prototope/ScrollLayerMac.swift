//
//  ScrollLayerMac.swift
//  Prototope
//
//  Created by Jason Brennan on 2017-07-26.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import AppKit

typealias SystemScrollView = NSScrollView

/** This layer allows you to scroll sublayers, with inertia and rubber-banding. */
open class ScrollLayer: Layer {
	
	/** Create a layer with an optional parent layer and name. */
	public init(parent: Layer? = nil, name: String? = nil) {
		documentView = FlippedView(frame: CGRect())
		notificationHandler = ScrollViewDelegate()
		
		super.init(parent: parent, name: name, viewClass: InteractionHandlingScrollView.self)
		scrollView.contentView.wantsLayer = true
		scrollView.documentView = documentView
		
		scrollView.allowsMagnification = true
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(ScrollViewDelegate.scrollViewDidScroll(notification:)),
			name: NSNotification.Name.NSScrollViewDidLiveScroll, object: scrollView
		)
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(ScrollViewDelegate.scrollViewWillBeginLiveMagnification(notification:)),
			name: NSNotification.Name.NSScrollViewWillStartLiveMagnify, object: scrollView
		)
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(ScrollViewDelegate.scrollViewDidEndLiveMagnification(notification:)),
			name: NSNotification.Name.NSScrollViewDidEndLiveMagnify, object: scrollView
		)
	}
	
	deinit {
//		scrollView.delegate = nil
	}
	
	var scrollView: SystemScrollView {
		return self.view as! SystemScrollView
	}
	private let documentView: SystemView
	private let notificationHandler: ScrollViewDelegate
	
	// This causes ScrollLayer's sublayers to be added to the scroll view's documentView, so they can be scrolled.
	override var childHostingView: SystemView? {
		return self.documentView
	}
	
	open var drawsBackgroundColor: Bool {
		get { return scrollView.drawsBackground }
		set { scrollView.drawsBackground = newValue }
	}

	
	// MARK: - Properties
	
	/// Converts a point to the scroll layer's **document view**'s coordinate space.
	open override func convertGlobalPointToLocalPoint(_ globalPoint: Point) -> Point {
		return Point(childHostingView!.convert(CGPoint(globalPoint), from: nil))
	}
	
	/** The scroll position of the scroll layer in its own coordinates. */
	public var scrollPosition: Point {
		get { return Point(scrollView.contentView.bounds.origin) }
		set { scrollView.documentView?.scroll(CGPoint(newValue)) }
	}
	
	/** The scrollable size of the layer. */
	public var scrollableSize: Size {
		get { return Size(self.documentView.bounds.size) }
		set {
			var frame = self.documentView.frame
			frame.size = CGSize(newValue)
			self.documentView.frame = frame
		}
	}
	
	
	/** Controls whether or not the vertical scroll indicator shows on scroll. Defaults to `true`. */
	open var showsVerticalScrollIndicator: Bool {
		get { return self.scrollView.hasVerticalScroller }
		set { self.scrollView.hasVerticalScroller = newValue }
	}
	
	
	/** Controls whether or not the horizontal scroll indicator shows on scroll. Defaults to `true`. */
	open var showsHorizontalScrollIndicator: Bool {
		get { return self.scrollView.hasHorizontalScroller }
		set { self.scrollView.hasHorizontalScroller = newValue }
	}
	
	/** Controls whether or not the scrollview can bounce horizontally. Defaults to `true`. */
	open var alwaysBouncesHorizontally: Bool {
		get { return scrollView.horizontalScrollElasticity != .none }
		set { return scrollView.horizontalScrollElasticity = newValue ? .allowed : .none }
	}
	
	/** Controls whether or not the scrollview can bounce vertically. Defaults to `true`. */
	open var alwaysBouncesVertically: Bool {
		get { return scrollView.verticalScrollElasticity != .none }
		set { return scrollView.verticalScrollElasticity = newValue ? .allowed : .none }
	}
	
	/** Controls whether or not the scrollView supports magnification. Defaults to `false`. */
	open var allowsMagnification: Bool {
		get { return self.scrollView.allowsMagnification }
		set { self.scrollView.allowsMagnification = newValue }
	}
	
	/** Controls whether or not the horizontal scroll indicator shows on scroll. Defaults to `true`. */
	open var magnification: Double {
		get { return Double(self.scrollView.magnification) }
		set { animatableScrollView.magnification = CGFloat(newValue) }
	}
	
	open var maximumMagnification: Double {
		get { return Double(self.scrollView.maxMagnification) }
		set { self.scrollView.maxMagnification = CGFloat(newValue) }
	}
	
	open var minimumMagnification: Double {
		get { return Double(self.scrollView.minMagnification) }
		set { self.scrollView.minMagnification = CGFloat(newValue) }
	}
	
	/// Determines whether or not the scroll layer tries to scroll in one direction primarily (`true` by default). Set this to `false` for layers which should easily scroll in all directions, like in a large drawing canvas. 
	open var usesPredominantAxisScrolling: Bool {
		get { return scrollView.usesPredominantAxisScrolling }
		set { scrollView.usesPredominantAxisScrolling = newValue }
	}
	

	/** This handler is called when the scrollView scrolls. */
	open var didScrollHandler: (() -> ())? {
		didSet {
			notificationHandler.didScrollHandler = didScrollHandler
		}
	}
	
	/** This handler is called when the scrollView begins a live magnification. */
	open var willBeginMagnifyingHandler: (() -> ())? {
		didSet {
			notificationHandler.willBeginMagnifyingHandler = willBeginMagnifyingHandler
		}
	}
	
	/** This handler is called when the scrollView magnifies. */
	open var didMagnifyHandler: (() -> ())? {
		didSet {
			notificationHandler.didEndMagnifyingHandler = didMagnifyHandler
		}
	}
	
	
	// MARK: - Methods
	
	/** Updates the scrollable size of the layer to fit its subviews exactly. Does not change the size of the layer, just its scrollable area. */
	open func updateScrollableSizeToFitSublayers() {
		var maxRect = CGRect()
		for sublayer in self.sublayers {
			maxRect = maxRect.union(CGRect(sublayer.frame))
		}
		
		self.scrollableSize = Size(maxRect.size)
	}
	
	/** If the given `rect` is not completely visible, this scrolls just so the rect is visible. Otherwise, it does nothing. */
	open func scrollToRectVisibile(_ rect: Rect, animated: Bool = true) {
		Layer.animateWithDuration(animated ? 0.15 : 0, animations: {
			self.scrollView.scrollToVisible(CGRect(rect))
		})
	}
	
	/** Momentarily flash the scroll indicators. */
	open func flashScrollIndicators() {
		scrollView.flashScrollers()
	}
	
	
	@objc fileprivate class ScrollViewDelegate: NSObject {
//		var decelerationRetargetingHandler: ((_ velocity: Point, _ decelerationTarget: Point) -> Point)?
		var didScrollHandler: (() -> ())?
		var willBeginMagnifyingHandler: (() -> ())?
		var didEndMagnifyingHandler: (() -> ())?
		
		func scrollViewDidScroll(notification: NSNotification) {
			didScrollHandler?()
		}
		
		func scrollViewWillBeginLiveMagnification(notification: NSNotification) {
			willBeginMagnifyingHandler?()
		}
		
		func scrollViewDidEndLiveMagnification(notification: NSNotification) {
			didEndMagnifyingHandler?()
		}
	}
	
	
	fileprivate class InteractionHandlingScrollView: SystemScrollView, InteractionHandling {

		var mouseInteractionEnabled = true
		
		override func hitTest(_ point: NSPoint) -> NSView? {
			guard mouseInteractionEnabled else { return nil }
			
			return super.hitTest(point)
		}

		override var acceptsFirstResponder: Bool {
			return keyEquivalentHandler != nil
		}
		
		var keyEquivalentHandler: Layer.KeyEquivalentHandler?
		
		override func performKeyEquivalent(with event: NSEvent) -> Bool {
			if let handler = keyEquivalentHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return true
				case .unhandled: return false
				}
			}
			
			return false
		}

		var mouseDownHandler: Layer.MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		var mouseMovedHandler: Layer.MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		var mouseUpHandler: Layer.MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		var mouseDraggedHandler: Layer.MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		var mouseEnteredHandler: Layer.MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		var mouseExitedHandler: Layer.MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		
		override func mouseDown(with event: NSEvent) {
			super.mouseDown(with: event)
			mouseDownHandler?(InputEvent(event: event))
		}
		
		override func mouseMoved(with event: NSEvent) {
			super.mouseMoved(with: event)
			mouseMovedHandler?(InputEvent(event: event))
		}
		
		override func mouseUp(with event: NSEvent) {
			super.mouseUp(with: event)
			mouseUpHandler?(InputEvent(event: event))
		}
		
		override func mouseDragged(with event: NSEvent) {
			super.mouseDragged(with: event)
			mouseDraggedHandler?(InputEvent(event: event))
		}
		
		override func mouseEntered(with event: NSEvent) {
			super.mouseEntered(with: event)
			mouseEnteredHandler?(InputEvent(event: event))
		}
		
		override func mouseExited(with event: NSEvent) {
			super.mouseExited(with: event)
			mouseExitedHandler?(InputEvent(event: event))
		}
	}
}

private extension ScrollLayer {
	
	/// Use this for any scrollView property change you want to be animatable.
	var animatableScrollView: SystemScrollView {
		return animatableView as! SystemScrollView
	}
}
