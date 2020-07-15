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
	public init(parent: Layer? = nil, name: String? = nil) {
		
		super.init(parent: parent, name: name, viewClass: NSTextView.self)
		
		textView.wantsLayer = true
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
}
