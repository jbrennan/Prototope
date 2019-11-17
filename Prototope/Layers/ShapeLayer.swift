//
//  ShapeLayer.swift
//  Prototope
//
//  Created by Jason Brennan on Mar-27-2015.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

#if os(iOS)
	import UIKit
	public typealias SystemBezierPath = UIBezierPath
#else
	import Cocoa
	public typealias SystemBezierPath = NSBezierPath
#endif

/** This layer represents a 2D shape, which is drawn from a list of Segments. This class is similar to the Paths in paper.js. */
open class ShapeLayer: Layer {
	
	
	/** Creates a circle with the given center and radius. */
	convenience public init(circleCenter: Point, radius: Double, parent: Layer? = nil, name: String? = nil) {
		self.init(ovalInRectangle: Rect(
			x: circleCenter.x - radius,
			y: circleCenter.y - radius,
			width: radius * 2,
			height: radius * 2), parent: parent, name: name)
	}
	
	
	/** Creates an oval within the given rectangle. */
	convenience public init(ovalInRectangle ovalRect: Rect, parent: Layer? = nil, name: String? = nil) {
		self.init(segments: Segment.segmentsForOvalInRect(ovalRect), closed: true, parent: parent, name: name)
	}
	
	
	/** Creates a rectangle with an optional corner radius. */
	convenience public init(rectangle: Rect, cornerRadius: Double = 0, parent: Layer? = nil, name: String? = nil) {
		self.init(segments: Segment.segmentsForRect(rectangle, cornerRadius: cornerRadius), closed: true, parent: parent, name: name)
	}
	
	
	/** Creates a line from two points. */
	convenience public init(lineFromFirstPoint firstPoint: Point, toSecondPoint secondPoint: Point, parent: Layer? = nil, name: String? = nil) {
		self.init(segments: Segment.segmentsForLineFromFirstPoint(firstPoint, secondPoint: secondPoint), parent: parent, name: name)
	}
	
	
	/** Creates a regular polygon path with the given number of sides. */
	convenience public init(polygonCenteredAtPoint centerPoint: Point, radius: Double, numberOfSides: Int, parent: Layer? = nil, name: String? = nil) {
		self.init(
			segments: Segment.segmentsForPolygonCenteredAtPoint(
				centerPoint,
				radius: radius,
				numberOfSides: numberOfSides
			),
			closed: true,
			parent: parent,
			name: name
		)
	}
	
	
	/** Initialize the ShapeLayer with a given path. */
	public init(segments: [Segment], closed: Bool = false, parent: Layer? = nil, name: String? = nil) {
		
		self.segments = segments
		self.closed = closed
		
		let path = ShapeLayer.bezierPathForSegments(segments, closedPath: closed)
		let bounds = Rect(path.cgPath.boundingBoxOfPath).nonInfinite()
		
		self._segmentPathCache = PathCache(path: path, renderPath: path, strokedPath: path.cgPath, bounds: bounds)
		
		super.init(parent: parent, name: name, viewClass: ShapeView.self, frame: bounds)
		
		let view = self.view as! ShapeView
		view.displayHandler = {
			// todo(jb): probably get rid of this mechanism.
			// but, I'd like to explore if it'll work (updating segments + bounds + position in this handler)
			// but for now, don't wait for the needs display loop, and just force the changes.
		}
		segmentsDidChange()
		self.shapeViewLayerStyleDidChange()
		pointInside = { [unowned self] point in
			let cgPoint = CGPoint(point)
			// See if the stroked path has the point, else try the normal (filled but non-expanded) path contains it.
			return self._segmentPathCache.strokedPath.contains(cgPoint) || self._segmentPathCache.path.contains(cgPoint)
		}
	}
	
	
	// MARK: - Segments
	
	/** A list of all segments of this path.
	Segments are in the **parent layer's** coordinate space, which feels similar to drawing tools, but is different from the default `CAShapeLayer` behaviour, which is ridiculous. */
	open var segments: [Segment] {
		didSet {
			segmentsDidChange()
		}
	}
	
