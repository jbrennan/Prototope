//
//  Layer+Layout.swift
//  Prototope
//
//  Created by Jason Brennan on 2015-02-13.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif


/** Positioning layers. */
extension Layer {
	
	
	/** The minX of the layer's frame. */
	public var originX: Double {
		get { return self.frame.minX }
		set { self.frame.origin.x = newValue }
	}
	
	
	/** The maxX of the layer's frame. */
	public var frameMaxX: Double {
		get { return self.frame.maxX }
		set { originX = newValue - width }
	}
	
	
	/** The minY of the layer's frame. */
	public var originY: Double {
		get { return self.frame.minY }
		set { self.frame.origin.y = newValue }
	}
	
	
	/** The maxY of the layer's frame. */
	public var frameMaxY: Double {
		get { return self.frame.maxY }
		set { originY = newValue - height }
	}
	
	
	/// Represents which kind of axis alignment to perform.
	public enum AxisAlignment {
		
		/// Align on the leading edge. For horizontal alignment, this is the left edge; for vertical, this is the top edge.
		case leading
		
		/// Align on the trailing edge. For horizontal alignment, this is the right edge; for vertical, this is the bottom edge.
		case trailing
		
		/// Align on the center.
		case center
		
		/// No alignment, leave things as they are.
		case none
	}
	
	
	/** Moves the receiver to the right of the given sibling layer. By default, this automatically aligns the receiver vertically to the leading edge of `sublingLayer`. Provide a different `adjacentAlignmentAxis` to override this. */
	public func moveToRightOfSiblingLayer(_ siblingLayer: Layer, margin: Double = 0.0, adjacentAxisAlignment: AxisAlignment = .leading) {
		self.originX = floor(siblingLayer.frameMaxX + margin)
		alignVertically(adjacentAxisAlignment, with: siblingLayer)
	}
	
	
	/** Moves the receiver to the left of the given sibling layer. By default, this automatically aligns the receiver vertically to the leading edge of `sublingLayer`. Provide a different `adjacentAlignmentAxis` to override this.*/
	public func moveToLeftOfSiblingLayer(_ siblingLayer: Layer, margin: Double = 0.0, adjacentAxisAlignment: AxisAlignment = .leading) {
		self.originX = floor(siblingLayer.originX - (self.width + margin))
		alignVertically(adjacentAxisAlignment, with: siblingLayer)
	}
	
	
	/** Moves the receiver vertically below the given sibling layer. By default, this automatically aligns the receiver horizontally to the leading edge of `sublingLayer`. Provide a different `adjacentAlignmentAxis` to override this. */
	public func moveBelowSiblingLayer(_ siblingLayer: Layer, margin: Double = 0.0, adjacentAxisAlignment: AxisAlignment = .leading) {
		self.originY = siblingLayer.frameMaxY + margin
		alignHorizontally(adjacentAxisAlignment, with: siblingLayer)
	}
	
	
	/** Moves the receiver vertically above the given sibling layer. By default, this automatically aligns the receiver horizontally to the leading edge of `sublingLayer`. Provide a different `adjacentAlignmentAxis` to override this. */
	public func moveAboveSiblingLayer(_ siblingLayer: Layer, margin: Double = 0.0, adjacentAxisAlignment: AxisAlignment = .leading) {
		self.originY = siblingLayer.originY - (self.height + margin)
		alignHorizontally(adjacentAxisAlignment, with: siblingLayer)
	}
	
	private func alignHorizontally(_ alignment: AxisAlignment, with siblingLayer: Layer) {
		switch alignment {
		case .leading:
			originX = siblingLayer.originX
		case .trailing:
			frameMaxX = siblingLayer.frameMaxX
		case .center:
			x = siblingLayer.x
		case .none:
			break
		}
	}
	
	private func alignVertically(_ alignment: AxisAlignment, with siblingLayer: Layer) {
		switch alignment {
		case .leading:
			originY = siblingLayer.originY
		case .trailing:
			frameMaxY = siblingLayer.frameMaxY
		case .center:
			y = siblingLayer.y
		case .none:
			break
		}
	}
	
	
	/** Moves the receiver so that its right side is aligned with the right side of its parent layer. */
	public func moveToRightSideOfParentLayer(margin: Double = 0.0) {
		if let parent = self.parent {
			self.originX = floor(parent.width - self.width - margin)
		}
	}
	
	
	/** Moves the receiver so that its left side is aligned with the left side of its parent layer. */
	public func moveToLeftSideOfParentLayer(margin: Double = 0.0) {
		if self.parent != nil {
			self.originX = margin
		}
	}
	
	
	/** Moves the receiver so that its top side is aligned with the top side of its parent layer. */
	public func moveToTopSideOfParentLayer(margin: Double = 0.0) {
		if self.parent != nil {
			self.originY = margin
		}
	}
	
	
	/** Moves the receiver so that its bottom side is aligned with the bottom side of its parent layer. */
	public func moveToBottomSideOfParentLayer(margin: Double = 0.0) {
		if let parent = self.parent {
			self.originY = floor(parent.height - self.height - margin)
		}
	}
	
	
	/** Moves the receiver to be vertically centred in its parent. */
	public func moveToVerticalCenterOfParentLayer() {
		if let parent = self.parent {
			self.originY = floor(parent.height / 2.0 - self.height / 2.0)
		}
	}
	
	
	/** Moves the receiver to be horizontally centred in its parent. */
	public func moveToHorizontalCenterOfParentLayer() {
		if let parent = self.parent {
			self.originX = floor(parent.width / 2.0 - self.width / 2.0)
		}
	}
	
	
	/** Moves the receiver to be centered in its parent. */
	public func moveToCenterOfParentLayer() {
		self.moveToVerticalCenterOfParentLayer()
		self.moveToHorizontalCenterOfParentLayer()
	}
	
}

