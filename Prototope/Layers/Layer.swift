//
//  Layer.swift
//  Prototope
//
//  Created by Andy Matuschak on 10/3/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//


#if os(iOS)
	import UIKit
	public typealias SystemView = UIView
	#else
	import AppKit
	public typealias SystemView = NSView
#endif

/**
	Layers are the fundamental building block of Prototope.

	A layer displays content (a color, an image, etc.) and can route touch events.

	Layers are stored in a tree. It's possible to make a layer without a parent, but
	only layers in the tree starting at Layer.root will be displayed.

	An example of making a red layer, ready for display:

		let redLayer = Layer(parent: Layer.root)
		redLayer.backgroundColor = Color.red
		redLayer.frame = Rect(x: 50, y: 50, width: 100, height: 100)
*/
open class Layer: Equatable {

	// MARK: Creating and identifying layers

	/** The root layer of the scene. Defines the global coordinate system. */
	open class var root: Layer! { return Environment.currentEnvironment?.rootLayer }

	/** Creates a layer with an optional parent and name. */
	public init(parent: Layer? = Layer.root, name: String? = nil, viewClass: SystemView.Type? = nil, frame: Rect? = nil) {
		self.parent = parent ?? Layer.root
		self.name = name

		if let viewClass = viewClass {
			self.view = viewClass.init()
			#if os(macOS)
			self.view.wantsLayer = true
			#endif
		} else {
			self.view = TouchForwardingImageView() // TODO: dynamically switch the view type depending on whether we're using an image or not
		}
		
		#if os(iOS)
			self.view.isMultipleTouchEnabled = true
			self.view.isUserInteractionEnabled = true
		#else
			view.layerContentsRedrawPolicy = .onSetNeedsDisplay
		#endif

		self.parentDidChange()

		self.frame = frame ?? Rect(x: 0, y: 0, width: 100, height: 100)
	}

	/** Convenience initializer; makes a layer which displays an image by name.
		The layer will adopt its size from the image and its name from imageName. */
	public convenience init(parent: Layer?, imageName: String) {
		self.init(parent: parent, name: imageName)
		self.image = Image(name: imageName)
		imageDidChange()
	}
	
	
	/** Convenience initializer; makes a layer which displays the given image.
		The layer will adopt its size from the image. */
	public convenience init(parent: Layer?, image: Image) {
		self.init(parent: parent, name: image.name)
		self.image = image
		
		imageDidChange()
	}
	

	/** Creates a Prototope Layer by wrapping a CALayer. The result may not have
	access to all the normal Prototope functionality--beware! You should mostly
	control this Layer via CALayer's APIs, not Prototope's. */
	public convenience init(wrappingCALayer: CALayer, name: String? = nil) {
		let wrappingView = CALayerWrappingView(wrappedLayer: wrappingCALayer)
		self.init(wrappingView: wrappingView, name: name)
	}

	/** Layers have an optional name that can be used to find them via various
		convenience methods. Defaults to nil. */
	public let name: String?
	
	/// Extra storage for quickly adding data to a Layer, without needing to subclass it.
	open var properties = [String: Any]()

	// MARK: Layer hierarchy access and manipulation

	/** The layer's parent layer. The parent layer will be nil when the layer is
		not attached to a hierarchy, or when the receiver is the root layer.

		Setting this property will move the layer to a new parent (or remove it
		from the layer hierarchy if you set the parent to nil. */
	open weak var parent: Layer? {
		willSet {
			if let parent = self.parent {
				parent.sublayers.remove(at: parent.sublayers.index(of: self)!)
				view.removeFromSuperview()
			}
		}
		didSet {
			parentDidChange()
		}
	}

	/** An array of all this layer's sublayers. */
	open fileprivate(set) var sublayers: [Layer] = []

	/** Removes all of the receivers' sublayers from the hierarchy. */
	open func removeAllSublayers() {
		// TODO: This could be way faster.
		for sublayer in sublayers {
			sublayer.parent = nil
		}
	}
	
	#if os(iOS)
	/** Brings the layer to the front of all sibling layers. */
	open func comeToFront() {
		if let parentView = self.parentView {
			parentView.bringSubview(toFront: self.view)
			self.parent!.sublayers.insert(self.parent!.sublayerAtFront!, at: 0)
		}
	}
	
	/** Sends the layer to the back of all sibling layers. */
	open func sendToBack() {
		if let parentView = self.parentView {
			parentView.sendSubview(toBack: self.view)
			self.parent!.sublayers.insert(self.parent!.sublayers.first!, at: self.parent!.sublayers.count - 1)
		}
	}
	#else
	public func comeToFront() {
		if let parentView = self.parentView {
			
			parentView.sortSubviews({ (view1, view2, pointer) -> ComparisonResult in
				let viewOnTop = pointer?.assumingMemoryBound(to: SystemView.self).pointee
				if view1 === viewOnTop {
					return ComparisonResult.orderedDescending
				} else if view2 === viewOnTop {
					return ComparisonResult.orderedAscending
				}
				
				return ComparisonResult.orderedSame
			}, context: UnsafeMutableRawPointer.init(&view))
			
		}
	}
	
	public func sendToBack() {
		if let parentView = self.parentView {
			
			parentView.sortSubviews({ (view1, view2, pointer) -> ComparisonResult in
				let viewOnBottom = pointer?.assumingMemoryBound(to: SystemView.self).pointee
				if view1 === viewOnBottom {
					return ComparisonResult.orderedAscending
				} else if view2 === viewOnBottom {
					return ComparisonResult.orderedDescending
				}
				
				return ComparisonResult.orderedSame
			}, context: UnsafeMutableRawPointer.init(&view))
			
		}
	}
	#endif

	/** Returns the sublayer which will be visually ordered to the front. */
	open var sublayerAtFront: Layer? { return sublayers.last }

	/** Returns the sublayer whose name matches the argument, or nil if it is not found. */
	open func sublayerNamed(_ name: String) -> Layer? {
		return sublayers.filter{ $0.name == name }.first
	}

	/** Returns the descendent (at any level) whose name matches the argument, or nil
		if it is not found. */
	open func descendentNamed(_ name: String) -> Layer? {
		if self.name == name {
			return self
		}

		for sublayer in sublayers {
			if let match = sublayer.descendentNamed(name) {
				return match
			}
		}

		return nil
	}

