//
//  Gesture.swift
//  Prototope
//
//  Created by Andy Matuschak on 10/19/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

// MARK: - Touches

/** Represents the state of a touch at a particular time. */
public struct TouchSample: SampleType {
	/** The location of the touch sample in the root layer's coordinate system. */
	public let globalLocation: Point
	
	/** The precise location of the touch sample in the root layer's coordinate system. This should only be used for Stylus, not finger, input. */
	public let preciseGlobalLocation: Point

	/** The time at which the touch arrived. */
	public let timestamp: Timestamp
	
	
	/** The absolute force of the touch, where 1.0 represents the force of an average touch. See also `force`, which is a value between 0..1. Available only for certain devices (3D touch devices like iPhone 6S or Apple Pencil). */
	public let absoluteForce: Double?
	
	/** The force of the touch as a percentage from 0..1. See also `absoluteForce`. Available only for certain devices (3D touch devices like iPhone 6S or Apple Pencil). */
	public let force: Double?

	/** The location of the touch sample, converted into a target layer's coordinate system. */
	public func locationInLayer(_ layer: Layer) -> Point {
		return layer.convertGlobalPointToLocalPoint(globalLocation)
	}

	public init(globalLocation: Point, preciseGlobalLocation: Point? = nil, timestamp: Timestamp, absoluteForce: Double? = nil, force: Double? = nil) {
		self.globalLocation = globalLocation
		self.preciseGlobalLocation = preciseGlobalLocation ?? globalLocation
		self.timestamp = timestamp
		self.absoluteForce = absoluteForce
		self.force = force
	}
}

extension TouchSample: CustomStringConvertible {
	public var description: String {
		return "<TouchSample: globalLocation: \(globalLocation), timestamp: \(timestamp)>"
	}
}

/** Only public because Swift requires it. Intended to be an opaque wrapper of UITouches. */
public struct UITouchID: Hashable, CustomStringConvertible {
	init(_ touch: SystemTouch) {
		self.touch = touch
		if UITouchID.touchesToIdentifiers[touch] == nil {
			UITouchID.touchesToIdentifiers[touch] = UITouchID.nextIdentifier
			UITouchID.nextIdentifier += 1
		}
	}

	fileprivate static var touchesToIdentifiers = [SystemTouch: Int]()
	fileprivate static var nextIdentifier = 0

	public var hashValue: Int {
		return self.touch.hashValue
	}

	public var description: String { return "\(UITouchID.touchesToIdentifiers[touch]!)" }

	fileprivate let touch: SystemTouch

}

public func ==(a: UITouchID, b: UITouchID) -> Bool {
	return a.touch === b.touch
}


// MARK: - Gesture

/* See conceptual documentation at Layer.gestures. */

/** A gesture which recognizes standard iOS taps. */
open class TapGesture: GestureType {
	/** The handler will be invoked with the location the tap occurred, expressed in the root layer's
		coordinate space. */
	public convenience init(_ handler: @escaping (_ globalLocation: Point) -> ()) {
		self.init(handler: handler)
	}

	/** When cancelsTouchesInLayer is true, touches being handled via touchXXXHandlers will be cancelled
		(and touch[es]CancelledHandler will be invoked) when the gesture recognizes.
		
		The handler will be invoked with the location the tap occurred, expressed in the root layer's
		coordinate space. */
	public init(cancelsTouchesInLayer: Bool = true, numberOfTapsRequired: Int = 1, numberOfTouchesRequired: Int = 1, handler: @escaping (_ globalLocation: Point) -> ()) {
		tapGestureHandler = TapGestureHandler(actionHandler: handler)
		tapGestureRecognizer = SystemTapGestureRecognizer(target: tapGestureHandler, action: #selector(TapGestureHandler.handleGestureRecognizer(_:)))

		#if os(iOS)
			tapGestureRecognizer.cancelsTouchesInView = cancelsTouchesInLayer
			tapGestureRecognizer.numberOfTapsRequired = numberOfTapsRequired
			tapGestureRecognizer.numberOfTouchesRequired = numberOfTouchesRequired
		#else
			tapGestureRecognizer.numberOfClicksRequired = numberOfTapsRequired
			if #available(OSX 10.12.2, *) {
				tapGestureRecognizer.numberOfTouchesRequired = numberOfTouchesRequired
			}
		#endif
        shouldRecognizeSimultaneouslyWithGesture = { _ in return false }
        tapGestureDelegate = GestureRecognizerBridge(self)
	}

