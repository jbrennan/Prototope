//
//  TextInputLayer.swift
//  PrototopeOSX
//
//  Created by Jason Brennan on 2017-09-28.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import AppKit

typealias SystemTextInputView = NSTextField


open class TextInputLayer: Layer {
	
	public init(parent: Layer? = nil, name: String? = nil) {
		NSTextField.setCellClass(VerticallyCenteredTextFieldCell.self)
		super.init(parent: parent, name: name, viewClass: SystemTextInputView.self)
		
		textField.wantsLayer = true
		textField.focusRingType = .none
		textField.isBordered = false
	}
	
	var textField: SystemTextInputView {
		return view as! SystemTextInputView
	}
	
	open var text: String {
		get { return textField.stringValue }
		set { textField.stringValue = newValue }
	}
	
	open var font: SystemFont {
		get { return textField.font ?? SystemFont.boldSystemFont(ofSize: systemFontSize()) }
		set { textField.font = newValue }
	}

	private class VerticallyCenteredTextFieldCell: NSTextFieldCell {
		override func titleRect(forBounds rect: NSRect) -> NSRect {
			var titleRect = super.titleRect(forBounds: rect)
			
			let minimumHeight = self.cellSize(forBounds: rect).height
			titleRect.origin.y += (titleRect.height - minimumHeight) / 2
			titleRect.size.height = minimumHeight
			
			return titleRect
		}
		
		override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
			super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
		}
		
		override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
			super.select(withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength);
		}
	}
}