	/** Attempts to find a layer at a particular named path by calling sublayerNamed
		once at each level, for each element in pathElements. Returns nil if not found.

		Example:
			let a = Layer()
			let b = Layer(parent: a, name: "foo")
			let c = Layer(parent: b, name: "bar")
			a.descendentAtPath(["foo", "bar"]) // returns c
			a.descendentAtPath(["foo", "quux"]) // returns nil */
	open func descendentAtPath(_ pathElements: [String]) -> Layer? {
		return pathElements.reduce(self) { $0?.sublayerNamed($1) }
	}

	/** Attempts to find a layer in the series of parent layers between the receiver and
		the root layer which has a given name. Returns nil if none is found. */
	open func ancestorNamed(_ name: String) -> Layer? {
		var currentLayer = parent
		while currentLayer != nil {
			if currentLayer!.name == name {
				return currentLayer
			}
			currentLayer = currentLayer!.parent
		}
		return nil
	}

    /** Sets the zPosition of the layer. Higher values go towards the screen as the
        z axis increases towards your face. Measured in points and defaults to 0.
        Animatable, but not yet with dynamic animators. */
    open var zPosition: Double {
		get { return Double(layer.zPosition) }
		set { layer.zPosition = CGFloat(newValue) }
	}

	// MARK: Geometry

	/** The x position of the layer's anchor point (by default the center), relative to
		the origin of its parent layer and expressed in the parent coordinate space.
		Animatable. */
	open var x: Double {
		get { return position.x }
		set { position.x = newValue }
	}

	/** The y position of the layer's anchor point (by default the center), relative to
		the origin of its parent layer and expressed in the parent coordinate space.
		Animatable. */
	open var y: Double {
		get { return position.y }
		set { position.y = newValue }
	}

    /** The position of the layer's origin point (the upper left-hand corner), 
        relative to the origin of its parent layer and expressed in the parent coordinate space. */
	#if os(iOS) // TODO(jb): Why can't I put this #if block inside the var declaration?
    open var origin: Point {
        get { return frame.origin }
        set { frame.origin = newValue }
	}
	#else
	public var origin: Point {
		get { return Point(view.frame.origin) }
		set { animatableView.frame.origin = (CGPoint(newValue)) }
    }
	#endif

	/** The position of the layer's anchor point (by default the center), relative to the
		origin of its parent layer and expressed in the parent coordinate space.
		Animatable. */
	#if os(iOS)
	open var position: Point {
		get { return Point(layer.position) }
		set { layer.position = CGPoint(newValue) }
	}
	#else
	public var position: Point {
		get { return view.frameCenter }
		set { animatableView.frameCenter = newValue }
	}
	#endif
	

	/** The layer's width, expressed in its own coordinate space. Animatable (but not yet
		via the dynamic animators). */
	open var width: Double {
		get { return bounds.size.width }
		set { bounds.size.width = newValue }
	}

	/** The layer's height, expressed in its own coordinate space. Animatable (but not yet
		via the dynamic animators). */
	open var height: Double {
		get { return bounds.size.height }
		set { bounds.size.height = newValue }
	}

	/** The layer's size, expressed in its own coordinate space. Animatable. */
	#if os(iOS)
	open var size: Size {
		get { return bounds.size }
		set { bounds.size = newValue }
	}
	#else
	open var size: Size {
		get { return frame.size }
		set { frame.size = newValue }
	}
	#endif

	/** The origin and extent of the layer expressed in its parent layer's coordinate space.
		Animatable. */
	open var frame: Rect {
		get {
			// TODO(jb): Do we need to make this distinction? Can't UIKit's version just use view.frame instead of layer.frame?
			// TODO(jb): Treat self.bounds the same way as here.
			#if os(iOS)
				return Rect(layer.frame)
			#else
				return Rect(self.view.frame)
			#endif
		}
		set {
			#if os(iOS)
				layer.frame = CGRect(newValue)
			#else
				animatableView.frame = CGRect(newValue)
			#endif
		}
	}

	/** The visible region of the layer, expressed in its own coordinate space. The x and y
		position define the visible origin (e.g. if you set bounds.y = 50, the top 50 pixels
		of the layer's image will be cut off); the width and height define its size.
		Animatable. */
	#if os(iOS)
	open var bounds: Rect {
		get { return Rect(layer.bounds) }
		set { layer.bounds = CGRect(newValue) }
	}
	#else
	open var bounds: Rect {
		get { return Rect(view.bounds) }
		set { animatableView.bounds = CGRect(newValue) }
	}
	#endif

	/** A layer's position is defined in terms of its anchor point, which defaults to the center.
		e.g. if you changed the anchor point to the upper-left hand corner, the layer's position
		would define the position of that corner.

		The anchor point also defines the point about which transformations are applied. e.g. for
		rotation, it defines the center of rotation.

		The anchor point is specified in unit coordinates: (0, 0) is the upper-left; (1, 1) is the
		lower-right. */
	open var anchorPoint: Point {
		get { return Point(layer.anchorPoint) }
		set { layer.anchorPoint = CGPoint(newValue) }
	}

	#if os(iOS)
	/// The rotation of the layer specified in degrees. May be used interchangeably with rotationRadians. Defaults to 0.
	open var rotationDegrees: Double {
		get {
			return rotationRadians * 180.0 / Double.pi
		}
		set {
			rotationRadians = newValue * Double.pi / 180.0
		}
	}
	#else
	/// The rotation of the layer specified in degrees. May be used interchangeably with rotationRadians. Defaults to 0.
	open var rotationDegrees: Double {
		get {
			return Double(view.frameCenterRotation)
		}
		set {
			animatableView.frameCenterRotation = CGFloat(newValue)
		}
	}
	#endif

	#if os(iOS)
	/// The rotation of the layer specified in radians. May be used interchangeably with rotationDegrees. Defaults to 0.
	open var rotationRadians: Double {
        get {
            return layer.value(forKeyPath: "transform.rotation.z") as! Double
        }
		set {
            layer.setValue(newValue, forKeyPath: "transform.rotation.z")
        }
	}
	#else
	/// The rotation of the layer specified in radians. May be used interchangeably with rotationDegrees. Defaults to 0.
	open var rotationRadians: Double {
		get {
			return rotationDegrees * Double.pi / 180.0
		}
		set {
			rotationDegrees = newValue * 180.0 / Double.pi
		}
	}
	#endif
	

