//
//  ResizeBehavior.swift
//  PrototopeOSX
//
//  Created by Jason Brennan on 2018-07-14.
//  Copyright © 2018 Jason Brennan. All rights reserved.
//

/// Provides basic "drag to resize" behaviour to the associated layer.
open class ResizeBehavior {
	
	public enum Style {
		
		/// Resizes the layer based solely on the axis being dragged.
		case axesIndependent
		
		/// Resizes the layer such that its proportions remain the same. This means eg dragging a rectangular layer from the right axis will also cause the layer's height to change as well as its width.
		case proportionally
	}
	
	private unowned var layer: Layer
	public var style: Style
	
	public var layerDidResizeHandler: ((Layer) -> Void)?
	
	/// Whether or not the resize behaviour is currently enabled.
	open var enabled = true
	
	private var currentlyDraggedResizer: ResizeHandle? {
		didSet {
			layer.dragBehavior?.enabled = currentlyDraggedResizer == nil
		}
	}
	
	/// Initializes the resize behaviour with the given layer (which is `unowned` by the behaviour).
	@discardableResult public init(layer: Layer, resizingStyle: Style = .axesIndependent) {
		self.layer = layer
		self.style = resizingStyle
		layer.resizeBehavior = self
	}
	
	func mouseDown(with event: InputEvent) {
		guard enabled else { return }
		currentlyDraggedResizer = ResizeHandle(location: event.locationInLayer(layer: layer), layerSize: layer.size)
	}
	
	func mouseMoved(with event: InputEvent) {
		guard enabled else { return }
		guard let resizerUnderMouse = ResizeHandle(location: event.locationInLayer(layer: layer), layerSize: layer.size) else {
			if self.currentlyDraggedResizer == nil {
				Cursor.set(cursorAppearance: .arrow)
			}
			return
		}
		
		Cursor.set(cursorAppearance: resizerUnderMouse.cursorAppearance)
	}
	
	func mouseExited() {
		if self.currentlyDraggedResizer == nil {
			Cursor.set(cursorAppearance: .arrow)
		}
	}
	
	func mouseDragged(with event: InputEvent) {
		guard enabled else { return }
		guard let currentlyDraggedResizer = currentlyDraggedResizer else { return }
		
		let location = event.locationInLayer(layer: layer)
		let topResize = {
			
			let oldHeight = self.layer.size.height
			
			// the new height is the old height + the amount we've gone above the origin (which is usually negative, so we flip it)
			let newHeight = (-1.0 * location.y + oldHeight).clamp(lower: 10, upper: Double.greatestFiniteMagnitude)
			self.layer.size.height = newHeight
			self.layer.originY += location.y
			
			if self.style == .proportionally {
				let ratio = self.layer.size.height / oldHeight
				self.layer.size.width *= ratio
			}
		}
		
		let leftResize = {
			let oldWidth = self.layer.size.width
			
			self.layer.size.width = (-1.0 * location.x + oldWidth).clamp(lower: 10, upper: Double.greatestFiniteMagnitude)
			self.layer.originX += location.x
			
			if self.style == .proportionally {
				let ratio = self.layer.size.width / oldWidth
				self.layer.size.height *= ratio
			}
		}
		
		let rightResize = {
			let oldWidth = self.layer.size.width
			self.layer.size.width = location.x.clamp(lower: 10, upper: Double.greatestFiniteMagnitude)
			
			if self.style == .proportionally {
				let ratio = self.layer.size.width / oldWidth
				self.layer.size.height *= ratio
			}
		}
		
		let bottomResize = {
			let oldHeight = self.layer.size.height
			self.layer.size.height = location.y.clamp(lower: 10, upper: Double.greatestFiniteMagnitude)
			
			if self.style == .proportionally {
				let ratio = self.layer.size.height / oldHeight
				self.layer.size.width *= ratio
			}
		}
		
		switch currentlyDraggedResizer {
		case .topLeft:
			topResize()
			leftResize()
		case .top:
			topResize()
		case .topRight:
			topResize()
			rightResize()
		case .left:
			leftResize()
		case .right:
			rightResize()
		case .bottomLeft:
			bottomResize()
			leftResize()
		case .bottom:
			bottomResize()
		case .bottomRight:
			bottomResize()
			rightResize()
		}
		
		layerDidResizeHandler?(layer)
	}
	
	func mouseUp() {
		currentlyDraggedResizer = nil
	}
	
	private enum ResizeHandle {
		
		case topLeft, top, topRight
		case left, right
		case bottomLeft, bottom, bottomRight
		
		init?(location: Point, layerSize: Size) {
			let borderWidth = 5.0
			if location.y < borderWidth {
				// it's at the top
				if location.x < borderWidth {
					self = .topLeft
				} else if location.x > layerSize.width - borderWidth {
					self = .topRight
				} else {
					self = .top
				}
				return
			}
			
			if location.y > layerSize.height - borderWidth {
				// it's at the bottom
				if location.x < borderWidth {
					self = .bottomLeft
				} else if location.x > layerSize.width - borderWidth {
					self = .bottomRight
				} else {
					self = .bottom
				}
				return
			}
			
			if location.x < borderWidth {
				// it's on the left
				self = .left
				return
			}
			
			if location.x > layerSize.width - borderWidth {
				// it's on the right
				self = .right
				return
			}
			
			return nil
		}
		
		var cursorAppearance: Cursor.Appearance {
			switch self {
			case .topLeft, .bottomRight: return .downwardDiagonalResizer
			case .top, .bottom: return .verticalResizer
			case .topRight, .bottomLeft: return .upwardDiagonalResizer
			case .left, .right: return .horizontalResizer
			}
		}
	}
}

protocol ResizableView: class {
	var resizeBehavior: ResizeBehavior? { get set }
}

