//
//  DragBehavior.swift
//  Prototope
//
//  Created by Jason Brennan on 2017-08-03.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//


/// Provides basic drag and drop functionality for the associated layer.
open class DragBehavior {
	private unowned var layer: Layer
	private var initialPositionInLayer = Point()
	
	/// Whether or not the drag behaviour is currently enabled.
	open var enabled = true
	
	public typealias Delta = Point
	public var layerDidDragHandler: ((Layer, Delta) -> Void)?
	
	/// Initializes the behaviour and attaches it to the given layer. They layer will be unowned by the behaviour.
	@discardableResult public init(layer: Layer) {
		self.layer = layer
		layer.dragBehavior = self
	}
	
	func dragDidBegin(atLocationInLayer locationInLayer: Point) {
		guard enabled else { return }
		initialPositionInLayer = locationInLayer
		layer.comeToFront()
	}
	
	func dragDidChange(atLocationInParentLayer locationInParentLayer: Point) {
		guard enabled else { return }
		let oldLayerOrigin = layer.origin
		layer.origin = locationInParentLayer - initialPositionInLayer
		
		// call the handler with the layer's origin's delta
		layerDidDragHandler?(layer, layer.origin - oldLayerOrigin)
	}
}

protocol DraggableView: class {
	var dragBehavior: DragBehavior? { get set }
}