	/** The scaling factor of the layer. Setting this value will set both scaleX and scaleY
	to the new value. Defaults to 1. */
	open var scale: Double {
		get { return scaleX }
		set {
			scaleX = newValue
			scaleY = newValue
		}
	}

	/** The scaling factor of the layer along the x dimension. Defaults to 1. */
	open var scaleX: Double {
        get {
            return layer.value(forKeyPath: "transform.scale.x") as! Double
        }
        set {
            layer.setValue(newValue, forKeyPath: "transform.scale.x")
        }
	}

	/** The scaling factor of the layer along the y dimension. Defaults to 1. */
	open var scaleY: Double {
        get {
            return layer.value(forKeyPath: "transform.scale.y") as! Double
        }
        set {
            layer.setValue(newValue, forKeyPath: "transform.scale.y")
        }
	}


	/** Returns the layer's position in the root layer's coordinate space. */
	open var globalPosition: Point {
		get {
			if let parent = parent {
				return parent.convertLocalPointToGlobalPoint(position)
			} else {
				return position
			}
		}
		set {
			if let parent = parent {
				position = parent.convertGlobalPointToLocalPoint(newValue)
			} else {
				position = newValue
			}
		}
	}
	
	open var screenPosition: Point {
		#if os(iOS)
		return globalPosition
		#else
			let screenCGPoint = view.window?.convertToScreen(CGRect(origin: CGPoint(globalPosition), size: CGSize())).origin ?? CGPoint()
			return Point(screenCGPoint)
		#endif
	}

	/** Returns whether the layer contains a given point, interpreted in the root layer's
		coordinate space. */
	open func containsGlobalPoint(_ point: Point) -> Bool {
		let localPoint = CGPoint(convertGlobalPointToLocalPoint(point))
		#if os(iOS)
			return view.point(inside: localPoint, with: nil)
		#else
			return view.isMousePoint(localPoint, in: view.bounds)
		#endif
	}

	/** Converts a point specified in the root layer's coordinate space to that same point
	expressed in the receiver's coordinate space. */
	open func convertGlobalPointToLocalPoint(_ globalPoint: Point) -> Point {
		#if os(iOS)
			return Point(view.convert(CGPoint(globalPoint), from: UIScreen.main.coordinateSpace))
		#else
			return Point(view.convert(CGPoint(globalPoint), from: nil))
		#endif
	}
	
	/** Converts a point specified in the receiver's coordinate space to that same point
	expressed in the root layer's coordinate space. */
	open func convertLocalPointToGlobalPoint(_ localPoint: Point) -> Point {
		#if os(iOS)
			return Point(view.convert(CGPoint(localPoint), to: UIScreen.main.coordinateSpace))
		#else
			return Point(view.convert(CGPoint(localPoint), to: nil))
		#endif
	}
	
	/// Converts the given rect from `otherLayer`'s coordinate space to the receiver's coordinate space.
	open func convert(rect: Rect, from otherLayer: Layer) -> Rect {
		return Rect(view.convert(CGRect(rect), from: otherLayer.childHostingView))
	}
	
	/// Converts the given point from `otherLayer`'s coordinate space to the receiver's coordinate space.
	open func convert(point: Point, from otherLayer: Layer) -> Point {
		return Point(view.convert(CGPoint(point), from: otherLayer.view))
	}
	
	/// Converts the given point to `otherLayer`'s coordinate space from the receiver's coordinate space.
	open func convert(point: Point, to otherLayer: Layer) -> Point {
		return Point(view.convert(CGPoint(point), to: otherLayer.view))
	}
	
	/// Returns the first sublayer whose frame contains the given point, or nil if none can be found.
	/// The point should be in the receiver's local coordinate space.
	open func subLayer(for point: Point) -> Layer? {
		// TODO: this should probably use hitTest() but that returns descendents, which isn't quite what I'm looking for.
		
		return sublayers.first(where: { $0.frame.contains(point) })
	}
	
	/// Returns the deepest sublayer containing the given point. The point should be in the receiver's local coordinate space.
	open func deepestSublayer(for point: Point) -> Layer? {
		
		// Currently hit testing on `view` and not `childHostingView` due to some weirdness with ScrollLayer
		// and how it converts points (eg it uses its `childHostingView` to convert points, which is problematic).
		// `hitTest()` expects the given `point` to be in the view's superview's coordinate space,
		// so this way works OK for now.
		// Need to re-think how ScrollLayer points work though.
		// This really only works now if the scroll layer isn't scrolled though... ugh.
		guard let deepestView = view.hitTest(CGPoint(point)) else {
			return nil
		}
		if self.view == deepestView { return self }
		
		func recursivelySearchSublayers(of layer: Layer, forLayerOwning view: SystemView) -> Layer? {
			
			for sublayer in layer.sublayers {
				if sublayer.view == view { // might want to check childHostingView instead of view?
					return sublayer
				} else if let deepest = recursivelySearchSublayers(of: sublayer, forLayerOwning: view) {
					return deepest
				}
			}
			return nil
		}
		
		return recursivelySearchSublayers(of: self, forLayerOwning: deepestView)
	}
	
	#if os(iOS)
	/** Optional function which is used for layer hit testing. You can provide your own implementation to determine if a (touch) point should be considered "inside" the layer. This is useful for enlarging the tap target of a small layer, for example. 
	
		Your custom implementation will only be called if the existing implementation returns `false`.
	*/
	open var pointInside: ((Point) -> Bool)? {
		get { return imageView!.pointInside }
		set { imageView?.pointInside = newValue }
	}
	#endif
	

	// MARK: Appearance

	/** The layer's background color. Will be displayed behind images and borders, above
		shadows. Defaults to nil. Animatable. */
	open var backgroundColor: Color? {
		get { return view.backgroundColor != nil ? Color(view.backgroundColor!) : nil }
		set { view.backgroundColor = newValue?.systemColor }
	}

	#if os(iOS)
	/** The layer's opacity (from 0 to 1). Animatable. Defaults to 1. */
	open var alpha: Double {
		get { return Double(view.alpha) }
		set { animatableView.alpha = CGFloat(newValue) }
	}
	#else
	/** The layer's opacity (from 0 to 1). Animatable. Defaults to 1. */
	open var alpha: Double {
		get { return Double(view.alphaValue) }
		set { animatableView.alphaValue = CGFloat(newValue) }
	}
	#endif
	