	/** Private structure to hold a path and its bounds. */
	fileprivate struct PathCache {
		let path: SystemBezierPath

		/// A copy of `path` that's in the layer's local coordinate system (set on the CAShapeLayer)
		let renderPath: SystemBezierPath
		/// A copy of `path` that includes stroke width. Useful for hit testing.
		let strokedPath: CGPath // todo: this should be a `SystemBezierPath` but there's no easy way to convert cgpath -> nsbp on Mac.
		let bounds: Rect
		
		// I think I need to translate the stroke path by this offset when hit-testing.
		var strokedPathOffset: Point { return bounds.origin }
	}
	
	/** private cache of the bezier path and its bounds.
	Must be updated when the segments change. */
	fileprivate var _segmentPathCache: PathCache
	
	/// Empty segments result in a path with an infinite bounds.
	/// 1 segment does too (because the first segment is simply a "move to" instruction, which can't be rendered).
	private var segmentsCanBeRendered: Bool { segments.count > 1 }
	
	fileprivate func segmentsDidChange() {
		
		// essentially,
		// segments for the rect (x: 200, y: 200, width: 100, height: 100) should produce:
		// - a frame with the same rect (and position to match)
		// - those exact segments
		// - a bounds of 0, 0, 100, 100
		// and, moving that rect to say, 300, 300 (that is, moving the frame) should:
		// - move the segments accordingly
		// - keep the bounds the same
		// - also should not be allowed to change frame size
		
		// only do path math (heh) if we have segments. A zero segment path results in an infinite origin bounds :\
		let path = segmentsCanBeRendered ? ShapeLayer.bezierPathForSegments(segments, closedPath: closed) : SystemBezierPath()
		
		// get a copy of the path that's sized according to the stroke of the original path, or a minimum value so it's reasonably clickable.
		let minimumClickableStrokeWidth = 10.0
		let strokedPath = path.cgPath.copy(
			strokingWithWidth: CGFloat(max(strokeWidth, minimumClickableStrokeWidth)),
			lineCap: lineCapStyle.cgLineCap,
			lineJoin: lineJoinStyle.cgLineJoin,
			miterLimit: 1.0
		)
		let segmentBounds = segmentsCanBeRendered ? Rect(strokedPath.boundingBoxOfPath) : Rect()
		let renderPath = path.pathByTranslatingByDelta(segmentBounds.origin)
		self._segmentPathCache = PathCache(path: path, renderPath: renderPath, strokedPath: strokedPath, bounds: segmentBounds)

		shapeViewLayer.path = renderPath.cgPath
		
		self.frame = segmentBounds
	}
	
	/** Sets the layer's bounds. The given rect's size must match the size of the `segments`'s path's bounds.
	Generally speaking, you should not need to call this directly. */
	open override var bounds: Rect {
		get { return super.bounds }
		
		set {
			let pathBounds = _segmentPathCache.bounds
			
			precondition(newValue.size == pathBounds.size, "Attempting to set the shape layer's bounds to a size \(newValue.size) which doesn't match the path's size \(pathBounds.size).")
			
			super.bounds = newValue
		}
	}
	
	
	/** Sets the layer's position (by default, its centre point).
	Setting this has the effect of translating the layer's `segments` so they match the new geometry. */
	open override var position: Point {
		get { return super.position }
		
		set {
			let oldPosition = super.position
			super.position = newValue
			
			let pathBounds = _segmentPathCache.bounds
			
			if pathBounds.center != newValue {
				let positionDelta = newValue - oldPosition
				
				segments = segments.map {
					var segment = $0
					segment.point += positionDelta
					// todo: translate the handles, too
					return segment
				}
			}
		}
	}
	
	
	/** Sets the layer's frame. The given rect's size must match the size of the `segments`'s path's bounds.
	Setting this has the effect of translating the layer's `segments` so they match the new geometry. */
	open override var frame: Rect {
		get { return super.frame }
		
		set {
			
			let pathBounds = _segmentPathCache.bounds
			
			precondition(newValue.size == pathBounds.size, "Attempting to set the shape layer's frame to a size \(newValue.size) which doesn't match the path's size \(pathBounds.size).")
			
			let oldFrame = super.frame
			super.frame = newValue
			
			
			if pathBounds.center != newValue.center {
				let positionDelta = newValue.center - oldFrame.center
				
				segments = segments.map {
					var segment = $0
					segment.point += positionDelta
					return segment
				}
			}
		}
	}
	
	open override var origin: Point {
		get { return super.origin }
		set { frame.origin = newValue }
	}
	
