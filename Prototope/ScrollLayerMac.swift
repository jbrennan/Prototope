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
		self.documentView = SystemView(frame: CGRect())
		super.init(parent: parent, name: name, viewClass: SystemScrollView.self)
		scrollView.documentView = documentView
//		scrollView.delegate = scrollViewDelegate
	}
	
	deinit {
//		scrollView.delegate = nil
	}
	
	var scrollView: SystemScrollView {
		return self.view as! SystemScrollView
	}
	private let documentView: SystemView
	
	// This causes ScrollLayer's sublayers to be added to the scroll view's documentView, so they can be scrolled.
	override var childHostingView: SystemView? {
		return self.documentView
	}

	
	// MARK: - Properties
	
	/** The scroll position of the scroll layer in its own coordinates. */
	public var scrollPosition: Point {
		get { return Point(self.documentView.bounds.origin) }
		set { self.documentView.bounds.origin = CGPoint(newValue) }
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
	
//	/** This handler provides an opportunity to change the way a scroll layer decelerates.
//	
//	It will be called when the user lifts their finger from the scroll layer. The system will provide the user's velocity (in points per second) when they lifted their finger, along with a computed deceleration target (i.e. the point where the scroll view will stop decelerating). If you specify a non-nil handler, the point you return from this handler will be used as the final deceleration target for a decelerating scroll layer. You can return the original deceleration target if you don't need to modify it. **/
//	open var decelerationRetargetingHandler: ((_ velocity: Point, _ decelerationTarget: Point) -> Point)? {
//		get { return scrollViewDelegate.decelerationRetargetingHandler }
//		set { scrollViewDelegate.decelerationRetargetingHandler = newValue }
//	}
//	
//	
//	/** This handler is called when the scrollView scrolls. */
//	open var didScrollHandler: (() -> ())? {
//		didSet {
//			self.scrollViewDelegate.didScrollHandler = didScrollHandler
//		}
//	}
	
	
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
	
	
//	@objc fileprivate class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
//		var decelerationRetargetingHandler: ((_ velocity: Point, _ decelerationTarget: Point) -> Point)?
//		var didScrollHandler: (() -> ())?
//		
//		@objc func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//			if let decelerationRetargetingHandler = decelerationRetargetingHandler {
//				let newTargetContentOffset = decelerationRetargetingHandler(Point(velocity), Point(targetContentOffset.pointee))
//				targetContentOffset.pointee = CGPoint(newTargetContentOffset)
//			}
//		}
//		
//		@objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
//			if let didScrollHandler = self.didScrollHandler {
//				didScrollHandler()
//			}
//		}
//	}
}