	/// Indicates if this layer is explicitly marked as being hidden (but may still return false if one of its ancestors is marked as hidden).
	open var hidden: Bool {
		get { return view.isHidden }
		set { animatableView.isHidden = newValue }
	}

	/** The layer's corner radius. Setting this to a non-zero value will also cause the
		layer to be masked at its corners. Defaults to 0. */
	open var cornerRadius: Double {
		get { return Double(layer.cornerRadius) }
		set {
			layer.cornerRadius = CGFloat(newValue)
			layer.masksToBounds = self._shouldMaskToBounds()
		}
	}

	/** An optional image which the layer displays. When set, changes the layer's size to
		match the image's. Defaults to nil. */
	open var image: Image? {
		didSet { imageDidChange() }
	}
	
	/// Indicates whether or not the layer's `image` will animate (if it is a .gif).
	open var imageAnimates: Bool {
		get { return imageView?.animates ?? false }
		set { imageView?.animates = newValue }
	}
	
	/// Controls how the layer's image scales if the layer's size does not match the image's size.
	/// By default, the image does no scaling, but if you set this property to `true` then the image scales proportionally (retaining its aspect ratio). You probably want the layer's size to also scale proportionally, too.
	open var imageScalesRetainingAspectRatio: Bool {
		get { return imageView?.imageScaling == NSImageScaling.scaleProportionallyUpOrDown }
		set { imageView?.imageScaling = (newValue ? NSImageScaling.scaleProportionallyUpOrDown : .scaleNone) }
	}

	/** The border drawn around the layer, inset into the layer's bounds, and on top of any of
		the other layer content. Respects the corner radius. Defaults to a clear border with
		a 0 width. */
	open var border: Border {
		get {
			return Border(color: Color(SystemColor(nillableCGColor: layer.borderColor)), width: Double(layer.borderWidth))
		}
		set {
			layer.borderColor = newValue.color.systemColor.cgColor
			layer.borderWidth = CGFloat(newValue.width)
		}
	}

	/** The shadow drawn beneath the layer. If the layer has no background color, this shadow
		will respect the alpha values of the layer's image: clear parts of the image will not
		generate a shadow.
	
		On OS X, this uses an `NSShadow`, which encodes the shadow's alpha in its colour.
		So, the `Shadow.alpha` is ignored, and instead the alpha comes from `Shadow.color`.
	*/
	open var shadow: Shadow {
		get {
			#if os(iOS)
			let layer = self.layer
			let color: Color
			if let shadowColor = layer.shadowColor {
				let systemColor = SystemColor(nillableCGColor: shadowColor)
				color = Color(systemColor)
			} else {
				color = Color.black
			}
			
			return Shadow(color: color, alpha: Double(layer.shadowOpacity), offset: Size(layer.shadowOffset), radius: Double(layer.shadowRadius))
			#else
				let shadow = view.shadow
				let color = Color(shadow?.shadowColor ?? SystemColor.clear)
				let offset = Size(shadow?.shadowOffset ?? CGSize())
				let radius: Double
				if let r = shadow?.shadowBlurRadius {
					radius = Double(r)
				} else {
					radius = 0.0
				}
				
				return Shadow(color: color, offset: offset, radius: radius)
			#endif
		}
		set {
			#if os(iOS)
				layer.shadowColor = newValue.color.systemColor.cgColor
				layer.shadowOpacity = Float(newValue.alpha)
				layer.shadowOffset = CGSize(newValue.offset)
				layer.shadowRadius = CGFloat(newValue.radius)
			#else
				let systemShadow = NSShadow()
				systemShadow.shadowColor = newValue.color.systemColor
				systemShadow.shadowOffset = CGSize(newValue.offset)
				systemShadow.shadowBlurRadius = CGFloat(newValue.radius)
				
				view.shadow = systemShadow
			#endif
			layer.masksToBounds = self._shouldMaskToBounds()
		}
	}
    
	
	// TODO(jb): port masked layer stuff to OS X.
	#if os(iOS)
    /** The mask layer is used to clip or filter the contents of a layer. Those contents will be
        rendered only where the mask layer's contents are opaque. Partially transparent regions
        of the mask layer will result in partially transparent renderings of the host layer.

        The mask layer operates within the coordinate space of its host layer. In most cases,
        you'll want to set a mask layer's frame to be equal to its host's bounds.

        Be aware: mask layers do incur an additional performance cost. If the cost becomes too
        onerous, consider making flattened images of the masked content instead. */
    open var maskLayer: Layer? {
        willSet {
            newValue?.parent = nil
            newValue?.maskedLayer?.maskLayer = nil
        }
        didSet {
            view.mask = maskLayer?.view
            maskLayer?.maskedLayer = self
        }
    }
    
    fileprivate weak var maskedLayer: Layer?
	#endif

	
	// MARK: Particles
	
	/** An array of the layer's particle emitters. */
	fileprivate var particleEmitters: [ParticleEmitter] = []
	
	
	/** Adds the particle emitter to the layer. */
	open func addParticleEmitter(_ particleEmitter: ParticleEmitter, forDuration duration: TimeInterval? = nil) {
		self.particleEmitters.append(particleEmitter)
		self.layer.addSublayer(particleEmitter.emitterLayer)
		particleEmitter.emitterLayer.frame = self.layer.bounds
		particleEmitter.size = self.size
		particleEmitter.position = Point(particleEmitter.emitterLayer.position)
		
		// TODO(jb): Should we disable bounds clipping on self.view.layer or instruct devs to instead emit the particles from a parent layer?
		self.layer.masksToBounds = false
		
		if let duration = duration {
			afterDuration(duration) {
				self.removeParticleEmitter(particleEmitter)
			}
		}
	}
	
	
	/** Removes the given particle emitter from the layer. */
	open func removeParticleEmitter(_ particleEmitter: ParticleEmitter) {
		particleEmitter.emitterLayer.removeFromSuperlayer()
		self.particleEmitters = self.particleEmitters.filter {
			(emitter: ParticleEmitter) -> Bool in
			return emitter !== particleEmitter
		}
	}
	
	
	// TODO(jb): Port touches / gestures to OS X? What makes sense here?
    // MARK: Touches and gestures