	/** Gets the first segment of the path, if it exists. */
	open var firstSegment: Segment? {
		return segments.first
	}
	
	
	/** Gets the last segment of the path, if it exists. */
	open var lastSegment: Segment? {
		return segments.last
	}
	
	
	/** Convenience method to add a point by wrapping it in a segment. */
	open func addPoint(_ point: Point) {
		self.segments.append(Segment(point: point))
	}
	
	
	/** Redraws the path. You can call this after you change path segments. */
	fileprivate func setNeedsDisplay() {
		self.view.setNeedsDisplay()
	}
	
	
	// MARK: - Methods
	
	/** Returns if the the given point is enclosed within the shape. If the shape is not closed, this always returns `false`. */
	open func enclosesPoint(_ point: Point) -> Bool {
		if !self.closed {
			return false
		}
		
		let path = _segmentPathCache.path
		return path.contains(CGPoint(point))
	}

	/// Scales the receiver by the given `amount` in both the x and y axis.
	/// This scales all segments by the given amount, and thus also updates the receiver's `frame` and related properties.
	///
	/// This is different from applying a scale to a normal layer (where the scale is only visual).
	open func scale(by amount: Double) {
		let transform = CGAffineTransform(scaleX: CGFloat(amount), y: CGFloat(amount))
		segments = segments.map({
			Segment(
				point: $0.point.applying(transform: transform),
				handleIn: $0.handleIn?.applying(transform: transform),
				handleOut: $0.handleOut?.applying(transform: transform)
			)
		})
	}
	
	
	// MARK: - Properties
	
	/** The fill colour for the shape. Defaults to `Color.black`. This is distinct from the layer's background colour. */
	open var fillColor: Color? = Color.black {
		didSet {
			shapeViewLayerStyleDidChange()
		}
	}
	
	
	/** The stroke colour for the shape. Defaults to `Color.black`. */
	open var strokeColor: Color? = Color.black {
		didSet {
			shapeViewLayerStyleDidChange()
		}
	}
	
	
	/** The width of the stroke. Defaults to 1.0. */
	open var strokeWidth = 1.0 {
		didSet {
			shapeViewLayerStyleDidChange()
		}
	}
	
	
	/** If the path is closed, the first and last segments will be connected. */
	open var closed: Bool {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	
	/** The dash length of the layer's stroke. This length is used for both the dashes and the space between dashes. Draws a solid stroke when nil. */
	open var dashLength: Double? {
		didSet {
			shapeViewLayerStyleDidChange()
		}
	}
	
	
	/** Represents the types of cap styles path segment endpoints will show. Only affects open paths. */
	public enum LineCapStyle {
		
		/** The line cap will have butts for ends. */
		case butt
		
		/** The line cap will have round ends. */
		case round
		
		/** The line cap will have square ends. */
		case square
		
		func capStyleString() -> String {
			switch self {
			case .butt:
				return convertFromCAShapeLayerLineCap(CAShapeLayerLineCap.butt)
			case .round:
				return convertFromCAShapeLayerLineCap(CAShapeLayerLineCap.round)
			case .square:
				return convertFromCAShapeLayerLineCap(CAShapeLayerLineCap.square)
			}
		}
		
		fileprivate var cgLineCap: CGLineCap {
			switch self {
			case .butt: return .butt
			case .round: return .round
			case .square: return .square
			}
		}
	}
	
	
	/** The line cap style for the path. Defaults to LineCapStyle.Butt. */
	open var lineCapStyle: LineCapStyle = .butt {
		didSet {
			shapeViewLayerStyleDidChange()
		}
	}
	
	
	/** Represents the types of join styles path segments will show at their joins. */
	public enum LineJoinStyle {
		
		/** Lines will be joined with a miter style. */
		case miter
		
		/** Lines will be joined with a round style. */
		case round
		
		/** Line joins will have beveled edges. */
		case bevel
		
		func joinStyleString() -> String {
			switch self {
			case .miter: return convertFromCAShapeLayerLineJoin(CAShapeLayerLineJoin.miter)
			case .round: return convertFromCAShapeLayerLineJoin(CAShapeLayerLineJoin.round)
			case .bevel: return convertFromCAShapeLayerLineJoin(CAShapeLayerLineJoin.bevel)
			}
		}
		
		fileprivate var cgLineJoin: CGLineJoin {
			switch self {
			case .miter: return .miter
			case .round: return .round
			case .bevel: return .bevel
			}
		}
	}
	
	
	/** The line join style for path lines. Defaults to LineJoinStyle.Miter. */
	open var lineJoinStyle: LineJoinStyle = .miter {
		didSet {
			shapeViewLayerStyleDidChange()
		}
	}
	
	#if os(iOS)
	// TODO: Remove this override when custom layers can inherit all the view-related Layer stuff properly.
	open override var pointInside: ((Point) -> Bool)? {
	get { return shapeView.pointInside }
	set { shapeView.pointInside = newValue }
	}
	#endif
	
	
	// MARK: - Private details
	
	fileprivate var shapeViewLayer: CAShapeLayer {
		return self.view.layer as! CAShapeLayer
	}
	
	fileprivate var shapeView: ShapeView {
		return self.view as! ShapeView
	}
	
	
	fileprivate class ShapeView: SystemView, InteractionHandling, DraggableView {
		var displayHandler: (() -> Void)?
		
		#if os(iOS)
		override class var layerClass : AnyClass {
			return CAShapeLayer.self
		}
		
		@objc override func display(_ layer: CALayer) {
			self.displayHandler?()
		}



		override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
			
			func defaultPointInsideImplementation(point: CGPoint, event: UIEvent?) -> Bool {
				// Try to hit test the presentation layer instead of the model layer.
				if let presentationLayer = layer.presentation() {
					let screenPoint = layer.convert(point, to: nil)
					let presentationLayerPoint = presentationLayer.convert(screenPoint, from: nil)
					return super.point(inside: presentationLayerPoint, with: event)
				} else {
					return super.point(inside: point, with: event)
				}
			}
			
			// see if the point is inside according to the default implementation
			let defaultPointInside = defaultPointInsideImplementation(point: point, event: event)
			
			// if we have a custom impl of pointInside call it, if and only if the default implementation failed.
			if let pointInside = pointInside , defaultPointInside == false {
				return pointInside(Point(point))
			} else {
				return defaultPointInside
			}
		}
		#else

		override var isFlipped: Bool { return true }

		override func makeBackingLayer() -> CALayer {
			return CAShapeLayer()
		}

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
			if let pointInside = pointInside {
				if pointInside(Point(point)) {
					return super.hitTest(point)
				} else {
					return nil
				}
			}
			return super.hitTest(point)
		}
		
