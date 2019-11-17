//
//  Image.swift
//  Prototope
//
//  Created by Andy Matuschak on 10/16/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

#if os(iOS)
	import UIKit
	public typealias SystemImage = UIImage
	#else
	import AppKit
	
	public typealias SystemImage = NSImage
	extension SystemImage {
		var CGImage: CGImage {
			var rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
			return cgImage(forProposedRect: &rect, context: nil, hints: nil)!
		}
	}
#endif


/** A simple abstraction for a bitmap image. */
public struct Image: CustomStringConvertible {
	

	/** The size of the image, in points. */
	public var size: Size {
		return Size(systemImage.size)
	}

	public var name: String!

	var systemImage: SystemImage

	/** Loads a named image from the assets built into the app. */
	public init?(name: String) {
		if let image = Environment.currentEnvironment!.imageProvider(name) {
			systemImage = image
			self.name = name
		} else {
			Environment.currentEnvironment?.exceptionHandler("Image named \(name) not found")
			return nil
		}
	}

	/** Constructs an Image from a UIImage. */
	public init(_ image: SystemImage) {
		systemImage = image
	}
	
	
	public var description: String {
		return self.name
	}
}

// MARK: - Rendering Text

extension Image {
	
	/** Creates an image by rendering the given text into an image. */
	public init(text: String, font: Font = Font(weight: .bold), textColor: Color = Color.black) {
		
		self.init(Image.imageFromText(text, font: font, textColor: textColor))
		self.name = text
	}
	
	static func imageFromText(_ text: String, font: Font = Font(weight: .bold), textColor: Color = Color.black) -> SystemImage {
		let attributes = [NSAttributedString.Key.font: font.systemFont, NSAttributedString.Key.foregroundColor: textColor.systemColor]
		let size = (text as NSString).size(withAttributes: attributes)
		
		let renderer = GraphicsImageRenderer(size: size)
		return renderer.image { (context) in
			(text as NSString).draw(at: CGPoint(), withAttributes: attributes)
		}
	}
}