	/** An array of the layer's gestures. Append a gesture to this list to add it to the layer.
	
	Gestures are like a higher-level abstraction than the Layer touch handler API. For
	instance, a pan gesture consumes a series of touch events but does not actually begin
	until the user moves a certain distance with a specified number of fingers.
	
	Gestures can also be exclusive: by default, if a gesture recognizes, traditional
	touch handlers for that subtree will be cancelled. You can control this with the
	cancelsTouchesInView property. Also by default, if one gesture recognizes, it will
	prevent all other gestures involved in that touch from recognizing.
	
	Defaults to the empty list. */
	open var gestures: [GestureType] = [] {
		didSet {
			for gesture in gestures {
				gesture.hostLayer = self
			}
		}
	}
	
	#if os(iOS)
	/** When false, touches that hit this layer or its sublayers are discarded. Defaults
		to true. */
	open var userInteractionEnabled: Bool {
		get { return view.isUserInteractionEnabled }
		set { view.isUserInteractionEnabled = newValue }
	}

	

	/** A layer's touchesXXXHandler property is set to a closure of this type. It takes a
		dictionary whose keys are touch sequences' IDs and whose values are a touch sequence;
		it should return whether or not the event was handled. If the return value is false
		the touches event will be passed along to the parent layer. */
	public typealias TouchesHandler = ([UITouchID: TouchSequence<UITouchID>]) -> Bool

	/** A layer's touchXXXHandler property is set to a closure of this type. These handlers
		can be used as more convenient variants of the touchesXXXHandlers for situations in
		which the touches can be considered independently. These handlers are passed a touch
		sequence and don't need to return a value.

		If multiple touches are involved in a single event for a single layer, this handler
		will be invoked once for each of those touches.

		If a touchXXXHandler is set for a given event, events are never passed along to the
		parent layer (if you need dynamic bubbling behavior, use touchesXXXHandlers). */
	public typealias TouchHandler = (TouchSequence<UITouchID>) -> Void

	/** A dictionary whose keys are touch sequence IDs and whose values are touch sequences.
		This dictionary contains a value for each touch currently active on this layer.

		When a touch or touches handler is running, this property will already have been
		updated to a value incorporating the new touch event. */
	open var activeTouchSequences: [UITouchID: TouchSequence<UITouchID>] {
		return imageView?.activeTouchSequences ?? [UITouchID: UITouchSequence]()
	}

	/** A handler for when new touches arrive. See the TouchesHandler documentation for more
		details. */
	open var touchesBeganHandler: TouchesHandler? {
		get { return imageView?.touchesBeganHandler }
		set { imageView?.touchesBeganHandler = newValue }
	}

	/** A handler for when a new touch arrives. See the TouchHandler documentation for more
		details. */
	open var touchBeganHandler: TouchHandler? {
		get { return imageView?.touchBeganHandler }
		set { imageView?.touchBeganHandler = newValue }
	}

	/** A handler for when touches move. See the TouchesHandler documentation for more
		details. */
	open var touchesMovedHandler: TouchesHandler? {
		get { return imageView?.touchesMovedHandler }
		set { imageView?.touchesMovedHandler = newValue }
	}

	/** A handler for when a touch moves. See the TouchHandler documentation for more details. */
	open var touchMovedHandler: TouchHandler? {
		get { return imageView?.touchMovedHandler }
		set { imageView?.touchMovedHandler = newValue }
	}

	/** A handler for when touches end. See the TouchesHandler documentation for more
		details. */
	open var touchesEndedHandler: TouchesHandler? {
		get { return imageView?.touchesEndedHandler }
		set { imageView?.touchesEndedHandler = newValue }
	}

	/** A handler for when a touch ends. See the TouchHandler documentation for more details. */
	open var touchEndedHandler: TouchHandler? {
		get { return imageView?.touchEndedHandler }
		set { imageView?.touchEndedHandler = newValue }
	}

	/** A handler for when touches are cancelled. This may happen because a gesture with
		cancelsTouchesInView set to true has recognized, because of palm rejection, or because
		a system event (like a system gesture) has cancelled the touch.

		See TouchesHandler documentation for more details. */
	open var touchesCancelledHandler: TouchesHandler? {
		get { return imageView?.touchesCancelledHandler }
		set { imageView?.touchesCancelledHandler = newValue }
	}

	/** A handler for when a touch is cancelled. This may happen because a gesture with
		cancelsTouchesInView set to true has recognized, because of palm rejection, or because
		a system event (like a system gesture) has cancelled the touch.

		See TouchesHandler documentation for more details. */
	open var touchCancelledHandler: TouchHandler? {
		get { return imageView?.touchCancelledHandler }
		set { imageView?.touchCancelledHandler = newValue }
	}

	/** Returns a list of descendent layers of the receiver (including self) which are actively
		being touched, or [] if none are. */
	open var touchedDescendents: [Layer] {
		var accumulator = [Layer]()
		if activeTouchSequences.count > 0 {
			accumulator.append(self)
		}
		for sublayer in sublayers {
			accumulator += sublayer.touchedDescendents
		}
		return accumulator
	}
	#endif // touch + gesture stuff
	
	// MARK: Mouse handling
	#if os(OSX)
	
	/** When false, mouse events that hit this layer or its sublayers are discarded. Defaults
	to true. */
	open var mouseInteractionEnabled: Bool {
		get { return interactableView?.mouseInteractionEnabled ?? true }
		set { interactableView?.mouseInteractionEnabled = newValue }
	}
	
	open var cursorAppearance: Cursor.Appearance? {
		get { return interactableView?.cursorAppearance }
		set { interactableView?.cursorAppearance = newValue }
	}
	
	/** This type is used for handling mouse input events. */
	public typealias MouseHandler = (InputEvent) -> Void
	public typealias KeyEquivalentHandler = (InputEvent) -> KeyEventResult
	public typealias ExternalDragAndDropHandler = (ExternalDragAndDropInfo) -> ExternalDragAndDropResult
	public typealias ExternalPerformDropHandler = (ExternalDragAndDropInfo) -> Bool
	
	
	/// The result of a key event handler, which informs the keyboard event system how to proceed.
	public enum KeyEventResult {
		
		/// The event was handled by the handler and should propagate no further.
		case handled
		
		/// The event was unhandled by the handler and should be passed to the next candidate responder.
		case unhandled
	}
	
