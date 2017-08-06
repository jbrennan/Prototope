//
//  Animation.swift
//  Prototope
//
//  Created by Andy Matuschak on 10/8/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

#if os(iOS)
import UIKit
	#else
	import pop
	#endif
// MARK: - Dynamic animation APIs

extension Layer {
	/** Provides access to a collection of dynamic animators for the properties on this layer.
		If you want a layer to animate towards a point in a physical fashion (i.e. with speed
		determined by physical parameters, not a fixed duration), or if you want to take into
		account gesture velocity, this is your API.

		For example, this dynamically animates someLayer's x value to 400 using velocity from
		a touch sequence:

			someLayer.animators.x.target = 400
			someLayer.animators.x.velocity = touchSequence.currentVelocityInLayer(someLayer.superlayer!)

		See documentation for LayerAnimatorStore and Animator for more information.

		If you just want to change a bunch of values in a fixed-time animation, see
		Layer.animateWithDuration(:, animations:, completionHandler:). */
	public var animators: LayerAnimatorStore {
		if let animatorStore = layersToAnimatorStores[self] {
			return animatorStore
		} else {
			let animatorStore = LayerAnimatorStore(layer: self)
			layersToAnimatorStores[self] = animatorStore
			return animatorStore
		}
	}
}

/** See documentation for Layer.animators for more detail on the role of this object. */
open class LayerAnimatorStore {
	open var x: Animator<Double>
	open var y: Animator<Double>
    open var origin: Animator<Point>
	open var position: Animator<Point>
	open var size: Animator<Size>
	open var frame: Animator<Rect>
	open var bounds: Animator<Rect>
	open var backgroundColor: Animator<Color>
	open var alpha: Animator<Double>
	open var rotationRadians: Animator<Double>
	//kPOPScaleXY expects two values, not one!
	open var scale: Animator<Point>
	
	// TODO(jb): cornerRadius seems like it doesn't really obey the animation properties. Not sure why
	open var cornerRadius: Animator<Double>

/*	TODO:
	width, height, anchorPoint, cornerRadius,
	scale, scaleX, scaleY, rotationDegrees, rotationRadians,
	border, shadow, globalPosition
*/

	fileprivate weak var layer: Layer?

	init(layer: Layer) {
		self.layer = layer
		x = Animator(layer: layer, propertyName: kPOPLayerPositionX)
		y = Animator(layer: layer, propertyName: kPOPLayerPositionY)
        
        let animatableOrigin = POPAnimatableProperty.property(withName: "origin") { property in
            property?.readBlock = { obj, values in
                values?[0] = (obj as! SystemView).frame.origin.x
                values?[1] = (obj as! SystemView).frame.origin.y
            }
            property?.writeBlock = { obj, values in
                (obj as! SystemView).frame.origin.x = (values?[0])!
                (obj as! SystemView).frame.origin.y = (values?[1])!
            }
        } as! POPAnimatableProperty
        origin = Animator(layer: layer, property: animatableOrigin)
		position = Animator(layer: layer, propertyName: kPOPLayerPosition, shouldAnimateLayer: true)
		size = Animator(layer: layer, propertyName: kPOPLayerSize)
		bounds = Animator(layer: layer, propertyName: kPOPLayerBounds)
		frame = Animator(layer: layer, propertyName: kPOPViewFrame)
		
		#if os(iOS)
			backgroundColor = Animator(layer: layer, propertyName: kPOPViewBackgroundColor)
		#else
			backgroundColor = Animator(layer: layer, propertyName: kPOPLayerBackgroundColor, shouldAnimateLayer: true)
		#endif
		
		#if os(iOS)
			let alphaPropertyName = kPOPViewAlpha
		#else
			let alphaPropertyName = kPOPViewAlphaValue
		#endif
		
		alpha = Animator(layer: layer, propertyName: alphaPropertyName)
		rotationRadians = Animator(layer: layer, propertyName: kPOPLayerRotation, shouldAnimateLayer: true)
        scale = Animator(layer: layer, propertyName: kPOPLayerScaleXY, shouldAnimateLayer: true)
		cornerRadius = Animator(layer: layer, propertyName: kPOPLayerCornerRadius, shouldAnimateLayer: true)
	}
}

// TODO: support decay-type animations too.
/** See documentation for Layer.animators for more detail on the role of this object. */
open class Animator<Target: AnimatorValueConvertible> {
	/** The target value of this animator. Will update the corresponding property on the
		associated layer during the animation. When the animation completes, the target
		value will be set back to nil. */
	open var target: Target? {
		didSet {
			if target != nil {
				updateAnimationCreatingIfNecessary(true)
			} else {
				stop()
			}
		}
	}

	/** How quickly the animation resolves to the target value. Valid range from 0 to 20. */
	open var springSpeed: Double = 4.0 {
		didSet { updateAnimationCreatingIfNecessary(false) }
	}

	/** How springily the animation resolves to the target value. Valid range from 0 to 20. */
	open var springBounciness: Double = 12.0 {
		didSet { updateAnimationCreatingIfNecessary(false) }
	}

	/** The instantaneous velocity of the layer, specified in (target type units) per second.
		For instance, if this animator affects x, the velocity is specified in points per second. */
	open var velocity: Target? {
		didSet { updateAnimationCreatingIfNecessary(false) }
	}

