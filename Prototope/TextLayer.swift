//
//  TextLayer.swift
//  Prototope
//
//  Created by Andy Matuschak on 2/15/15.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import UIKit

/**
	This layer draws text, optionally with word wrapping.

	It presently rasterizes the text to a bitmap, so applying a scale factor will result in fuzziness.

	It does not yet support truncation or heterogeneously styled text.

	If text is not being wrapped, then the layer's size will automatically grow to accommodate the full string. If text *is* being wrapped, the layer will respect its given width but will adjust its height to accommodate the full string. Except when the layer's size is directly being changed (i.e. via layer.width or layer.bounds.width--but not layer.frame.width), the layer's origin will be preserved if the size changes to accommodate the text. If the layer's size is changed direclty, then its position will be preserved.
*/
open class TextLayer: Layer {
	
	/** Text alignment */
	public enum Alignment {
		/** Visually left aligned */
		case left
		
		/** Visually centered */
		case center
		
		/** Visually right aligned */
		case right
		
		/** Fully-justified. The last line in a paragraph is natural-aligned. */
		case justified
		
		/** Indicates the default alignment for script */
		case natural
		
		internal func toNSTextAlignment() -> NSTextAlignment {
			switch self {
			case .left: return .left
			case .center: return .center
			case .right: return .right
			case .justified: return .justified
			case .natural: return .natural
			}
		}
		
		internal init(nsTextAlignment: NSTextAlignment) {
			switch nsTextAlignment {
			case .left: self = .left
			case .center: self = .center
			case .right: self = .right
			case .justified: self = .justified
			case .natural: self = .natural
			}
		}
	}
	
	open var text: String? {
		get {
			return label.text
		}
		set {
			label.text = newValue
			updateSize()
		}
	}

	open var fontName: String = "Futura" {
		didSet {
			updateFont()
			updateSize()
		}
	}

	open var fontSize: Double = 16 {
		didSet {
			updateFont()
			updateSize()
		}
	}

	open var textColor: Color {
		get { return Color(label.textColor) }
		set { label.textColor = newValue.systemColor }
	}

	open var wraps: Bool {
		get {
			return label.numberOfLines == 0
		}
		set {
			label.numberOfLines = newValue ? 0 : 1
			updateSize() // Adjust width/height as necessary for new wrapping mode.
		}
	}
	
	open var textAlignment: Alignment {
		get {
			return Alignment(nsTextAlignment: label.textAlignment)
		}
		set {
			label.textAlignment = newValue.toNSTextAlignment()
			//No need to adjust size, since changing alignment doesn't influence it
		}
	}
	
	/** Distance from top of layer to the first line's baseline */
	open var baselineHeight: Double {
		return Double(label.font.ascender)
	}
	
	/** Aligns this layer's first baseline with the first baseline of the other layer */
	open func alignWithBaselineOf(_ otherLayer: TextLayer) {
		let delta = pixelAwareCeil(otherLayer.baselineHeight-baselineHeight)
		
		self.frame.origin.y = otherLayer.frame.minY + delta
	}
	
	open override var frame: Rect {
		didSet {
			// Respect the new width; resize height so as not to truncate.
			if wraps {
				updateSize()
			}
		}
	}

	open override var bounds: Rect {
		didSet {
			// Respect the new width; resize height so as not to truncate.
			if wraps {
				let position = self.position
				label.sizeToFit()
				self.position = position
			}
		}
	}
	
	fileprivate func updateFont() {
		if let font = Environment.currentEnvironment!.fontProvider(fontName, fontSize) {
			label.font = font
		} else {
			Environment.currentEnvironment?.exceptionHandler("Couldn't find a font named \(fontName)")
		}
		updateSize()
	}

	fileprivate func updateSize() {
        let prePoint = self.sizeUpdatePivotPoint()
		label.sizeToFit()
        let postPoint = self.sizeUpdatePivotPoint()
        let delta = postPoint - prePoint
        self.position -= delta
    }
    
    func sizeUpdatePivotPoint() -> Point {
        switch self.textAlignment {
        case .natural: // assume left for .Natural
            fallthrough
        case .justified:
            fallthrough
            case .left:
            return Point(x: self.frame.minX, y: self.frame.minY)
        case .right:
            return Point(x: self.frame.maxX, y: self.frame.minY)
        case .center:
            return Point(x: self.frame.midX, y: self.frame.minY)
        }
    }
    
    fileprivate var label: UILabel {
		return self.view as! UILabel
	}

	public init(parent: Layer? = Layer.root, name: String? = nil) {
		super.init(parent: parent, name: name, viewClass: UILabel.self)
		updateFont()
	}
}
