////
////  NSViewAnimationWithBlocks.swift
////  Prototope
////
////  Created by Jason Brennan on 2017-08-15.
////  Copyright © 2017 Jason Brennan. All rights reserved.
////
//
//import Cocoa
//
//enum ViewAnimationTransition {
//	case none
//	case flipFromLeft
//	case flipFromRight
//	case curlUp
//	case curlDown
//}
//
//enum ViewAnimationGroupTransition {
//	case none
//	case flipFromLeft
//	case flipFromRight
//	case curlUp
//	case curlDown
//	case flipFromTop
//	case flipFromBottom
//	case crossDissolve
//}
//
//struct ViewAnimationOptions: OptionSet {
//	let rawValue: Int
//	
//	static let layoutSubviews            = ViewAnimationOptions(rawValue: 1 <<  0)
//	static let allowUserInteraction      = ViewAnimationOptions(rawValue: 1 <<  1) // turn on user interaction while animating
//	static let beginFromCurrentState     = ViewAnimationOptions(rawValue: 1 <<  2) // start all views from current value, not initial value
//	static let `repeat`                    = ViewAnimationOptions(rawValue: 1 <<  3) // repeat animation indefinitely
//	static let autoreverse               = ViewAnimationOptions(rawValue: 1 <<  4) // if repeat, run animation back and forth
//	static let overrideInheritedDuration = ViewAnimationOptions(rawValue: 1 <<  5) // ignore nested duration
//	static let overrideInheritedCurve    = ViewAnimationOptions(rawValue: 1 <<  6) // ignore nested curve
//	static let allowAnimatedContent      = ViewAnimationOptions(rawValue: 1 <<  7) // animate contents (applies to transitions only)
//	static let showHideTransitionViews   = ViewAnimationOptions(rawValue: 1 <<  8) // flip to/from hidden state instead of adding/removing
//	
//	static let curveEaseInOut            = ViewAnimationOptions(rawValue: 0 << 16) // default
//	static let curveEaseIn               = ViewAnimationOptions(rawValue: 1 << 16)
//	static let curveEaseOut              = ViewAnimationOptions(rawValue: 2 << 16)
//	static let curveLinear               = ViewAnimationOptions(rawValue: 3 << 16)
//	
//	static let transitionNone            = ViewAnimationOptions(rawValue: 0 << 20) // default
//	static let transitionFlipFromLeft    = ViewAnimationOptions(rawValue: 1 << 20)
//	static let transitionFlipFromRight   = ViewAnimationOptions(rawValue: 2 << 20)
//	static let transitionCurlUp          = ViewAnimationOptions(rawValue: 3 << 20)
//	static let transitionCurlDown        = ViewAnimationOptions(rawValue: 4 << 20)
//	static let transitionCrossDissolve   = ViewAnimationOptions(rawValue: 5 << 20)
//	static let transitionFlipFromTop     = ViewAnimationOptions(rawValue: 6 << 20)
//	static let transitionFlipFromBottom  = ViewAnimationOptions(rawValue: 7 << 20)
//}
//
//enum ViewAnimationCurve {
//	case easeInOut
//	case easeIn
//	case easeOut
//	case linear
//}
//
//
////extension NSView {
////	// animation methods
////	static func animate(duration: Foundation.TimeInterval, animations: () -> ()) {
////		beginAnimations(with: ViewAnimationOptions.transitionNone)
////		
////		animations()
////	}
////	
////}
//
//fileprivate extension NSView {
//	static var animationGroups = [NSViewAnimationGroup]()
//	static func beginAnimations(with options: ViewAnimationOptions) {
//		let group = NSViewAnimationGroup()
//		animationGroups.append(group)
//	}
//	
//}
//
//class NSViewBlockAnimationDelegate: NSObject {
//	var completion: ((_ finished: Bool) -> ())?
//	var ignoreInteractionEvents = false
//}
//
//class NSViewAnimationGroup: NSObject {
//	var name: String?
//}
//
//
//
//
//
//
//
//