		override var acceptsFirstResponder: Bool {
			return keyEquivalentHandler != nil
		}
		
		var dragBehavior: DragBehavior?
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
			let locationInView = convert(event.locationInWindow, from: nil)
			dragBehavior?.dragDidBegin(atLocationInLayer: Point(locationInView))
			mouseDownHandler?(InputEvent(event: event))
		}
		
		override func mouseMoved(with event: NSEvent) {
			mouseMovedHandler?(InputEvent(event: event))
		}
		
		override func mouseUp(with event: NSEvent) {
			mouseUpHandler?(InputEvent(event: event))
			dragBehavior?.dragDidEnd()
		}
		
		override func mouseDragged(with event: NSEvent) {
			let locationInSuperView = superview!.convert(event.locationInWindow, from: nil)
			dragBehavior?.dragDidChange(atLocationInParentLayer: Point(locationInSuperView))
			mouseDraggedHandler?(InputEvent(event: event))
		}
		
		override func mouseEntered(with event: NSEvent) {
			mouseEnteredHandler?(InputEvent(event: event))
		}
		
		override func mouseExited(with event: NSEvent) {
			mouseExitedHandler?(InputEvent(event: event))
		}
		#endif
		
		override func setNeedsDisplay() {
			// The UIKit implementation (reasonably) won't call through to `CALayer` if you don't implement `drawRect:`, so we do it ourselves.
			#if os(iOS)
				self.layer.setNeedsDisplay()
			#else
				self.layer?.setNeedsDisplay()
			#endif
		}
		
		
	}
	
	
	fileprivate func shapeViewLayerStyleDidChange() {
		let layer = self.shapeViewLayer
		layer.lineCap = convertToCAShapeLayerLineCap(self.lineCapStyle.capStyleString())
		layer.lineJoin = convertToCAShapeLayerLineJoin(self.lineJoinStyle.joinStyleString())
		
		if let fillColor = fillColor {
			layer.fillColor = fillColor.CGColor
		} else {
			layer.fillColor = nil
		}
		
		
		if let strokeColor = strokeColor {
			layer.strokeColor = strokeColor.CGColor
		} else {
			layer.strokeColor = nil
		}
		
		
		if let dashLength = dashLength {
			layer.lineDashPattern = [NSNumber(value: dashLength), NSNumber(value: dashLength)]
		} else {
			layer.lineDashPattern = []
		}
		
		layer.lineWidth = CGFloat(strokeWidth)
	}
	
	
	fileprivate static func bezierPathForSegments(_ segments: [Segment], closedPath: Bool) -> SystemBezierPath {
		
		/*	This is modelled on paper.js' implementation of path rendering.
		While iterating through the segments, this checks to see if a line or a curve should be drawn between them.
		Each segment has an optional handleIn and handleOut, which act as control points for curves on either side.
		See https://github.com/paperjs/paper.js/blob/1803cd216ae6b5adb6410b5e13285b0a7fc04526/src/path/Path.js#L2026
		*/
		
		let bezierPath = SystemBezierPath()
		var isFirstSegment = true
		var currentPoint = Point()
		var previousPoint = Point()
		var currentHandleIn = Point()
		var currentHandleOut = Point()
		
		func drawSegment(_ segment: Segment) {
			currentPoint = segment.point
			
			if isFirstSegment {
				bezierPath.move(to: CGPoint(currentPoint))
				isFirstSegment = false
			} else {
				if let segmentHandleIn = segment.handleIn {
					currentHandleIn = currentPoint + segmentHandleIn
				} else {
					currentHandleIn = currentPoint
				}
				
				
				if currentHandleIn == currentPoint && currentHandleOut == previousPoint {
					bezierPath.addLine(to: CGPoint(currentPoint))
				} else {
					bezierPath.addCurve(to: CGPoint(currentPoint), controlPoint1: CGPoint(currentHandleOut), controlPoint2: CGPoint(currentHandleIn))
				}
			}
			
			previousPoint = currentPoint
			if let segmentHandleOut = segment.handleOut {
				currentHandleOut = previousPoint + segmentHandleOut
			} else {
				currentHandleOut = previousPoint
			}
			
		}
		for segment in segments {
			drawSegment(segment)
		}
		
		if closedPath && segments.count > 0 {
			drawSegment(segments[0])
			bezierPath.close()
		}
		
		return bezierPath
	}
	
}

