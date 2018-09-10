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
	
	private let notificationHandler = NotificationHandler()
	
	open var textDidBeginEditingHandler: VoidHandler? {
		get { return notificationHandler.textDidBeginEditingHandler }
		set { notificationHandler.textDidBeginEditingHandler = newValue }
	}
	
	open var textDidChangeHandler: VoidHandler? {
		get { return notificationHandler.textDidChangeHandler }
		set { notificationHandler.textDidChangeHandler = newValue }
	}
	
	open var textDidEndEditingHandler: VoidHandler? {
		get { return notificationHandler.textDidEndEditingHandler }
		set { notificationHandler.textDidEndEditingHandler = newValue }
	}
	
	public init(parent: Layer? = nil, name: String? = nil) {
		NSTextField.cellClass = VerticallyCenteredTextFieldCell.self
		super.init(parent: parent, name: name, viewClass: SystemTextInputView.self)
		
		textField.wantsLayer = true
		textField.focusRingType = .none
		textField.isBordered = false
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(NotificationHandler.textDidBeginEditing),
			name: NSControl.textDidBeginEditingNotification, object: textField
		)
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(NotificationHandler.textDidChange),
			name: NSControl.textDidChangeNotification, object: textField
		)
		
		NotificationCenter.default.addObserver(
			notificationHandler,
			selector: #selector(NotificationHandler.textDidEndEditing),
			name: NSControl.textDidEndEditingNotification, object: textField
		)
	}
	
	var textField: SystemTextInputView {
		return view as! SystemTextInputView
	}
	
	open var text: String {
		get { return textField.stringValue }
		set { textField.stringValue = newValue }
	}
	
	open var textColor: Color {
		get { return Color(textField.textColor ?? SystemColor.textColor) }
		set { textField.textColor = newValue.systemColor }
	}
	
	open var placeholderText: String? {
		get { return textField.placeholderString }
		set { textField.placeholderString = newValue }
	}
	
	open var font: Font {
		get {
			let systemFont = textField.font ?? SystemFont.boldSystemFont(ofSize: SystemFont.systemFontSize)
			return Font(systemFont: systemFont)
		}
		set { textField.font = newValue.systemFont }
	}
	
	open var isEditable: Bool {
		get { return textField.isEditable }
		set { textField.isEditable = newValue }
	}
	
	open func becomeFocussed() {
		textField.window?.makeFirstResponder(textField)
	}
	
	open func endBeingFocussed() {
		textField.window?.makeFirstResponder(textField.window)
	}
	
	open func resizeToFitText() {
		textField.sizeToFit()
	}
	
	private class NotificationHandler: NSObject {
		var textDidBeginEditingHandler: VoidHandler?
		var textDidChangeHandler: VoidHandler?
		var textDidEndEditingHandler: VoidHandler?
		
		@objc func textDidBeginEditing() {
			textDidBeginEditingHandler?()
		}
		
		@objc func textDidChange() {
			textDidChangeHandler?()
		}
		
		@objc func textDidEndEditing() {
			textDidEndEditingHandler?()
		}
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
