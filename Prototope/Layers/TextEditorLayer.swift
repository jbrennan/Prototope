//
//  TextEditorLayer.swift
//  PrototopeOSX
//
//  Created by Jason Brennan on 2017-10-05.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import Cocoa

/// Wraps `NSTextView`
open class TextEditorLayer: Layer {
	
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
		
		super.init(parent: parent, name: name, viewClass: NSTextView.self)
		
		textView.wantsLayer = true
		textView.delegate = notificationHandler
	}
	
	open var textView: NSTextView {
		return view as! NSTextView
	}
	
	open var text: String {
		get { return textView.string }
		set { textView.string = newValue }
	}
	
	open var font: SystemFont {
		get { return textView.font ?? SystemFont.systemFont(ofSize: SystemFont.systemFontSize) }
		set { textView.font = newValue }
	}
	
	private class NotificationHandler: NSObject, NSTextViewDelegate {
		var textDidBeginEditingHandler: VoidHandler?
		var textDidChangeHandler: VoidHandler?
		var textDidEndEditingHandler: VoidHandler?
		
		@objc func textDidBeginEditing(_ notification: Notification) {
			textDidBeginEditingHandler?()
		}
		
		@objc func textDidChange(_ notification: Notification) {
			textDidChangeHandler?()
		}
		
		@objc func textDidEndEditing(_ notification: Notification) {
			textDidEndEditingHandler?()
		}
	}
}
