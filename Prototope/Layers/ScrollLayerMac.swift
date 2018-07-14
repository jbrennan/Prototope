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
	
	/// The style of the ScrollLayer's canvas
	public enum ScrollSizingStyle {
		/// A standard scroll layer.
		case `default`
		
		/// An "infinite canvas" style scroll layer.
		case infinite
	}
	
	/** Create a layer with an optional parent layer and name. */
	public init(parent: Layer? = nil, name: String? = nil, scrollSizingStyle: ScrollSizingStyle = .default) {
		documentView = scrollSizingStyle == .default ? FlippedView(frame: CGRect()) : InfiniteScrollingDocumentView(frame: CGRect())
		notificationHandler = ScrollViewDelegate()
		
		super.init(parent: parent, name: name, viewClass: InteractionHandlingScrollView.self)
		scrollView.wantsLayer = true
		
		switch scrollSizingStyle {
		case .default:
			scrollView.contentView.wantsLayer = true
			scrollView.documentView = documentView
		case .infinite:
			let clipView = InfiniteClipView(frame: CGRect())
			documentView.wantsLayer = true
			clipView.documentView = documentView
			scrollView.contentView = clipView
			alwaysBouncesHorizontally = false
			alwaysBouncesVertically = false
			
			NotificationCenter.default.addObserver(
				notificationHandler,
				selector: #selector(ScrollViewDelegate.scrollViewDidScroll(notification:)),
				name: NSView.boundsDidChangeNotification, object: clipView
			)
		}
		
		scrollView.allowsMagnification = true
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(ScrollViewDelegate.scrollViewDidScroll(notification:)),
			name: NSScrollView.didLiveScrollNotification, object: scrollView
		)
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(ScrollViewDelegate.scrollViewWillBeginLiveMagnification(notification:)),
			name: NSScrollView.willStartLiveMagnifyNotification, object: scrollView
		)
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(ScrollViewDelegate.scrollViewDidEndLiveMagnification(notification:)),
			name: NSScrollView.didEndLiveMagnifyNotification, object: scrollView
		)
	}
	
	var scrollView: SystemScrollView {
		return self.view as! SystemScrollView
	}
	private let documentView: SystemView
	private let notificationHandler: ScrollViewDelegate
	
	// This causes ScrollLayer's sublayers to be added to the scroll view's documentView, so they can be scrolled.
	override var childHostingView: SystemView {
		return self.documentView
	}
	
	open var drawsBackgroundColor: Bool {
		get { return scrollView.drawsBackground }
		set { scrollView.drawsBackground = newValue }
	}

	
	// MARK: - Properties
	
	/// Converts a point to the scroll layer's **document view**'s coordinate space.
	open override func convertGlobalPointToLocalPoint(_ globalPoint: Point) -> Point {
		return Point(childHostingView.convert(CGPoint(globalPoint), from: nil))
	}
	
	open override func convertLocalPointToGlobalPoint(_ localPoint: Point) -> Point {
		return Point(childHostingView.convert(CGPoint(localPoint), to: nil))
	}
	
	/** The scroll position of the scroll layer in its own coordinates. */
	public var scrollPosition: Point {
		get { return Point(documentView.visibleRect.origin) }
		set { scrollView.documentView?.scroll(CGPoint(newValue)) }
	}
	
	/// Returns the area visible through the scroll layer.
	open var visibleScrollArea: Rect {
		return Rect(documentView.visibleRect)
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
//			self.scrollView.scrollToVisible(CGRect(rect)) // doesn't work, I'm guessing because of my scroll layer / document view hierarchy
			self.scrollPosition = rect.origin
		})
	}
	
	/** Momentarily flash the scroll indicators. */
	open func flashScrollIndicators() {
		scrollView.flashScrollers()
	}
	
	/// Recenters the scroll layer if it's Infinite. Currently does nothing for normal scroll layers.
	open func recenterScrollableArea() {
		if let infiniteClipView = scrollView.contentView as? InfiniteClipView {
			infiniteClipView.recenterClipView()
		}
	}
	
	
	@objc fileprivate class ScrollViewDelegate: NSObject {
//		var decelerationRetargetingHandler: ((_ velocity: Point, _ decelerationTarget: Point) -> Point)?
		var didScrollHandler: (() -> ())?
		var willBeginMagnifyingHandler: (() -> ())?
		var didEndMagnifyingHandler: (() -> ())?
		
		@objc func scrollViewDidScroll(notification: NSNotification) {
			didScrollHandler?()
		}
		
		@objc func scrollViewWillBeginLiveMagnification(notification: NSNotification) {
			willBeginMagnifyingHandler?()
		}
		
		@objc func scrollViewDidEndLiveMagnification(notification: NSNotification) {
			didEndMagnifyingHandler?()
		}
	}
	
	
	fileprivate class InteractionHandlingScrollView: SystemScrollView, InteractionHandling, ExternalDragAndDropHandling {

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
			if let handler = keyDownHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return
				case .unhandled: break
				}
			}
			return super.flagsChanged(with: event)
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
		
		// MARK: File Drag and Drop
		
		// very much WIP. For now I really only care about handling dropped local images
		var draggingEnteredHandler: ExternalDragAndDropHandler?
		override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
			if let draggingEnteredHandler = draggingEnteredHandler {
				let pasteboard = sender.draggingPasteboard()
				if pasteboard.canReadObject(forClasses: [NSURL.self], options: [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes : NSImage.imageTypes]) {
					return .copy
				}
				return draggingEnteredHandler(ExternalDragAndDropInfo(draggingInfo: sender)).systemDragOperation
			}
			return NSDragOperation()
		}
		
		override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
			return true
		}
		
		var externalImagesDroppedHandler: Layer.ExternalImagesDroppedHandler?
		override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
			
			guard let externalImagesDroppedHandler = externalImagesDroppedHandler else {
				return false
			}
			
			// todo: move this logic into my DraggingInfo wrapper?
			let dragCenterInLocalCoordinates = convert(sender.draggingLocation(), from: nil)
			if let urls = sender.draggingPasteboard().readObjects(forClasses: [NSURL.self], options: [.urlReadingContentsConformToTypes: NSImage.imageTypes]) as? [URL], urls.count > 0 {
//				print(urls)
				return externalImagesDroppedHandler(urls, Point(dragCenterInLocalCoordinates))
			}
			
			return false
		}
	}
	
	/// Heavily based on https://github.com/helftone/infinite-nsscrollview
	private class InfiniteClipView: NSClipView {
		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
			wantsLayer = true
			postsBoundsChangedNotifications = true
			NotificationCenter.default.addObserver(self, selector: #selector(InfiniteClipView.viewGeometryChanged(notification:)), name: NSView.boundsDidChangeNotification, object: self)
			NotificationCenter.default.addObserver(self, selector: #selector(InfiniteClipView.viewGeometryChanged(notification:)), name: NSView.frameDidChangeNotification, object: self)
		}
		
		required init?(coder decoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		@objc private func viewGeometryChanged(notification: Notification) {
			
			if clipRecenterOffset() != nil {
				// We cannot perform recentering from within the notification (it's synchronous)
				// due to a bug in NSScrollView.
				scheduleRecenter()
			}
			infiniteDocumentView.layoutDocumentView()
		}
		
		private var infiniteDocumentView: InfiniteScrollingDocumentView {
			return documentView as! InfiniteScrollingDocumentView
		}
		
		private var scrollMagnification: CGFloat {
			return (superview! as! NSScrollView).magnification
		}
		
		/// A recenter is performed whenever the clipview gets close to the edge,
		/// so that we avoid bouncing and breaking the illusion of an infinite scrollview.
		func recenterClipView() {
			guard let clipRecenterOffset = self.clipRecenterOffset() else { return }
			
			inRecenter = true
			
			// We need to add the negative clip offset to the doc view
			// so that the content moves in the right direction.
			var recenterDocBounds = documentView!.bounds
			recenterDocBounds.origin.x -= clipRecenterOffset.x
			recenterDocBounds.origin.y -= clipRecenterOffset.y
			documentView?.setBoundsOrigin(recenterDocBounds.origin)
			
			let clipBounds = bounds
			var recenterClipOrigin = clipBounds.origin
			recenterClipOrigin.x += clipRecenterOffset.x
			recenterClipOrigin.y += clipRecenterOffset.y
			
			setBoundsOrigin(recenterClipOrigin)
			
			inRecenter = false
			
		}
		
		private func clipRecenterOffset() -> CGPoint? {
			// The threshold needs to be larger than the maximum single scroll distance (otherwise the scroll edge will be hit).
			// Through experimentation, all values stayed below 500.0.
			// jb: Upon more testing, this might need to change when we're zoomed. Not sure yet.
			let recenterThreshold: CGFloat = 500.0
			
			let docFrame = documentView!.frame
			let clipBounds = bounds
			
			// Compute the distances to the edges, if any of these values gets less than or equal to zero,
			// then the scroll view edge has been hit and the recenter threshold has to be increased
			let minHorizontalDistance = clipBounds.minX - docFrame.minX
			let maxHorizontalDistance = docFrame.maxX - clipBounds.maxX
			// not sure about vertical, given I use a flipped view
			let minVerticalDistance = clipBounds.minY - docFrame.minY
			let maxVerticalDistance = docFrame.maxY - clipBounds.maxY
			
			
			if minHorizontalDistance < recenterThreshold ||
				maxHorizontalDistance < recenterThreshold ||
				minVerticalDistance < recenterThreshold ||
				maxVerticalDistance < recenterThreshold {
				
				// Compute the desired clip origin and then just return the offset from the current origin.
				var recenterClipOrigin = CGPoint.zero
				
				recenterClipOrigin.x = docFrame.minX + round((docFrame.width - clipBounds.width) / 2.0)
				recenterClipOrigin.y = docFrame.minY + round((docFrame.height - clipBounds.height) / 2.0)

				
				return CGPoint(x: recenterClipOrigin.x - clipBounds.origin.x, y: recenterClipOrigin.y - clipBounds.origin.y)
			}
			
			return nil
		}
		
		private var inRecenter = false
		private var recenterScheduled = false
		private func scheduleRecenter() {
			if inRecenter || recenterScheduled { return }
			recenterScheduled = true
			
			DispatchQueue.main.async { [weak self] in
				self?.recenterScheduled = false
				self?.recenterClipView()
			}
		}
		
		override func scroll(to newOrigin: NSPoint) {
			// NSScrollView implements smooth scrolling _only_ for mouse wheel events.
			// This happens inside scroll(to:) which will cache the call and subsequently update the bounds.
			// Unfortunately, if we recenter while in a smooth scroll, the scrollview will keep scrolling
			// but will not take into account the recenter.
			// Smooth scrolling can be disabled for an app using NSScrollAnimationEnabled.
			// In order to work around the issue, we just bypass smooth scrolling and directly scroll.
			// Note: we can't recenter from here. NSScrollView screws up if we use a trackpad.
			setBoundsOrigin(newOrigin)
		}
	}
	
	private class InfiniteScrollingDocumentView: NSView {
		func layoutDocumentView() {
			// todo: fill this out
		}
		
		override var isFlipped: Bool { return true }
	}
}

private extension ScrollLayer {
	
	/// Use this for any scrollView property change you want to be animatable.
	var animatableScrollView: SystemScrollView {
		return animatableView as! SystemScrollView
	}
}
