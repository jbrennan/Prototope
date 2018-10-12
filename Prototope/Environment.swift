//
//  Environment.swift
//  Prototope
//
//  Created by Andy Matuschak on 2/8/15.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
	#else
	import AppKit
#endif

/** Establishes an environment in which Prototope can execute. */
public struct Environment {
	
	public let rootLayer: Layer
	public let imageProvider: (String) -> SystemImage?
	public let soundProvider: (String) -> Data?
	public let fontProvider: (_ name: String, _ size: Double) -> SystemFont?
	public let exceptionHandler: (String) -> Void
//    let behaviorDriver: BehaviorDriver

	public static var currentEnvironment: Environment?

	public init(rootView: SystemView, imageProvider: @escaping (String) -> SystemImage?, soundProvider: @escaping (String) -> Data?, fontProvider: @escaping (String, Double) -> SystemFont?, exceptionHandler: @escaping (String) -> Void) {
		
		self.rootLayer = Layer(hostingView: rootView, name: "Root")

//		self.behaviorDriver = BehaviorDriver()

		self.imageProvider = imageProvider
		self.soundProvider = soundProvider
		self.fontProvider = fontProvider
		self.exceptionHandler = exceptionHandler
	}

	public static func runWithEnvironment(_ environment: Environment, action: () -> Void) {
		// Eventually this will push and pop... but we're a long way from that because we still get events from the system now (e.g. timers, gestures). Before we can really push and pop, callbacks to clients will have to restore the environment according with those events. So for now, the expectation is that everything's dead when you change the environment.
		currentEnvironment = environment
		action()
	}

	public static func defaultEnvironmentWithRootView(_ rootView: SystemView) -> Environment {
		return Environment(
			rootView: rootView,
			imageProvider: { SystemImage(named: $0) },
			soundProvider: { name in
				for fileExtension in Sound.supportedExtensions {
					if let URL = Bundle.main.url(forResource: name, withExtension: fileExtension) {
						return try? Data(contentsOf: URL, options: [])
					}
				}
				return nil
			},
			fontProvider: { name, size in
				return SystemFont(name: name, size: CGFloat(size))
			},
			exceptionHandler: { exception in
				fatalError("⚠️ Prototope exception: \(exception)")
			}
		)
	}
}