	// TODO: This API is not robust. Need to think this through more.
	/** This function is called whenever the animation resolves to its target value. */
	open var completionHandler: (() -> Void)? {
		didSet {
			animationDelegate.completionHandler = { [weak self] in
				self?.completionHandler?()
				self?.target = nil
			}
		}
	}

	let property: POPAnimatableProperty
	fileprivate weak var layer: Layer?
	fileprivate let animationDelegate = AnimationDelegate()
	fileprivate var shouldAnimateLayer: Bool = false

	init(layer: Layer, property: POPAnimatableProperty) {
		self.property = property
		self.layer = layer
	}

	convenience init(layer: Layer, propertyName: String, shouldAnimateLayer: Bool) {
		let property = POPAnimatableProperty.property(withName: propertyName) as! POPAnimatableProperty
		self.init(layer: layer, property: property)
		self.shouldAnimateLayer = shouldAnimateLayer
	}

	convenience init(layer: Layer, propertyName: String) {
		let property = POPAnimatableProperty.property(withName: propertyName) as! POPAnimatableProperty
		self.init(layer: layer, property: property)
	}

	/** returns the object to animate, either the uiview or its calayer) */
	fileprivate func animatable() -> NSObject? {
		return (self.shouldAnimateLayer ? layer?.view.layer : layer?.view)
	}

	/** Immediately stops the animation. */
	open func stop() {
		animatable()?.pop_removeAnimation(forKey: property.name)
	}

	fileprivate func updateAnimationCreatingIfNecessary(_ createIfNecessary: Bool) {
		var animation = animatable()?.pop_animation(forKey: property.name) as! POPSpringAnimation?
		if animation == nil && createIfNecessary {
			animation = POPSpringAnimation()
			animation!.delegate = animationDelegate
			animation!.property = property
			animatable()?.pop_add(animation!, forKey: property.name)
		}

		if let animation = animation {
			precondition(target != nil)
			animation.springSpeed = CGFloat(springSpeed)
			animation.springBounciness = CGFloat(springBounciness)
			animation.toValue = target?.toAnimatorValue()
			if let velocityValue: AnyObject = velocity?.toAnimatorValue() {
				animation.velocity = velocityValue
			}
		}
	}
}

// MARK: - Traditional time-based animation APIs
// TODO: Revisit. Don't really like these yet.

extension Layer {
	/** Traditional cubic bezier animation curves. */
	public enum AnimationCurve {
		case linear
		case easeIn
		case easeOut
		case easeInOut
	}

	/** Implicitly animates all animatable changes made inside the animations block and calls the
		completion handler when they're complete. Attempts to compose reasonably with animations
		that are already in flight, but that's not always possible. If you're looking to take into
		account initial velocity or to have a more realistic physical simulation, see Layer.animators. */
	public class func animateWithDuration(_ duration: Foundation.TimeInterval, animations: @escaping () -> Void, completionHandler: (() -> Void)? = nil) {
		animateWithDuration(duration, curve: .easeInOut, animations: animations, completionHandler: completionHandler)
	}

	/** Implicitly animates all animatable changes made inside the animations block and calls the
		completion handler when they're complete. Attempts to compose reasonably with animations
		that are already in flight, but that's not always possible. If you're looking to take into
		account initial velocity or to have a more realistic physical simulation, see Layer.animators. */
	public class func animateWithDuration(_ duration: Foundation.TimeInterval, curve: AnimationCurve, animations: @escaping () -> Void, completionHandler: (() -> Void)? = nil) {
		#if os(iOS)
			var curveOption: UIViewAnimationOptions
			switch curve {
			case .linear:
				curveOption = .curveLinear
			case .easeIn:
				curveOption = .curveEaseIn
			case .easeOut:
				curveOption = .curveEaseOut
			case .easeInOut:
				curveOption = UIViewAnimationOptions()
			}
			UIView.animate(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions.allowUserInteraction.union(curveOption), animations: animations, completion: { _ in completionHandler?(); return })
		#else
			print("Sorry, animateWithDuration() isn't available on OS X yet!")
			animations()
			completionHandler?()
		#endif
	}

}

// MARK: - Internal interfaces

private class AnimationDelegate: NSObject, POPAnimationDelegate {
	var completionHandler: (() -> Void)?

	@objc func pop_animationDidStop(_ animation: POPAnimation, finished: Bool) {
		completionHandler?()
	}
}

public protocol AnimatorValueConvertible: _AnimatorValueConvertible {}
public protocol _AnimatorValueConvertible {
	func toAnimatorValue() -> AnyObject
}

extension Double: AnimatorValueConvertible {
	public func toAnimatorValue() -> AnyObject {
		return NSNumber(value: self as Double)
	}
}

extension Point: AnimatorValueConvertible {
	public func toAnimatorValue() -> AnyObject {
		return NSValue(cgPoint: CGPoint(self))
	}
}

extension Size: AnimatorValueConvertible {
	public func toAnimatorValue() -> AnyObject {
		return NSValue(cgSize: CGSize(self))
	}
}

extension Rect: AnimatorValueConvertible {
	public func toAnimatorValue() -> AnyObject {
		return NSValue(cgRect: CGRect(self))
	}
}

extension Color: AnimatorValueConvertible {
	public func toAnimatorValue() -> AnyObject {
		return self.systemColor
	}
}

private var layersToAnimatorStores = [Layer: LayerAnimatorStore]()
