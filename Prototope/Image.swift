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
	public init(text: String, font: Font = Font(weight: .bold), textColor: Color = Color.black, maxWidth: Double? = nil) {
		
		self.init(Image.imageFromText(text, font: font, textColor: textColor, maxWidth: maxWidth))
		self.name = text
	}
	
	static func imageFromText(_ text: String, font: Font = Font(weight: .bold), textColor: Color = Color.black, maxWidth: Double? = nil) -> SystemImage {
		let attributes = [
			NSAttributedString.Key.font: font.systemFont,
			.foregroundColor: textColor.systemColor
		]
		let drawingRect = (text as NSString).boundingRect(
			with: NSSize(
				width: maxWidth ?? Double.greatestFiniteMagnitude,
				height: Double.greatestFiniteMagnitude),
			options: .usesLineFragmentOrigin,
			attributes: attributes)
		
		let renderer = GraphicsImageRenderer(size: drawingRect.size)
		return renderer.image { (context) in
			(text as NSString).draw(
				with: drawingRect,
				options: .usesLineFragmentOrigin, // needed to get multi-line text working
				attributes: attributes
			)
		}
	}
}

// MARK: - Resizing

public extension Image {
	
	/// Returns a copy of the receiver, resized to the given target size.
	///
	/// - Note: Does not maintain the image's aspect ratio, unless the target size does.
	func resized(to targetSize: Size) -> Image {
		Image(systemImage.resized(to: CGSize(targetSize)))
	}
	
	/// Returns a copy of the receiver, scaled in both directions to the given target scale.
	func scaled(by scale: Double) -> Image {
		resized(to: size * scale)
	}
}

private extension NSImage {
	func resized(to targetSize: CGSize) -> NSImage {
		let frame = CGRect(origin: .zero, size: targetSize)
		let representation = bestRepresentation(for: frame, context: nil, hints: nil)!
		return NSImage(size: targetSize, flipped: false) { _ in
			representation.draw(in: frame)
		}
	}
}