	/** Called when the mouse button is clicked down. */
	public var mouseDownHandler: MouseHandler? {
		get { return interactableView?.mouseDownHandler }
		set { interactableView?.mouseDownHandler = newValue}
	}
	
	
	/** Called when the mouse buttin is dragged. */
	public var mouseDraggedHandler: MouseHandler? {
		get { return interactableView?.mouseDraggedHandler }
		set { interactableView?.mouseDraggedHandler = newValue}
	}
	
	
	/** Called when the mouse button is released. */
	public var mouseUpHandler: MouseHandler? {
		get { return interactableView?.mouseUpHandler }
		set { interactableView?.mouseUpHandler = newValue}
	}
	
	
	/** Called when the mouse enters the layer. */
	public var mouseEnteredHandler: MouseHandler? {
		get { return interactableView?.mouseEnteredHandler }
		set { interactableView?.mouseEnteredHandler = newValue}
	}
	
	
	/** Called when the mouse exits the layer. */
	public var mouseExitedHandler: MouseHandler? {
		get { return interactableView?.mouseExitedHandler }
		set { interactableView?.mouseExitedHandler = newValue}
	}
	
	
	/** Called when the mouse moves at all on the layer. See also mouseDraggedHandler. */
	public var mouseMovedHandler: MouseHandler? {
		get { return interactableView?.mouseMovedHandler }
		set { interactableView?.mouseMovedHandler = newValue}
	}
	
	// MARK: - Key handling
	
	open func becomeFirstResponder() {
		view.window?.makeFirstResponder(view)
	}
	
	/** Called when keys go down in the layer. */
	public var keyEquivalentHandler: KeyEquivalentHandler? {
		get { return interactableView?.keyEquivalentHandler }
		set { interactableView?.keyEquivalentHandler = newValue }
	}
	
	
	public var keyDownHandler: KeyEquivalentHandler? {
		get { return interactableView?.keyDownHandler }
		set { interactableView?.keyDownHandler = newValue }
	}
	
	
	public var flagsChangedHandler: KeyEquivalentHandler? {
		get { return interactableView?.flagsChangedHandler }
		set { interactableView?.flagsChangedHandler = newValue }
	}
	
	// MARK: - External Drag and Drop
	public var externalDragEnteredHandler: ExternalDragAndDropHandler? {
		get { return externalDragAndDroppableView?.draggingEnteredHandler }
		set { externalDragAndDroppableView?.draggingEnteredHandler = newValue }
	}
	
	public var externalPerformDropHandler: Layer.ExternalPerformDropHandler? {
		get { return externalDragAndDroppableView?.externalPerformDropHandler }
		set { externalDragAndDroppableView?.externalPerformDropHandler = newValue }
	}
	
	
	#endif

	// MARK: Convenience utilities

	open fileprivate(set) var willBeRemovedSoon: Bool = false
	open func removeAfterDuration(_ duration: Foundation.TimeInterval) {
		willBeRemovedSoon = true
		afterDuration(duration) {
			self.parent = nil
		}
	}

	
	open func fadeOutAndRemoveAfterDuration(_ duration: Foundation.TimeInterval) {
		willBeRemovedSoon = true
		let previousAlpha = alpha
		Layer.animateWithDuration(duration, animations: {
			self.alpha = 0
			}, completionHandler: {
				self.parent = nil
				self.alpha = previousAlpha
		})
	}

	// MARK: - Internal interfaces

	fileprivate func _shouldMaskToBounds() -> Bool {
		if image != nil {
			if self.shadow.isVisible && self.cornerRadius > 0 {
				var prefix: String = "layers"
				if let offendingLayer = self.name {
					prefix = "your layer '\(offendingLayer)'"
				}
				// in this case unless you have a complex hierarchy,
				// you should probably use a rounded image.
				Environment.currentEnvironment?.exceptionHandler("\(prefix) can't have images, shadows and corner radii set all at the same time. 😣")
			}

			// don't set masksToBounds unless you have an image and a corner radius
			if self.cornerRadius > 0 {
				return true
			}
		}

		// if you have a shadow set but no image, don't clip so you can see the shadow
		if self.shadow.isVisible {
			return false
		}

		// otherwise, always clip (making sublayers easier to crop/etc by default)
		return true
	}

	// MARK: - Internal interfaces

	fileprivate func parentDidChange() {
		parentView = parent?.childHostingView
		parent?.sublayers.append(self)
	}
	
	/** Returns the system view to be used as a "parent view" for this layer's sub-layers. Subclasses may wish to override this so that sub-layers can be added to a specific view in their internal subviews. For example, ScrollLayer uses this on OS X so that sublayers are added to its -documentView NSView. */
	var childHostingView: SystemView {
		return view
	}

	fileprivate func imageDidChange() {
		if let image = image {
			imageView?.image = image.systemImage
			#if os(iOS)
				size = image.size
			#else
				// TODO(jb): Using just .size (aka the CALayer's bounds' size) doesn't update view coordinate space on AppKit :\
				frame.size = image.size
			#endif
			layer.masksToBounds = self._shouldMaskToBounds()
		}
	}

	fileprivate init(wrappingView: SystemView, name: String? = nil) {
		view = wrappingView
		self.name = name
	}
    
    
	/** Creates a new layer hosted by the given view. The layer wraps its own view, which is sized to the full dimensions of the hosting view. */
    public convenience init(hostingView: SystemView, name: String? = nil) {
        self.init()
        self.parentView = hostingView
		self.frame = Rect(hostingView.bounds)
		#if os(iOS)
			self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		#else
			self.view.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
			
		#endif
    }
	
	#if os(macOS)
	private static var inAnimationContext: Bool { return animationContextCount > 0 }
	private static var animationContextCount = 0
	static func beginAnimationContext() { animationContextCount += 1 }
	static func endAnimationContext() { animationContextCount -= 1 }
	#endif
	
	// MARK: UIKit mapping

	var view: SystemView
	fileprivate var layer: CALayer {
		#if os(iOS)
			return view.layer
		#else
			return view.layer!
		#endif
	}
	
	var animatableView: SystemView {
		#if os(macOS)
			assert(Thread.isMainThread)
			return Layer.inAnimationContext ? view.animator() : view
		#else
			return view
		#endif
	}
	
	fileprivate var imageView: TouchForwardingImageView? { return view as? TouchForwardingImageView }

	fileprivate var parentView: SystemView? {
		get { return view.superview }
		set { newValue?.addSubview(view) }
	}

	// MARK: Touch handling implementation

	class TouchForwardingImageView: SystemImageView, InteractionHandling, DraggableView, ResizableView, ExternalDragAndDropHandling {
		