// MARK: - Segments

/** A segment represents a point on a path, and may optionally have control handles for a curve on either side. */
public struct Segment: CustomStringConvertible {
	
	/** The anchor point / location of this segment. */
	public var point: Point
	
	
	/** The control point going in to this segment, used when computing curves. */
	public var handleIn: Point?
	
	/** The control point coming out of this segment, used when computing curves. */
	public var handleOut: Point?
	
	
	/** Initialize a segment with the given point and optional handle points. */
	public init(point: Point, handleIn: Point? = nil, handleOut: Point? = nil) {
		self.point = point
		self.handleIn = handleIn
		self.handleOut = handleOut
	}
	
	public var description: String {
		return self.point.description
	}
}


/** Convenience functions for creating shapes. */
public extension Segment {
	
	// Magic number for approximating ellipse control points.
	fileprivate static let kappa = 4.0 * (sqrt(2.0) - 1.0) / 3.0
	
	/** Creates a set of segments for drawing an oval in the given rect. Algorithm based on paper.js */
	static func segmentsForOvalInRect(_ rect: Rect) -> [Segment] {
		
		let kappaSegments = [
			Segment(point: Point(x: -1.0, y: 0.0), handleIn: Point(x: 0.0, y: kappa), handleOut: Point(x: 0.0, y: -kappa)),
			Segment(point: Point(x: 0.0, y: -1.0), handleIn: Point(x: -kappa, y: 0.0), handleOut: Point(x: kappa, y: 0.0)),
			Segment(point: Point(x: 1.0, y: 0.0), handleIn: Point(x: 0.0, y: -kappa), handleOut: Point(x: 0.0, y: kappa)),
			Segment(point: Point(x: 0.0, y: 1.0), handleIn: Point(x: kappa, y: 0.0), handleOut: Point(x: -kappa, y: 0.0))
		]
		
		var segments = [Segment]()
		let radius = Point(x: rect.size.width / 2.0, y: rect.size.height / 2.0)
		let center = rect.center
		
		for index in 0..<kappaSegments.count {
			let kappaSegment = kappaSegments[index]
			
			let point = kappaSegment.point * radius + center
			let handleIn = kappaSegment.handleIn! * radius
			let handleOut = kappaSegment.handleOut! * radius
			
			segments.append(Segment(point: point, handleIn: handleIn, handleOut: handleOut))
		}
		return segments
	}
	
