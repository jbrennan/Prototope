//
//  Screen.swift
//  Prototope
//
//  Created by Jason Brennan on Jun-16-2015.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//
//	Swifty re-write of https://github.com/adamwulf/ios-uitouch-bluedots

import UIKit
import UIKit.UIGestureRecognizerSubclass


/** Type representing the Screen of the device. */
public struct Screen {
	
	
	/** Enable touch dots to be shown. Useful for screen recordings. */
	public static var touchDotsEnabled: Bool = false {
		didSet {
			if touchDotsEnabled {
				enableTouchDots()
			} else {
				removeTouchDots()
			}
		}
	}
	
	fileprivate static var overlayView: TouchDotOverlayView? = nil
	fileprivate static func enableTouchDots() {
		
		if let delegate = UIApplication.shared.delegate {
			if let window = delegate.window {
				
				// double optional because delegate.window is an optional protocol method that *returns* an optional. TMYK
				if let window = window {
					overlayView = TouchDotOverlayView(frame: window.frame)
					window.addSubview(overlayView!)
				}
			}
		}
	}
	
	
	fileprivate static func removeTouchDots() {
		overlayView?.removeFromSuperview()
	}
}


/** Internal view subclass to act as a passthrough and to show touch dots. */
class TouchDotOverlayView: UIView {
	
	let gestureRecognizer = TouchDotGestureRecognizer()
	var dotViews = [Int: UIImageView]()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		self.isUserInteractionEnabled = true
		self.backgroundColor = UIColor.clear
		self.isOpaque = false
		
		self.gestureRecognizer.touchDelegate = self
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}


// UIView hierarchy overrides
extension TouchDotOverlayView {
	
	override func didMoveToSuperview() {
		self.gestureRecognizer.view?.removeGestureRecognizer(self.gestureRecognizer)
		self.superview?.addGestureRecognizer(self.gestureRecognizer)
	}
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		return nil
	}
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		return false
	}
}


// Touch dot management
extension TouchDotOverlayView {
	func updateTouch(_ touch: UITouch) {
		let location = touch.location(in: self)
		let key = touch.hash
		
		var view = self.dotViews[key]
		if view == nil {
			let image = UIImage(named: "finger", in: Bundle(for: type(of: self)), compatibleWith: nil)
			view = UIImageView(image: image)
			view?.sizeToFit()
			self.addSubview(view!)
			self.dotViews[key] = view
		}
		
		view?.center = location
	}
	
	
	func removeViewForTouch(_ touch: UITouch) {
		let view = self.dotViews.removeValue(forKey: touch.hash)
		view?.removeFromSuperview()
	}
}


// Touch handling from the gesture recognizer
extension TouchDotOverlayView: TouchDotGestureRecognizerDelegate {
	func touchesBegan(_ touches: Set<UITouch>) {
		// ensure we are topmost
		self.superview?.bringSubview(toFront: self)
		for touch in touches {
			self.updateTouch(touch)
		}
	}
	
	
	func touchesMoved(_ touches: Set<UITouch>) {
		for touch in touches {
			self.updateTouch(touch)
		}
	}
	
	
	func touchesEnded(_ touches: Set<UITouch>) {
		for touch in touches {
			self.removeViewForTouch(touch)
		}
	}
	
}


/** Internal gesture recognizer class to handle where touches are and how they interact with other GR in the system. */
class TouchDotGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
	
	var activeTouches = Set<UITouch>()
	weak var touchDelegate: TouchDotGestureRecognizerDelegate?

	init() {
		
		// TODO(jb): I'm not sure how to hack around this, I don't intend on messaging the target, but I've got to initialize super...
		super.init(target: NSObject(), action: #selector(NSObject.description as () -> String))
		self.removeTarget(nil, action: #selector(NSObject.description as () -> String))
		self.delaysTouchesBegan = false
		self.delaysTouchesEnded = false
		self.cancelsTouchesInView = false
		
		self.delegate = self
	}
	
	
	// MARK: - Touch handling
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		self.activeTouches.formUnion(touches )
		
		switch self.state {
		case .possible:
			self.state = .began
			
		default:
			self.state = .changed
		}
		
		self.touchDelegate?.touchesBegan(touches )
	}
	
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		self.state = .changed
		self.touchDelegate?.touchesMoved(touches )
	}
	
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		self.touchesCompleted(touches )
	}
	
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		self.touchesCompleted(touches )
	}
	
	func touchesCompleted(_ touches: Set<UITouch>) {
		self.activeTouches.subtract(touches)
		if self.activeTouches.count < 1 {
			self.state = .ended
		}
		self.touchDelegate?.touchesEnded(touches)
	}
	
	
	// MARK: - Gesture interaction
	override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	
	override func shouldBeRequiredToFail(by otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	
	// MARK: - Gesture recognizer delegate methods
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
}


protocol TouchDotGestureRecognizerDelegate: class {
	func touchesBegan(_ touches: Set<UITouch>)
	func touchesMoved(_ touches: Set<UITouch>)
	func touchesEnded(_ touches: Set<UITouch>)
}
