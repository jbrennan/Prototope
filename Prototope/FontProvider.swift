//
//  FontProvider.swift
//  Prototope
//
//  Created by Saniul Ahmed on 15/06/2015.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import Foundation

open class FontProvider {
	static fileprivate let supportedExtensions = ["ttf", "otf"]
	
	let resources: [String : Data]
	
	var registeredFontsURLs = [URL]()
	
	public init(resources: [String : Data]) {
		self.resources = resources
	}
	
	deinit {
		for URL in registeredFontsURLs {
			var fontError: Unmanaged<CFError>?
			if CTFontManagerUnregisterFontsForURL(URL as CFURL, CTFontManagerScope.process, &fontError) {
				print("Successfully unloaded font: '\(URL)'.")
			} else if let fontError = fontError?.takeRetainedValue() {
				let errorDescription = CFErrorCopyDescription(fontError)
				print("Failed to unload font '\(URL)': \(errorDescription)")
			} else {
				print("Failed to unload font '\(URL)'.")
			}
		}
	}
	
	func resourceForFontWithName(_ name: String) -> Data? {
		for fileExtension in FontProvider.supportedExtensions {
			if let data = resources[name + ".\(fileExtension)"] {
				return data
			}
		}
		
		return nil
	}
	
	open func fontForName(_ name: String, size: Double) -> UIFont? {
		if let font = UIFont(name: name, size: CGFloat(size)) {
			return font
		}
		
		if let customFontData = resourceForFontWithName(name) {
			let URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first as Foundation.URL!
			
			let fontFileURL = URL?.appendingPathComponent(name)
			
			try? customFontData.write(to: fontFileURL!, options: [.atomic])
			
			var fontError: Unmanaged<CFError>?
			if CTFontManagerRegisterFontsForURL(fontFileURL as! CFURL, CTFontManagerScope.process, &fontError) {
				// FIXME!
//				registeredFontsURLs += [fontFileURL]
				
				print("Successfully loaded font: '\(name)'.")
				if let font = UIFont(name: name, size: CGFloat(size)) {
					return font
				}
			} else if let fontError = fontError?.takeRetainedValue() {
				let errorDescription = CFErrorCopyDescription(fontError)
				print("Failed to load font '\(name)': \(errorDescription)")
			} else {
				print("Failed to load font '\(name)'.")
			}
		}
		
		return nil
	}
}
