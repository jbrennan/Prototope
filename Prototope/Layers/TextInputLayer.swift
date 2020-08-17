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
		self.font = Font()
		
		super.init(parent: parent, name: name, viewClass: SystemTextInputView.self)
		
		textField.wantsLayer = true
		textField.focusRingType = .none
		textField.isBordered = false
		textField.maximumNumberOfLines = 0
		textField.layerContentsRedrawPolicy = .beforeViewResize
		textField.font = self.font.systemFont
		
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
		didSet {
			textField.font = font.systemFont
		}
	}
	
	open var isEditable: Bool {
		get { return textField.isEditable }
		set { textField.isEditable = newValue }
	}
	
	open var alignment: TextAlignment {
		get { TextAlignment(systemTextAlignment: textField.alignment) }
		set { textField.alignment = newValue.systemTextAlignment }
	}
	
	open var lineBreakMode: LineBreakMode {
		get { LineBreakMode(systemLineBreakMode: textField.lineBreakMode) }
		set { textField.lineBreakMode = newValue.systemLineBreakMode }
	}
	
	open func becomeFocussed() {
		textField.window?.makeFirstResponder(textField)
	}
	
	open func endBeingFocussed() {
		textField.window?.makeFirstResponder(textField.window)
	}
	
	open var preferredMaxWidth: Double {
		get { return Double(textField.preferredMaxLayoutWidth) }
		set { textField.preferredMaxLayoutWidth = CGFloat(newValue) }
	}
	
	open func resizeToFitText() {
		textField.frame.size = textField.intrinsicContentSize
		textField.needsDisplay = true
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

public enum TextAlignment: CaseIterable {
	case leading
	case center
	case trailing
	case justified
	
	init(systemTextAlignment: NSTextAlignment) {
		switch systemTextAlignment {
		case .left: self = .leading
		case .right: self = .trailing
		case .center: self = .center
		case .justified: self = .justified
		case .natural: self = .leading
		}
	}
	
	var systemTextAlignment: NSTextAlignment {
		switch self {
		case .leading: return .left
		case .center: return .center
		case .trailing: return .right
		case .justified: return .justified
		}
	}
	
	public var title: String {
		switch self {
		case .leading: return "Leading"
		case .center: return "Center"
		case .trailing: return "Trailing"
		case .justified: return "Justified"
		}
	}
}

public enum LineBreakMode: CaseIterable {
    case byWordWrapping // Wrap at word boundaries, default
    case byCharWrapping // Wrap at character boundaries
    case byClipping // Simply clip
    case byTruncatingHead // Truncate at head of line: "...wxyz"
    case byTruncatingTail // Truncate at tail of line: "abcd..."
    case byTruncatingMiddle
	
	init(systemLineBreakMode: NSLineBreakMode) {
		switch systemLineBreakMode {
		case .byWordWrapping: self = .byWordWrapping
		case .byCharWrapping: self = .byCharWrapping
		case .byClipping: self = .byClipping
		case .byTruncatingHead: self = .byTruncatingHead
		case .byTruncatingTail: self = .byTruncatingTail
		case .byTruncatingMiddle: self = .byTruncatingMiddle
		}
	}
	
	var systemLineBreakMode: NSLineBreakMode {
		switch self {
		case .byWordWrapping: return .byWordWrapping
		case .byCharWrapping: return .byCharWrapping
		case .byClipping: return .byClipping
		case .byTruncatingHead: return .byTruncatingHead
		case .byTruncatingTail: return .byTruncatingTail
		case .byTruncatingMiddle: return .byTruncatingMiddle
		}
	}
	
	public var title: String {
		switch self {
		case .byWordWrapping: return "Word Wrap"
		case .byCharWrapping: return "Character Wrap"
		case .byClipping: return "Clip"
		case .byTruncatingHead: return "Truncate Head"
		case .byTruncatingTail: return "Truncate Tail"
		case .byTruncatingMiddle: return "Truncate Middle"
		}
	}
}