	/// Creates a set of segments for drawing a circle centred at the given point with the given radius.
	static func segmentsFor(circleCenter: Point, radius: Double) -> [Segment] {
		return segmentsForOvalInRect(Rect(
			x: circleCenter.x - radius,
			y: circleCenter.y - radius,
			width: radius * 2,
			height: radius * 2))
	}
	
	
	/** Creates a set of segments for drawing a rectangle, optionally with a corner radius. Algorithm based on paper.js */
	static func segmentsForRect(_ rect: Rect, cornerRadius radius: Double) -> [Segment] {
		var segments = [Segment]()
		
		let topLeft = rect.origin
		let topRight = Point(x: rect.maxX, y: rect.minY)
		let bottomRight = Point(x: rect.maxX, y: rect.maxY)
		let bottomLeft = Point(x: rect.minX, y: rect.maxY)
		
		
		if radius <= 0.0 {
			segments.append(Segment(point: topLeft))
			segments.append(Segment(point: topRight))
			segments.append(Segment(point: bottomRight))
			segments.append(Segment(point: bottomLeft))
		} else {
			let handle = radius * kappa
			
			segments.append(Segment(point: bottomLeft + Point(x: radius, y: 0.0), handleIn: nil, handleOut: Point(x: -1.0 * handle, y: 0)))
			segments.append(Segment(point: bottomLeft - Point(x: 0.0, y: radius), handleIn: Point(x: 0.0, y: handle), handleOut: nil))
			
			segments.append(Segment(point: topLeft + Point(x: 0.0, y: radius), handleIn: nil, handleOut: Point(x: 0.0, y: -1.0 * handle)))
			segments.append(Segment(point: topLeft + Point(x: radius, y: 0.0), handleIn: Point(x: -handle, y: 0.0), handleOut: nil))
			
			segments.append(Segment(point: topRight - Point(x: radius, y: 0.0), handleIn: nil, handleOut: Point(x: handle, y: 0)))
			segments.append(Segment(point: topRight + Point(x: 0.0, y: radius), handleIn: Point(x: 0.0, y: -handle), handleOut: nil))
			
			segments.append(Segment(point: bottomRight - Point(x: 0.0, y: radius), handleIn: nil, handleOut: Point(x: 0.0, y: handle)))
			segments.append(Segment(point: bottomRight - Point(x: radius, y: 0.0), handleIn: Point(x: handle, y: 0), handleOut: nil))
			
		}
		return segments
	}
	
	
	/** Segments for a line. Algorithm based on something I just made up. */
	static func segmentsForLineFromFirstPoint(_ firstPoint: Point, secondPoint: Point) -> [Segment] {
		return [Segment(point: firstPoint), Segment(point: secondPoint)]
	}
	
	
	/** Segments for a polygon with the given number of sides. Must be >= 3 sides or else funnybusiness ensues. */
	static func segmentsForPolygonCenteredAtPoint(_ centerPoint: Point, radius: Double, numberOfSides: Int) -> [Segment] {
		var segments = [Segment]()
		
		if numberOfSides < 3 {
			Environment.currentEnvironment?.exceptionHandler("Please use at least 3 sides for your polygon (you used \(numberOfSides))")
			return segments
		}
		
		let angle = Radian(degrees: 360.0 / Double(numberOfSides))
		let fixedRotation = -(Double.pi / 2) // By decree (and appeal to aesthetics): there should always be a vertex on top.
		
		for index in 0..<numberOfSides {
			let x = centerPoint.x + radius * cos(angle * Double(index) + fixedRotation)
			let y = centerPoint.y + radius * sin(angle * Double(index) + fixedRotation)
			segments.append(Segment(point: Point(x: x, y: y)))
		}
		
		return segments
	}
}