	#if os(iOS)
	deinit {
		tapGestureRecognizer.removeTarget(tapGestureHandler, action: #selector(TapGestureHandler.handleGestureRecognizer(_:)))
	}

	/** The number of fingers which must simultaneously touch the gesture's view to count as a tap. */
	open var numberOfTouchesRequired: Int {
		get { return tapGestureRecognizer.numberOfTouchesRequired }
		set { tapGestureRecognizer.numberOfTouchesRequired = newValue }
	}

	/** The number of sequential taps which must be recognized before the gesture's handler is fired. */
	open var numberOfTapsRequired: Int {
		get { return tapGestureRecognizer.numberOfTapsRequired }
		set { tapGestureRecognizer.numberOfTapsRequired = newValue }
	}
	#endif

	fileprivate let tapGestureRecognizer: SystemTapGestureRecognizer
	fileprivate let tapGestureHandler: TapGestureHandler
    fileprivate var tapGestureDelegate: SystemGestureRecognizerDelegate!
    
    open var underlyingGestureRecognizer: SystemGestureRecognizer {
        return tapGestureRecognizer
    }
    
    open var shouldRecognizeSimultaneouslyWithGesture: (GestureType) -> Bool

	open weak var hostLayer: Layer? {
		didSet { handleTransferOfGesture(self, fromLayer: oldValue, toLayer: hostLayer) }
	}

	@objc class TapGestureHandler: NSObject {
		init(actionHandler: @escaping (Point) -> ()) {
			self.actionHandler = actionHandler
		}

		fileprivate let actionHandler: (Point) -> ()

		func handleGestureRecognizer(_ gestureRecognizer: SystemGestureRecognizer) {
			actionHandler(Point(gestureRecognizer.location(in: nil)))
		}
	}
}

/** A pan gesture recognizes a standard iOS pan: it doesn't begin until the user's moved at least 10
	points, then it tracks new touches coming and going over time (up to the maximumNumberOfTouches).
	It exposes simple access to the path of the center of all the touches. */
open class PanGesture: GestureType {