		var dragBehavior: DragBehavior?
		var resizeBehavior: ResizeBehavior?
		
		required init?(coder aDecoder: NSCoder) {
			fatalError("This method intentionally not implemented.")
		}

		override init(frame: CGRect) {
			super.init(frame: frame)
			#if os(OSX)
				wantsLayer = true
				imageScaling = .scaleNone
			#endif
		}

		convenience init() {
			self.init(frame: CGRect())
		}
		
		#if os(iOS)
		
		var pointInside: ((Point) -> Bool)?
		
		
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
			
			// if we have a custom impl of pointInside call it if and only if the default implementation failed.
			if let pointInside = pointInside , defaultPointInside == false {
				return pointInside(Point(point))
			} else {
				return defaultPointInside
			}
		}

		fileprivate typealias TouchSequenceMapping = [UITouchID: UITouchSequence]
		fileprivate var activeTouchSequences = TouchSequenceMapping()

		fileprivate func handleTouches(_ touches: NSSet, event: UIEvent?, touchesHandler: TouchesHandler?, touchHandler: TouchHandler?, touchSequenceMappingMergeFunction: (TouchSequenceMapping, TouchSequenceMapping) -> TouchSequenceMapping) -> Bool {
			precondition(touchesHandler == nil || touchHandler == nil, "Can't set both a touches*Handler and a touch*Handler")

			let newSequenceMappings = incorporateTouches(touches, intoTouchSequenceMappings: activeTouchSequences)

			activeTouchSequences = touchSequenceMappingMergeFunction(activeTouchSequences, newSequenceMappings)

			if let touchHandler = touchHandler {
				for (_, touchSequence) in newSequenceMappings {
					touchHandler(touchSequence)
				}
				return true
			} else if let touchesHandler = touchesHandler {
				return touchesHandler(newSequenceMappings)
			} else {
				return false
			}
		}

		var touchesBeganHandler: TouchesHandler?
		var touchBeganHandler: TouchHandler?
		override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
			if !handleTouches(touches as NSSet, event: event, touchesHandler: touchesBeganHandler, touchHandler: touchBeganHandler, touchSequenceMappingMergeFunction: +) {
				super.touchesBegan(touches, with: event)
			}
		}

		var touchesMovedHandler: TouchesHandler?
		var touchMovedHandler: TouchHandler?
		override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
			if !handleTouches(touches as NSSet, event: event, touchesHandler: touchesMovedHandler, touchHandler: touchMovedHandler, touchSequenceMappingMergeFunction: +) {
				super.touchesMoved(touches, with: event)
			}
		}

		var touchesEndedHandler: TouchesHandler?
		var touchEndedHandler: TouchHandler?
		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
			if !handleTouches(touches as NSSet, event: event, touchesHandler: touchesEndedHandler, touchHandler: touchEndedHandler, touchSequenceMappingMergeFunction: -) {
				super.touchesEnded(touches, with: event)
			}
		}

		var touchesCancelledHandler: TouchesHandler?
		var touchCancelledHandler: TouchHandler?
		override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
			if !handleTouches(touches as NSSet, event: event, touchesHandler: touchesCancelledHandler, touchHandler: touchCancelledHandler, touchSequenceMappingMergeFunction: -) {
				super.touchesCancelled(touches, with: event)
			}
		}
		#else
		
		var mouseInteractionEnabled = true
		
		override func hitTest(_ point: NSPoint) -> NSView? {
			guard mouseInteractionEnabled else { return nil }
			
			return super.hitTest(point)
		}
		
		var cursorAppearance: Cursor.Appearance? {
			didSet {
				setupTrackingAreaIfNeeded()
				window?.invalidateCursorRects(for: self)
			}
		}
		
		override func resetCursorRects() {
			if let cursor = cursorAppearance {
				addCursorRect(bounds, cursor: cursor.nsCursor)
			}
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
		
		var draggingEnteredHandler: ExternalDragAndDropHandler?
		override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
			if let draggingEnteredHandler = draggingEnteredHandler {
				let pasteboard = sender.draggingPasteboard
				let image = sender.draggedImage
				
				return draggingEnteredHandler(ExternalDragAndDropInfo(draggingInfo: sender)).systemDragOperation
			}
			return NSDragOperation()
		}
		
		var externalPerformDropHandler: Layer.ExternalPerformDropHandler?
		override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
			return externalPerformDropHandler?(ExternalDragAndDropInfo(draggingInfo: sender)) ?? false
		}
		
		#endif
	}

	// MARK: CALayerWrappingView

	class CALayerWrappingView: SystemView {
		let wrappedLayer: CALayer
		init(wrappedLayer: CALayer) {
			self.wrappedLayer = wrappedLayer

			super.init(frame: wrappedLayer.frame)

			#if os(iOS)
				layer.addSublayer(wrappedLayer)
			#else
				layer!.addSublayer(wrappedLayer)
			#endif
			setNeedsLayout()
		}

		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has intentionally not been implemented")
		}

		override func layoutSubviews() {
			wrappedLayer.frame = bounds
		}
	}
    

    open var behaviors: [BehaviorType] = [] {
        didSet {
//            Environment.currentEnvironment?.behaviorDriver.updateWithLayer(self, behaviors: behaviors)
        }
    }
	
	// MARK: - Looking at view through different lenses.
	
	/// The drag behaviour for this layer. Currently only supported for Layers (and not subclasses).
	var dragBehavior: DragBehavior? {
		get { return draggableView?.dragBehavior }
		set { draggableView?.dragBehavior = newValue }
	}
	
	var resizeBehavior: ResizeBehavior? {
		get { return resizableView?.resizeBehavior }
		set { resizableView?.resizeBehavior = newValue }
	}
	
	private var draggableView: DraggableView? { return view as? DraggableView }
	private var resizableView: ResizableView? { return view as? ResizableView }
	
	private var interactableView: InteractionHandling? { return view as? InteractionHandling }
	private var externalDragAndDroppableView: ExternalDragAndDropHandling? { return view as? ExternalDragAndDropHandling }
}

#if os(macOS)
	public extension Layer {
		func autoscroll() {
			view.autoscroll(with: NSEvent())
		}
	}
#endif

extension Layer: Hashable {
	public var hashValue: Int {
		return view.hashValue
	}
}

extension Layer: CustomStringConvertible {
	public var description: String {
		var output = ""
		if let name = name {
			output += "\(name): "
		}
		output += view.description
		return output
	}
}