// MARK: - Bezier Path helpers

extension SystemBezierPath {
	
	/** Returns a copy of `path`, translated negatively by the given delta. */
	func pathByTranslatingByDelta(_ delta: Point) -> SystemBezierPath {
		let deltaCGPoint = CGPoint(delta)
		let translatedPath = self.copy() as! SystemBezierPath
		#if os(iOS)
			translatedPath.apply(CGAffineTransform(translationX: -deltaCGPoint.x, y: -deltaCGPoint.y))
		#else
			translatedPath.transform(using: AffineTransform(translationByX: -deltaCGPoint.x, byY: -deltaCGPoint.y))
		#endif
		return translatedPath
	}
	
}

#if os(macOS)
	extension SystemBezierPath {
		func addLine(to point: CGPoint) {
			line(to: point)
		}
		
		func addCurve(to point: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
			curve(to: point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
		}
		
		public var cgPath: CGPath {
			let path = CGMutablePath()
			var points = [CGPoint](repeating: .zero, count: 3)
			for i in 0 ..< self.elementCount {
				let type = self.element(at: i, associatedPoints: &points)
				switch type {
				case .moveTo:
					path.move(to: CGPoint(x: points[0].x, y: points[0].y) )
				case .lineTo:
					path.addLine(to: CGPoint(x: points[0].x, y: points[0].y) )
				case .curveTo:
					// For curveToBezierPath, the points array above comes in as:
					// [cp1, cp2, endPoint], that's why points[2] is the first arg.
					path.addCurve(to: points[2], control1: points[0], control2: points[1])
				case .closePath:
					path.closeSubpath()
				}
			}
			return path
		}
	}
#endif

// MARK: - Clipping Shapes and Paths

extension Image {
	public func clipped(by path: SystemBezierPath) -> Image {
		
		// todo: this method is currently broken:
		// - it generates an image as large as the source image, which is logical but not desirable.
		//		- should shrink the image down to be the size of the path's bounds.
		//		- turns out this is tricky!!!!

		let image = NSImage(size: CGSize(size))
		
		image.lockFocusFlipped(true)
		
		NSGraphicsContext.current?.imageInterpolation = .high
		let pathCopy = path.copy() as! SystemBezierPath

		pathCopy.addClip()

		let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
		systemImage.draw(
			in: frame,
			from: frame,
			operation: .sourceOver,
			fraction: 1,
			respectFlipped: true,
			hints: nil
		)
		
		image.unlockFocus()
		return Image(image)
	}
	
//	public func clipped(by shapeLayer: ShapeLayer) -> Image {
//		// might have to use the "render path" not sure yet..
//		clipped(by: shapeLayer._segmentPathCache.path)
//	}
}

extension Layer {
	public func clipped(by shapeLayer: ShapeLayer) -> Layer {
		let image = self.image!
		
		// todo: this assumes they're both in the same coordinate space!! too sleepy to figure it out tonight
		// think I just gotta convert self's origin into shapeLayer's coordinate space, then I should be ok
		let path = shapeLayer._segmentPathCache.renderPath

		// hmmm, that's not quite right. it's off by a few pixels
		let convertedOrigin = shapeLayer.convert(point: origin, from: self.parent!)
//		print("origin: \(origin) convertedOrigin: \(convertedOrigin)")
		let offsetPath = path.pathByTranslatingByDelta(convertedOrigin) // broken, use origin instead (when both are in same coordinate space)
//		print("shapePathBoundsOrigin: \(path.bounds.origin) convertedPathOrigin: \(offsetPath.bounds.origin)")
		
		let clipped = Layer(parent: nil, image: image.clipped(by: offsetPath))
		clipped.origin = origin
		clipped.border = Border(color: .blue, width: 2)
		
		return clipped
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCAShapeLayerLineCap(_ input: CAShapeLayerLineCap) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCAShapeLayerLineJoin(_ input: CAShapeLayerLineJoin) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAShapeLayerLineCap(_ input: String) -> CAShapeLayerLineCap {
	return CAShapeLayerLineCap(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAShapeLayerLineJoin(_ input: String) -> CAShapeLayerLineJoin {
	return CAShapeLayerLineJoin(rawValue: input)
}