	/** The pan gesture won't recognize until minimumNumberOfTouches arrive, and it will ignore all touches
		beyond maximumNumberOfTouches (but won't be cancelled if that many arrive once the gesture has already
		begun).

		When cancelsTouchesInLayer is true, touches being handled via touchXXXHandlers will be cancelled
		(and touch[es]CancelledHandler will be invoked) when the gesture recognizes.

		The handler will be invoked as the gesture recognizes and updates; it's passed both the gesture's current
		phase (see ContinuousGesturePhase documentation) and also a touch sequence representing the center of
		all the touches involved in the pan gesture. */
	public init(minimumNumberOfTouches: Int = 1, maximumNumberOfTouches: Int = Int.max, cancelsTouchesInLayer: Bool = true, handler: @escaping (_ phase: ContinuousGesturePhase, _ centroidSequence: TouchSequence<Int>) -> ()) {
		panGestureHandler = PanGestureHandler(actionHandler: handler)
		panGestureRecognizer = SystemPanGestureRecognizer(target: panGestureHandler, action: #selector(PanGestureHandler.handleGestureRecognizer(_:)))
		
		#if os(iOS)
			panGestureRecognizer.cancelsTouchesInView = cancelsTouchesInLayer
			panGestureRecognizer.minimumNumberOfTouches = minimumNumberOfTouches
			panGestureRecognizer.maximumNumberOfTouches = maximumNumberOfTouches
		#endif
		shouldRecognizeSimultaneouslyWithGesture = { _ in return false }
		panGestureDelegate = GestureRecognizerBridge(self)
	}
	
	fileprivate let panGestureRecognizer: SystemPanGestureRecognizer
	fileprivate let panGestureHandler: PanGestureHandler
	fileprivate var panGestureDelegate: SystemGestureRecognizerDelegate!
	
	open var underlyingGestureRecognizer: SystemGestureRecognizer {
		return panGestureRecognizer
	}
	
	open var shouldRecognizeSimultaneouslyWithGesture: (GestureType) -> Bool
	
	open weak var hostLayer: Layer? {
		didSet { handleTransferOfGesture(self, fromLayer: oldValue, toLayer: hostLayer) }
	}
	
	#if os(iOS)
	deinit {
		panGestureRecognizer.removeTarget(panGestureHandler, action: #selector(PanGestureHandler.handleGestureRecognizer(_:)))
	}
	#endif

	@objc class PanGestureHandler: NSObject {
		fileprivate let actionHandler: (_ phase: ContinuousGesturePhase, _ centroidSequence: TouchSequence<Int>) -> ()
		fileprivate var centroidSequence: TouchSequence<Int>?

		init(actionHandler: @escaping (_ phase: ContinuousGesturePhase, _ centroidSequence: TouchSequence<Int>) -> ()) {
			self.actionHandler = actionHandler
		}

		func handleGestureRecognizer(_ gestureRecognizer: SystemGestureRecognizer) {
			let panGesture = gestureRecognizer as! SystemPanGestureRecognizer
			switch panGesture.state {
			case .began:
				// Reset the gesture to record translation relative to the starting centroid; we'll interpret subsequent translations as centroid positions.
				let centroidWindowLocation = panGesture.location(in: nil)
				panGesture.setTranslation(centroidWindowLocation, in: nil)

				struct IDState { static var nextCentroidSequenceID = 0 }
				centroidSequence = TouchSequence(samples: [TouchSample(globalLocation: Point(centroidWindowLocation), timestamp: Timestamp.currentTimestamp)], id: IDState.nextCentroidSequenceID)
				IDState.nextCentroidSequenceID += 1
			case .changed, .ended, .cancelled:
				#if os(iOS)
					let locationCoordinateSpace = panGesture.view!.window!
				#else
					let locationCoordinateSpace: NSView? = nil
				#endif
				let touchSample = TouchSample(globalLocation: Point(panGesture.translation(in: locationCoordinateSpace)), timestamp: Timestamp.currentTimestamp)
				centroidSequence = centroidSequence!.sampleSequenceByAppendingSample(touchSample)
			case .possible, .failed:
				fatalError("Unexpected gesture state")
			}

			actionHandler(ContinuousGesturePhase(panGesture.state)!, centroidSequence!)

			switch panGesture.state {
			case .ended, .cancelled:
				centroidSequence = nil
			case .began, .changed, .possible, .failed:
				break
			}
		}
	}
}

/** A long press gesture recognizes a standard iOS long press: 
	it doesn't begin until the required number of touches has been down for the required amount of time. */
open class LongPressGesture: GestureType {
	
	
	public init(
		minumumPressDuration: TimeInterval = 0.5,
		cancelsTouchesInLayer: Bool = true,
		handler: @escaping (_ phase: ContinuousGesturePhase, _ touchSequence: TouchSequence<Int>) -> (Void)
	) {
		longPressGestureHandler = LongPressGestureHandler(actionHandler: handler)
		longPressGestureRecognizer = SystemLongPressGestureRecognizer(target: longPressGestureHandler, action: #selector(LongPressGestureHandler.handleGestureRecognizer(_:)))
		
		longPressGestureRecognizer.cancelsTouchesInView = cancelsTouchesInLayer
		longPressGestureRecognizer.minimumPressDuration = minumumPressDuration
		
		shouldRecognizeSimultaneouslyWithGesture = { _ in return false }
		longPressGestureDelegate = GestureRecognizerBridge(self)
	}
	
	#if os(iOS)
	deinit {
		longPressGestureRecognizer.removeTarget(longPressGestureHandler, action: #selector(LongPressGestureHandler.handleGestureRecognizer(_:)))
	}
	#endif
	
	fileprivate let longPressGestureRecognizer: SystemLongPressGestureRecognizer
	fileprivate let longPressGestureHandler: LongPressGestureHandler
	fileprivate var longPressGestureDelegate: SystemGestureRecognizerDelegate!
	
	open var underlyingGestureRecognizer: SystemGestureRecognizer {
		return longPressGestureRecognizer
	}
	
	open var shouldRecognizeSimultaneouslyWithGesture: (GestureType) -> Bool
	
	open weak var hostLayer: Layer? {
		didSet { handleTransferOfGesture(self, fromLayer: oldValue, toLayer: hostLayer) }
	}
	
	@objc class LongPressGestureHandler: NSObject {
		fileprivate let actionHandler: (_ phase: ContinuousGesturePhase, _ touchSequence: TouchSequence<Int>) -> (Void)
		fileprivate var touchSequence: TouchSequence<Int>?
		
		init(actionHandler: @escaping (_ phase: ContinuousGesturePhase, _ touchSequence: TouchSequence<Int>) -> (Void)) {
			self.actionHandler = actionHandler
		}
		
		
		func handleGestureRecognizer(_ gestureRecognizer: SystemGestureRecognizer) {
			let longPressGesture = gestureRecognizer as! SystemLongPressGestureRecognizer
			
			switch longPressGesture.state {
			case .began:
				
				let touchWindowLocation = longPressGesture.location(in: nil)
				let touchSample = TouchSample(globalLocation: Point(touchWindowLocation), timestamp: Timestamp.currentTimestamp)
				
				struct IDState { static var nextLongPressSequenceID = 0 }
				
				touchSequence = TouchSequence(samples: [touchSample], id: IDState.nextLongPressSequenceID)
				
				IDState.nextLongPressSequenceID += 1
				
			case .changed, .ended, .cancelled:
				touchSequence = touchSequence!.sampleSequenceByAppendingSample(TouchSample(globalLocation: Point(longPressGesture.location(in: nil)), timestamp: Timestamp.currentTimestamp))
			case .possible, .failed:
				fatalError("Unexpected gesture state")
			}
			
			actionHandler(ContinuousGesturePhase(longPressGesture.state)!, touchSequence!)
			
			
			switch longPressGesture.state {
			case .ended, .cancelled:
				touchSequence = nil
			case .began, .changed, .possible, .failed:
				break
			}
		}
	}
	
}

// todo(jb): Finish bridging these types to OS X.
#if os(iOS)
/** A rotation sample represents the state of a rotation gesture at a single point in time */
public struct RotationSample: SampleType {
    public let rotationRadians: Double
    public let velocityRadians: Double
    
    public var rotationDegrees: Double {
        get {
            return rotationRadians * 180 / M_PI
        }
    }
    
    public var velocityDegrees: Double {
        get {
            return velocityRadians * 180 / M_PI
        }
    }
    
    public let centroid: TouchSample

    public var description: String {
        return "<RotationSample: ⟳\(rotationDegrees)° ∂⟳\(velocityDegrees)°/s, \(rotationRadians)rad \(velocityRadians)rad/s, @\(centroid)>"
    }
}

/** A rotation gesture recognizes a standard iOS rotation: it doesn't begin until the user's rotated by some number of degrees, then it tracks new touches coming and going over time as well as rotation relative to the beginning of the gesture and the current rotation velocity. It exposes simple access to the sequence of rotation samples representing the series of the gesture's state over time. */
open class RotationGesture: GestureType {
    /** The handler will be invoked as the gesture recognizes and updates; it's passed the gesture's current
    phase (see ContinuousGesturePhase documentation) and a sequence of rotation samples representing the series of the gesture's state over time. */
    public convenience init(_ handler: @escaping (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<RotationSample, Int>) -> ()) {
        self.init(handler: handler)
    }
    
    /**
    When cancelsTouchesInLayer is true, touches being handled via touchXXXHandlers will be cancelled
    (and touch[es]CancelledHandler will be invoked) when the gesture recognizes.
    
    The handler will be invoked as the gesture recognizes and updates; it's passed the gesture's current
    phase (see ContinuousGesturePhase documentation) and a sequence of rotation samples representing the series of the gesture's state over time. */
    public init(cancelsTouchesInLayer: Bool = true, handler: @escaping (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<RotationSample, Int>) -> ()) {
        rotationGestureHandler = RotationGestureHandler(actionHandler: handler)
        rotationGestureRecognizer = SystemRotationGestureRecognizer(target: rotationGestureHandler, action: #selector(RotationGestureHandler.handleGestureRecognizer(_:)))
        rotationGestureRecognizer.cancelsTouchesInView = cancelsTouchesInLayer
        
        shouldRecognizeSimultaneouslyWithGesture = { _ in return false }
        rotationGestureDelegate = GestureRecognizerBridge(self)
    }
    
    fileprivate let rotationGestureRecognizer: SystemRotationGestureRecognizer
    fileprivate let rotationGestureHandler: RotationGestureHandler
    fileprivate var rotationGestureDelegate: SystemGestureRecognizerDelegate!
    
    open var underlyingGestureRecognizer: SystemGestureRecognizer {
        return rotationGestureRecognizer
    }
    
    open var shouldRecognizeSimultaneouslyWithGesture: (GestureType) -> Bool
    
    open weak var hostLayer: Layer? {
        didSet { handleTransferOfGesture(self, fromLayer: oldValue, toLayer: hostLayer) }
    }
    
    deinit {
        rotationGestureRecognizer.removeTarget(rotationGestureHandler, action: #selector(RotationGestureHandler.handleGestureRecognizer(_:)))
    }
    
    @objc class RotationGestureHandler: NSObject {
        fileprivate let actionHandler: (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<RotationSample, Int>) -> ()
        fileprivate var sampleSequence: SampleSequence<RotationSample, Int>?
        
        init(actionHandler: @escaping (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<RotationSample, Int>) -> ()) {
            self.actionHandler = actionHandler
        }
        
        func handleGestureRecognizer(_ gestureRecognizer: SystemGestureRecognizer) {
            let rotationGesture = gestureRecognizer as! SystemRotationGestureRecognizer
            
            let rotation = Double(rotationGesture.rotation)
            let velocity = Double(rotationGesture.velocity)
            
            let centroidPoint = rotationGesture.location(in: nil)
            let touchSample = TouchSample(globalLocation: Point(centroidPoint), timestamp: Timestamp.currentTimestamp)
            let sample = RotationSample(rotationRadians: rotation, velocityRadians: velocity, centroid: touchSample)
            
            switch rotationGesture.state {
            case .began:
                struct IDState { static var nextSequenceID = 0 }
                sampleSequence = SampleSequence(samples: [sample], id: IDState.nextSequenceID)
                IDState.nextSequenceID += 1
                
            case .changed, .ended, .cancelled:
                sampleSequence = sampleSequence!.sampleSequenceByAppendingSample(sample)
                
            case .possible, .failed:
                fatalError("Unexpected gesture state")
            }
            
            actionHandler(ContinuousGesturePhase(rotationGesture.state)!, sampleSequence!)
            
            switch rotationGesture.state {
            case .ended, .cancelled:
                sampleSequence = nil
            case .began, .changed, .possible, .failed:
                break
            }
        }
    }
}

/** A pinch sample represents the state of a pinch gesture at a single point in time */
public struct PinchSample: SampleType {
    public let scale: Double
    public let velocity: Double
    public let centroid: TouchSample
    
    public var description: String {
        return "<PinchSample: scale: \(scale) velocity: \(velocity) @\(centroid)>"
    }
}

/** A pinch gesture recognizes a standard iOS pinch: it doesn't begin until the user's pinched some number of points, then it tracks new touches coming and going over time as well as scale relative to the beginning of the gesture and the current scale velocity. It exposes simple access to the sequence of pinch samples representing the series of the gesture's state over time. */
open class PinchGesture: GestureType {
    /** The handler will be invoked as the gesture recognizes and updates; it's passed the gesture's current
    phase (see ContinuousGesturePhase documentation), scale relative to the state at the beginning
    of the gesture, scale velocity in scale per second and also a touch sequence representing the center of all the touches involved in the pinch gesture. */
    public convenience init(_ handler: @escaping (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<PinchSample, Int>) -> ()) {
        self.init(handler: handler)
    }
    
    /**
    
    When cancelsTouchesInLayer is true, touches being handled via touchXXXHandlers will be cancelled
    (and touch[es]CancelledHandler will be invoked) when the gesture recognizes.
    
    The handler will be invoked as the gesture recognizes and updates; it's passed the gesture's current
    phase (see ContinuousGesturePhase documentation), scale relative to the state at the beginning
    of the gesture, scale velocity in scale per second and also a touch sequence representing the center of all the touches involved in the pinch gesture. */
    public init(cancelsTouchesInLayer: Bool = true, handler: @escaping (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<PinchSample, Int>) -> ()) {
        pinchGestureHandler = PinchGestureHandler(actionHandler: handler)
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: pinchGestureHandler, action: #selector(PinchGestureHandler.handleGestureRecognizer(_:)))
        pinchGestureRecognizer.cancelsTouchesInView = cancelsTouchesInLayer
        shouldRecognizeSimultaneouslyWithGesture = { _ in return false }
        
        pinchGestureDelegate = GestureRecognizerBridge(self)
    }
    
    internal let pinchGestureRecognizer: UIPinchGestureRecognizer
    fileprivate let pinchGestureHandler: PinchGestureHandler
    fileprivate var pinchGestureDelegate: SystemGestureRecognizerDelegate!
    
    open var underlyingGestureRecognizer: SystemGestureRecognizer {
        return pinchGestureRecognizer
    }

    open var shouldRecognizeSimultaneouslyWithGesture: (GestureType) -> Bool
    
    open weak var hostLayer: Layer? {
        didSet { handleTransferOfGesture(self, fromLayer: oldValue, toLayer: hostLayer) }
    }
    
    deinit {
        pinchGestureRecognizer.removeTarget(pinchGestureHandler, action: #selector(PinchGestureHandler.handleGestureRecognizer(_:)))
    }
    
    @objc class PinchGestureHandler: NSObject {
        fileprivate let actionHandler: (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<PinchSample, Int>) -> ()
        fileprivate var sampleSequence: SampleSequence<PinchSample, Int>?
        
        init(actionHandler: @escaping (_ phase: ContinuousGesturePhase, _ sampleSequence: SampleSequence<PinchSample, Int>) -> ()) {
            self.actionHandler = actionHandler
        }
        
        func handleGestureRecognizer(_ gestureRecognizer: SystemGestureRecognizer) {
            let scaleGesture = gestureRecognizer as! UIPinchGestureRecognizer
            
            let scale = Double(scaleGesture.scale)
            let velocity = Double(scaleGesture.velocity)
            
            let centroidPoint = scaleGesture.location(in: nil)
            let touchSample = TouchSample(globalLocation: Point(centroidPoint), timestamp: Timestamp.currentTimestamp)
            let sample = PinchSample(scale: scale, velocity: velocity, centroid: touchSample)
            
            switch scaleGesture.state {
            case .began:
                struct IDState { static var nextSequenceID = 0 }
                sampleSequence = SampleSequence(samples: [sample], id: IDState.nextSequenceID)
                IDState.nextSequenceID += 1
                
            case .changed, .ended, .cancelled:
                sampleSequence = sampleSequence!.sampleSequenceByAppendingSample(sample)
                
            case .possible, .failed:
                fatalError("Unexpected gesture state")
            }
            
            actionHandler(ContinuousGesturePhase(scaleGesture.state)!, sampleSequence!)
            
            switch scaleGesture.state {
            case .ended, .cancelled:
                sampleSequence = nil
            case .began, .changed, .possible, .failed:
                break
            }
        }
    }
}
	
#endif

/** Continuous gestures are different from discrete gestures in that they pass through several phases.
	A discrete gesture simply recognizes--then it's done. A continuous gesture begins, then may change
	over the course of several events, then ends (or is cancelled). */
public enum ContinuousGesturePhase {
	case began
	case changed
	case ended
	case cancelled
}

extension ContinuousGesturePhase: CustomStringConvertible {
	public var description: String {
		switch self {
		case .began:
			return "Began"
		case .changed:
			return "Changed"
		case .ended:
			return "Ended"
		case .cancelled:
			return "Cancelled"
		}
	}
}

private extension ContinuousGesturePhase {
	init?(_ uiGestureState: SystemGestureRecognizerState) {
		switch uiGestureState {
		case .possible, .failed:
			return nil
		case .began:
			self = .began
		case .changed:
			self = .changed
		case .ended:
			self = .ended
		case .cancelled:
			self = .cancelled
		}
	}
}

// MARK: - Samples and sequences

public protocol SampleType: CustomStringConvertible {
    
}

// MARK: SampleSequenceType
public protocol SampleSequenceType : CustomStringConvertible {
    associatedtype Sample
    associatedtype ID : CustomStringConvertible
    
    var samples: [Sample] { get }
    
    var id: ID { get }
    
    var firstSample: Sample! { get }
    
    var previousSample: Sample? { get }
    
    var currentSample: Sample! { get }
    
    init(samples: [Sample], id: ID)
    
    func sampleSequenceByAppendingSample(_ sample: Sample) -> Self
    
    static func +(a: Self, b: Sample) -> Self

    static func +(a: Self, b: Self) -> Self
}

public func +<Seq: SampleSequenceType, S>(a: Seq, b: S) -> Seq where S == Seq.Sample {
    return a.sampleSequenceByAppendingSample(b)
}

public func +<Seq: SampleSequenceType>(a: Seq, b: Seq) -> Seq {
    return Seq(samples:a.samples + b.samples, id:a.id)
}

// MARK: Concrete SampleSequence

/** Represents a series of samples over time.
    Provides convenience methods for accessing samples that might be relevant
    when processing gestures. */
public struct SampleSequence<S: SampleType, I: CustomStringConvertible> : SampleSequenceType {
    public typealias Sample = S
    public typealias ID = I

    /** Samples ordered by arrival time. */
    public let samples: [Sample]
    
    /** An identifier that can be used to distinguish this sequence from e.g. other
    sequences that might be proceeding simultaneously. You might think of it as
    a "finger identifier". */
    public var id: ID
    
    /** The first sample. */
    public var firstSample: Sample! {
        return samples.first
    }
    
    /** The next-to-last sample (if one exists). */
    public var previousSample: Sample? {
        let index = samples.count - 2
        return index >= 0 ? samples[index] : nil
    }
    
    /** The most recent sample. */
    public var currentSample: Sample! {
        return samples.last
    }
    
    public init(samples: [Sample], id: ID) {
        precondition(samples.count >= 0)
        self.samples = samples
        self.id = id
    }
    
    /** Create a new sequence by adding a sample onto the end of the sample list. */
    public func sampleSequenceByAppendingSample(_ sample: Sample) -> SampleSequence<Sample, ID> {
        return SampleSequence(samples: samples + [sample], id: id)
    }
    
    public var description: String {
        return "{id: \(id), samples: \(samples)}"
    }
}

// MARK: TouchSequence Decorator

/** Represents a series of touch samples over time.
This is a decorator on SampleSequence, specializing it to use touch samples
and extending it with velocity calculation and smoothing methods */
public struct TouchSequence<I: CustomStringConvertible> : SampleSequenceType {
    public typealias Sample = TouchSample
    public typealias ID = I
    
    /** Inner sequence */
    fileprivate let sequence: SampleSequence<TouchSample, ID>
    
    /** Touch samples ordered by arrival time. */
    public var samples: [TouchSample] {
        return sequence.samples
    }
    
    /** An identifier that can be used to distinguish this touch sequence from e.g. other
    touch sequences that might be proceeding simultaneously. You might think of it as
    a "finger identifier". */
    public var id: ID {
        return sequence.id
    }
    
    /** The first touch sample. */
    public var firstSample: TouchSample! {
        return sequence.firstSample
    }
    
    /** The next-to-last touch sample (if one exists). */
    public var previousSample: TouchSample? {
        return sequence.previousSample
    }
    
    /** The most recent touch sample. */
    public var currentSample: TouchSample! {
        return sequence.currentSample
    }
    
    public init(samples: [TouchSample], id: ID) {
        self.sequence = SampleSequence(samples: samples, id: id)
    }
    
    /** The approximate current velocity of the touch sequence, specified in points per second
    in the layer's coordinate space. */
    public func currentVelocityInLayer(_ layer: Layer) -> Point {
        if samples.count <= 1 {
            return Point()
        } else {
            let velocitySmoothingFactor = 0.1
            func velocitySampleFromSample(_ a: TouchSample, toSample b: TouchSample) -> Point {
                return (b.locationInLayer(layer) - a.locationInLayer(layer)) / (b.timestamp - a.timestamp)
            }
            
            var velocity = velocitySampleFromSample(samples[0], toSample: samples[1])
            for sampleIndex in 2..<samples.count {
                velocity = velocity * velocitySmoothingFactor + velocitySampleFromSample(samples[sampleIndex - 1], toSample: samples[sampleIndex]) * (1 - velocitySmoothingFactor)
            }
            return velocity
        }
    }
    
    /** The approximate current velocity of the touch sequence, specified in points per second
    in the root layer's coordinate space. */
    public func currentGlobalVelocity() -> Point {
        return currentVelocityInLayer(Layer.root)
    }
	
	/** The location of the current touch, in the root layer's coordinate space. */
	public var currentGlobalLocation: Point {
		return currentSample.globalLocation
	}
    
    /** Create a new touch sequence by adding a sample onto the end of the sample list. */
    public func sampleSequenceByAppendingSample(_ sample: TouchSample) -> TouchSequence<ID> {
        return TouchSequence(samples: samples + [sample], id: id)
    }
    
    public var description: String {
        return sequence.description
    }
}

// MARK: Gesture-to-gesture interaction

//Need to have a way to map Gestures to UIGestureRecognizers
var gestureMap = [SystemGestureRecognizer:GestureType]()

func gestureForGestureRecognizer(_ gestureRecognizer: SystemGestureRecognizer) -> GestureType? {
    return gestureMap[gestureRecognizer]
}

@objc class GestureRecognizerBridge: NSObject, SystemGestureRecognizerDelegate {
    let gesture: GestureType
    
    init(_ gesture: GestureType) {
        self.gesture = gesture
        super.init()
        gesture.underlyingGestureRecognizer.delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: SystemGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: SystemGestureRecognizer) -> Bool {
        if let otherGesture = gestureForGestureRecognizer(otherGestureRecognizer) {
            return gesture.shouldRecognizeSimultaneouslyWithGesture(otherGesture)
        }
        return false
    }
}

// MARK: - Internal interfaces

public protocol GestureType: _GestureType {
    var shouldRecognizeSimultaneouslyWithGesture: (GestureType) -> Bool { get set }
}

private func handleTransferOfGesture(_ gesture:GestureType, fromLayer: Layer?, toLayer: Layer?) {
    let recognizer = gesture.underlyingGestureRecognizer
    
    switch (fromLayer, toLayer) {
    case (.none, .some):
        gestureMap[recognizer] = gesture
    case (.some, .none):
        gestureMap.removeValue(forKey: recognizer)
    default:
        ()
    }
    
	if fromLayer !== toLayer {
		fromLayer?.view.removeGestureRecognizer(recognizer)
		toLayer?.view.addGestureRecognizer(recognizer)
	}
}

#if os(iOS)
	public typealias SystemGestureRecognizer = UIGestureRecognizer
	typealias SystemTapGestureRecognizer = UITapGestureRecognizer
	typealias SystemPanGestureRecognizer = UIPanGestureRecognizer
	typealias SystemLongPressGestureRecognizer = UILongPressGestureRecognizer
	typealias SystemRotationGestureRecognizer = UIRotationGestureRecognizer
	
	typealias SystemGestureRecognizerDelegate = UIGestureRecognizerDelegate
	typealias SystemGestureRecognizerState = UIGestureRecognizerState
	typealias SystemTouch = UITouch
#else
	public typealias SystemGestureRecognizer = NSGestureRecognizer
	typealias SystemTapGestureRecognizer = NSClickGestureRecognizer
	private typealias SystemPanGestureRecognizer = NSPanGestureRecognizer
	typealias SystemLongPressGestureRecognizer = NSPressGestureRecognizer
	typealias SystemRotationGestureRecognizer = NSRotationGestureRecognizer
	
	typealias SystemGestureRecognizerDelegate = NSGestureRecognizerDelegate
	typealias SystemGestureRecognizerState = NSGestureRecognizerState
	typealias SystemTouch = NSTouch
	
	extension SystemGestureRecognizer {
		var cancelsTouchesInView: Bool {
			get { return false }
			set { print("`cancelsTouchesInView` is unsupported on OS X, but I was too lazy to compile it out everywhere.") }
		}
	}
	
	// Currently unused class that's supposed to work with the system's auto scrolling behaviour.
	// it doesn't work super well!
	private class AutoScrollingPanGestureRecognizer: NSPanGestureRecognizer {
		
		var repeater: Repeater?
		
		override func mouseDown(with event: NSEvent) {
			super.mouseDown(with: event)
			
		}
		
		override func mouseDragged(with event: NSEvent) {
			super.mouseDragged(with: event)
//			view?.autoscroll(with: event)
			repeater?.cancel()
			repeater = nil
			repeater = Repeater(interval: 0.1, work: { [weak self] in
				print("boop")
				self?.view?.autoscroll(with: event)
			})
		}
		
		override func mouseUp(with event: NSEvent) {
			super.mouseUp(with: event)
			repeater?.cancel()
			repeater = nil
		}
	}
#endif

public protocol _GestureType {
	weak var hostLayer: Layer? { get nonmutating set }
	var underlyingGestureRecognizer: SystemGestureRecognizer { get }
}

public func ==(lhs: _GestureType,rhs: _GestureType) -> Bool {
    return lhs.underlyingGestureRecognizer == rhs.underlyingGestureRecognizer
}

#if os(iOS)
extension TouchSample {
	init(_ touch: SystemTouch) {
		globalLocation = Point(touch.location(in: nil))
		preciseGlobalLocation = Point(touch.preciseLocation(in: nil))
		timestamp = Timestamp(touch.timestamp)
		
		let forceTouchAvailable =
			UIScreen.main.traitCollection.forceTouchCapability == .available
			|| touch.type == .stylus
		
		absoluteForce = forceTouchAvailable ? Double(touch.force) : nil
		force = forceTouchAvailable ? Double(touch.force / touch.maximumPossibleForce) : nil
	}
}
#endif