public func ==(a: Layer, b: Layer) -> Bool {
	return a === b
}

/// Represents a type (typically a view) which can handle interaction methods.
/// If you make a Layer subclass with a custom view and you want to handle interactions at the Layer level (i.e., not only through gesture recognizers),
/// then your view should conform to this protocol and your implementation should probably mirror Layer.TouchForwardingImageView's implementation.
#if os(iOS)
protocol InteractionHandling: class {}

#else
protocol InteractionHandling: MouseHandling, KeyHandling {}
#endif

#if os(macOS)

protocol MouseHandling: class {
	
	var mouseInteractionEnabled: Bool { get set }
	var cursorAppearance: Cursor.Appearance? { get set }
	
	var mouseDownHandler: Layer.MouseHandler? { get set }
	var mouseMovedHandler: Layer.MouseHandler? { get set }
	var mouseUpHandler: Layer.MouseHandler? { get set }
	var mouseDraggedHandler: Layer.MouseHandler? { get set }
	var mouseEnteredHandler: Layer.MouseHandler? { get set }
	var mouseExitedHandler: Layer.MouseHandler? { get set }
	
	func mouseDown(with event: NSEvent)
	func mouseMoved(with event: NSEvent)
	func mouseUp(with event: NSEvent)
	func mouseDragged(with event: NSEvent)
	func mouseEntered(with event: NSEvent)
	func mouseExited(with event: NSEvent)
	
}

protocol KeyHandling: class {
	var keyEquivalentHandler: Layer.KeyEquivalentHandler? { get set }
	var keyDownHandler: Layer.KeyEquivalentHandler? { get set }
	var flagsChangedHandler: Layer.KeyEquivalentHandler? { get set }
	
	func performKeyEquivalent(with event: NSEvent) -> Bool
	func keyDown(with event: NSEvent)
	func flagsChanged(with event: NSEvent)
}

extension MouseHandling where Self: SystemView {
	func setupTrackingAreaIfNeeded() {
		guard trackingAreas.isEmpty else { return }
		
		let options: NSTrackingArea.Options = [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeInActiveApp, NSTrackingArea.Options.inVisibleRect]
		let trackingArea = NSTrackingArea(rect: self.visibleRect, options: options, owner: self, userInfo: nil)
		self.addTrackingArea(trackingArea)
	}
}

protocol ExternalDragAndDropHandling: class {
	var draggingEnteredHandler: Layer.ExternalDragAndDropHandler? { get set }
	var externalPerformDropHandler: Layer.ExternalPerformDropHandler? { get set }
	
	func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation
}

#endif

// MARK: - External Drag and Drop

extension Layer {
	
	#if os(macOS)
	// not sure about this API yet, just putting paint on the canvas for now
	
	public enum DraggedType {
		case url
		
		var pasteboadType: NSPasteboard.PasteboardType {
			switch self {
			case .url: return NSPasteboard.PasteboardType.URL
			}
		}
	}
	
	open func register(forDraggedTypes draggedTypes: [DraggedType]) {
		view.registerForDraggedTypes(draggedTypes.map({ $0.pasteboadType }))
	}
	#endif
}


public struct ExternalDragAndDropInfo {
	let draggingInfo: NSDraggingInfo
	
	/// The location of the event relative to the root layer.
	public var globalLocation: Point {
		let rootLayer = Environment.currentEnvironment!.rootLayer
		return locationInLayer(layer: rootLayer)
	}
	
	/// The location of the event in the given layer.
	public func locationInLayer(layer: Layer) -> Point {
		return layer.convertGlobalPointToLocalPoint(Point(draggingInfo.draggingLocation))
	}
	
	public var imageURLs: [URL] {
		return draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingContentsConformToTypes: NSImage.imageTypes]) as? [URL] ?? []
	}
	
	public var videoURLs: [URL] {
		return draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingContentsConformToTypes: ["public.movie"]]) as? [URL] ?? []
	}
}

public enum ExternalDragAndDropResult {
	case nothing
	case copy
	
	var systemDragOperation: NSDragOperation {
		switch self {
		case .nothing: return NSDragOperation()
		case .copy: return .copy
		}
	}
}


#if os(iOS)
private typealias UITouchSequence = TouchSequence<UITouchID>

private func touchSequencesFromTouchSet(_ touches: NSSet) -> [UITouchSequence] {
	return touches.map {
		let touch = $0 as! UITouch
		return TouchSequence(samples: [TouchSample(touch)], id: UITouchID(touch))
	}
}

private func touchSequenceMappingsFromTouchSequences<ID>(_ touchSequences: [TouchSequence<ID>]) -> [ID: TouchSequence<ID>] {
	return dictionaryFromElements(touchSequences.map { ($0.id, $0) })
}

private func incorporateTouchSequences<ID>(_ sequences: [TouchSequence<ID>], intoTouchSequenceMappings mappings: [ID: TouchSequence<ID>]) -> [TouchSequence<ID>] {
	return sequences.map { (mappings[$0.id] ?? TouchSequence(samples: [], id: $0.id)) + $0 }
}

private func incorporateTouches(_ touches: NSSet, intoTouchSequenceMappings mappings: [UITouchID: TouchSequence<UITouchID>]) -> [UITouchID: TouchSequence<UITouchID>] {
	let updatedTouchSequences = incorporateTouchSequences(touchSequencesFromTouchSet(touches), intoTouchSequenceMappings: mappings)
	return touchSequenceMappingsFromTouchSequences(updatedTouchSequences)
}

#endif


#if os(iOS)
	import UIKit
	public typealias SystemImageView = UIImageView
#else
	import AppKit
	public typealias SystemImageView = NSImageView
	
	extension SystemView {
		func setNeedsLayout() {
			// TODO(jb): What's the OS X equiv of this again?
			// no-op?
		}
		
		@objc func setNeedsDisplay() {
			setNeedsDisplay(bounds)
		}
		
		@objc func layoutSubviews() {
			self.resizeSubviews(withOldSize: self.frame.size)
		}
		
		@objc var backgroundColor: SystemColor? {
			get {
				if let color = self.layer?.backgroundColor {
					return SystemColor(cgColor: color)
				}
				return nil
			}
			set {
				if let systemColor = newValue {
					self.layer?.backgroundColor = systemColor.cgColor
				} else {
					self.layer?.backgroundColor = nil
				}
			}
		}
	}
#endif
