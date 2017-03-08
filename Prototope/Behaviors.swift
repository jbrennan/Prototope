//
//  Collisions.swift
//  Prototope
//
//  Created by Saniul Ahmed on 07/02/2015.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

//MARK: Public Behavior Types

/** Protocol for types describing the "configuration" of a behavior. */
public protocol BehaviorType {}

/** Describes a behavior that just calls a closure/block on every heartbeat,
    passing the host layer to the closure. */
public struct ActionBehavior: BehaviorType {
    let handler: (Layer) -> Void
    
    public init(handler: @escaping (Layer)->Void) {
        self.handler = handler
    }
}

/** Value type describing the configuration of a collision behavior, specifying
 the layer with which the host layer is supposed to be colliding and a handler function */
public struct CollisionBehavior: BehaviorType {
    public enum Kind {
        case entering
        case leaving
    }
    
    let otherLayer: Layer
    let handler: (CollisionBehavior.Kind)->Void
    
    public init(with otherLayer: Layer, handler: @escaping (CollisionBehavior.Kind)->Void) {
        self.otherLayer = otherLayer
        self.handler = handler
    }
}

//MARK: Behavior Bindings

/** Abstract. Describes a relationship between a layer and a single instance of a behavior.
 Subclasses should encapsulate the state necessary to handle the behavior correctly. */
class BehaviorBinding: Equatable, Hashable {
    let id: Int
    let hostLayer: Layer
    
	static var behaviorCounter = 0
    
    init(hostLayer: Layer) {
        self.id = BehaviorBinding.behaviorCounter
		BehaviorBinding.behaviorCounter += 1
		
        self.hostLayer = hostLayer
    }
    
    func update() {
        fatalError("BehaviorBinding.update must be overridden")
    }
    
    var hashValue: Int {
        return id
    }
}

func ==(b1: BehaviorBinding, b2: BehaviorBinding) -> Bool {
    return b1.id == b2.id
}

/** Possible collision states for a pair of layers */
enum CollisionState {
    case nonOverlapping
    case partiallyIntersects
    case containedIn
    case contains
    
    static func stateForLayer(_ layer1: Layer, andLayer layer2: Layer) -> CollisionState {
        let rect1 = Layer.root.view.convert(CGRect(layer1.frame), from:layer1.view.superview)
        let rect2 = Layer.root.view.convert(CGRect(layer2.frame), from:layer2.view.superview)
        
        if !rect1.intersects(rect2) {
            return .nonOverlapping
        }
        
        if rect1.contains(rect2) {
            return .contains
        } else if rect2.contains(rect1) {
            return .containedIn
        }
        
        return .partiallyIntersects
    }
}

/** Concrete class encapsulating the necessary state for CollisionBehaviors */
class CollisionBehaviorBinding : BehaviorBinding {
    var previousState: CollisionState
    let config: CollisionBehavior
    
    init(hostLayer: Layer, config: CollisionBehavior) {
        self.config = config
        self.previousState = CollisionState.stateForLayer(hostLayer, andLayer: self.config.otherLayer)
        
        super.init(hostLayer: hostLayer)
    }

    override func update() {
        self.updateWithState(CollisionState.stateForLayer(self.hostLayer, andLayer: self.config.otherLayer))
    }
    
    func updateWithState(_ state: CollisionState) {
        let kind: CollisionBehavior.Kind?
        
        let old = previousState
        switch (old, state) {
            
        case (.nonOverlapping,.partiallyIntersects):
            fallthrough
        case (.nonOverlapping,.containedIn):
            fallthrough
        case (.nonOverlapping,.contains):
            kind = .entering
            
        case (.partiallyIntersects,.nonOverlapping):
            fallthrough
        case (.containedIn,.nonOverlapping):
            fallthrough
        case (.contains,.nonOverlapping):
            kind = .leaving
            
        default:
            kind = nil
        }
        
        kind.map(fire)
        self.previousState = state
    }
    
    func fire(_ kind: CollisionBehavior.Kind) {
        self.config.handler(kind)
    }
}

/** Concrete BehaviorBinding for ActionBehavior */
class ActionBehaviorBinding : BehaviorBinding {
    let config: ActionBehavior
    
    init(hostLayer: Layer, config: ActionBehavior) {
        self.config = config
        
        super.init(hostLayer: hostLayer)
    }
    
    override func update() {
        config.handler(hostLayer)
    }
}

//MARK: Behavior Driver

/** Manages all the behaviors in a given Environment */
class BehaviorDriver {
    var heartbeat: Heartbeat!
    
    var registeredBindings: Set<BehaviorBinding> {
        didSet {
            self.heartbeat.paused = self.registeredBindings.count == 0
        }
    }
    
    init() {
        self.registeredBindings = Set<BehaviorBinding>()
        
        self.heartbeat = Heartbeat { [unowned self] _ in
            self.tick()
        }
    }
    
    deinit {
        self.heartbeat.stop()
    }
    
    func tick() {
        for b in self.registeredBindings {
            b.update()
        }
    }
    
    func updateWithLayer(_ layer: Layer, behaviors: [BehaviorType]) {
        let knownBindings = self.registeredBindings.lazy.filter { $0.hostLayer == layer }
        
        let otherBindings = self.registeredBindings.subtracting(knownBindings)
        
        let newBindings = behaviors.map { b -> BehaviorBinding in
            return self.createBindingForLayer(layer, behavior: b)!
        }
        
        self.registeredBindings = otherBindings.union(newBindings)
    }
    
    func registerBinding(_ binding: BehaviorBinding) {
        self.registeredBindings.insert(binding)
    }
    
    func unregisterBinding(_ binding: BehaviorBinding) {
        self.registeredBindings.remove(binding)
    }
    
    func createBindingForLayer(_ layer: Layer, behavior: BehaviorType) -> BehaviorBinding? {
        if let collisionBehavior = behavior as? CollisionBehavior {
            return CollisionBehaviorBinding(hostLayer: layer, config: collisionBehavior)
        } else if let actionBehavior = behavior as? ActionBehavior {
            return ActionBehaviorBinding(hostLayer: layer, config: actionBehavior)
        }
        return nil
    }
}
