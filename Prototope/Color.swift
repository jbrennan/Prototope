//
//  Color.swift
//  Prototope
//
//  Created by Andy Matuschak on 10/7/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

#if os(iOS)
	import UIKit
	typealias SystemColor = UIColor
#else
	import AppKit
	typealias SystemColor = NSColor
#endif


/** A simple representation of color. */
public struct Color {
	let systemColor: SystemColor
	
	/** The underlying CGColor of this colour. */
	var CGColor: CGColor {
		return self.systemColor.cgColor
	}

	/** Constructs a color from RGB and alpha values. Arguments range from 0.0 to 1.0. */
	public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
		systemColor = SystemColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
	}

	/** Constructs a grayscale color. Arguments range from 0.0 to 1.0.  */
	public init(white: Double, alpha: Double = 1.0) {
		systemColor = SystemColor(white: CGFloat(white), alpha: CGFloat(alpha))
	}

	/** Constructs a color from HSB and alpha values. Arguments range from 0.0 to 1.0. */
	public init(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1.0) {
		systemColor = SystemColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: CGFloat(alpha))
	}

	/** Construct a color from a hex value and with alpha from 0.0 - 1.0.
		i.e. Color(hex: 0x336699, alpha: 0.2)
	 */
	public init(hex: UInt32, alpha: Double) {
	    let r = CGFloat((hex >> 16) & 0xff) / 255.0
	    let g = CGFloat((hex >> 8) & 0xff) / 255.0
	    let b = CGFloat(hex & 0xff) / 255.0
		
	    systemColor = SystemColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(alpha))
	}

	/** Construct an opaque color from a hex value
		i.e. Color(hex: 0x336699)
	 */
	public init(hex: UInt32) {
		self.init(hex: hex, alpha: 1.0)
	}

	/** Constructs a Color from a UIColor. */
	init(_ systemColor: SystemColor) {
		self.systemColor = systemColor
	}
	
	/// Returns a `Color` with the same colour components of the receiver, but with the given `alphaValue` instead.
	public func with(alphaValue: Double) -> Color {
		return Color(systemColor.withAlphaComponent(CGFloat(alphaValue)))
	}
	
	/// Returns the colour broken down into its Hue, Saturation, Brightness, Alpha components
	public var hsbaComponents: (h: Double, s: Double, b: Double, a: Double) {
		guard let calibrated = systemColor.usingColorSpaceName(NSColorSpaceName.calibratedRGB, device: nil) else {
			return (h: 0, s: 0, b: 0, a: 0)
		}
		return (h: Double(calibrated.hueComponent),
				s: Double(calibrated.saturationComponent),
				b: Double(calibrated.brightnessComponent),
				a: Double(calibrated.alphaComponent)
		)
	}

	public static var black: Color { return Color(SystemColor.black) }
	public static var darkGray: Color { return Color(SystemColor.darkGray) }
	public static var lightGray: Color { return Color(SystemColor.lightGray) }
	public static var white: Color { return Color(SystemColor.white) }
	public static var gray: Color { return Color(SystemColor.gray) }
	public static var red: Color { return Color(SystemColor.red) }
	public static var green: Color { return Color(SystemColor.green) }
	public static var blue: Color { return Color(SystemColor.blue) }
	public static var cyan: Color { return Color(SystemColor.cyan) }
	public static var yellow: Color { return Color(SystemColor.yellow) }
	public static var magenta: Color { return Color(SystemColor.magenta) }
	public static var orange: Color { return Color(SystemColor.orange) }
	public static var purple: Color { return Color(SystemColor.purple) }
	public static var brown: Color { return Color(SystemColor.brown) }
	public static var clear: Color { return Color(SystemColor.clear) }
}

extension Color: Equatable {
	public static func ==(lhs: Color, rhs: Color) -> Bool {
		guard
			let lhsCalibrated = lhs.systemColor.usingColorSpace(.genericRGB),
			let rhsCalibrated = rhs.systemColor.usingColorSpace(.genericRGB) else {
			return false
		}
		
		return lhsCalibrated == rhsCalibrated
	}
}

extension Color {
#if os(macOS)
	/// Gets the colour under the cursor, on the main display only.
	public static func underCursor() -> Color {
		
		let eventLocation = CGEvent(source: nil)!.location
		guard let image = CGDisplayCreateImage(CGMainDisplayID(), rect: CGRect(x: eventLocation.x, y: eventLocation.y, width: 1, height: 1)) else {
			return .white
		}
		
		// Convert the NSBitmapImageRep to the genericRGB colour space, because our sampling method comes in a device dependent space.
		guard let bitmap = NSBitmapImageRep(cgImage: image).converting(to: .genericRGB, renderingIntent: .default) else {
			return .white
		}
		let foundColor = bitmap.colorAt(x: 0, y: 0)
		
		return Color(foundColor ?? NSColor.white)
	}
#endif
}

extension SystemColor {
	public convenience init(nillableCGColor color: CGColor?) {
		if let color = color {
			#if os(iOS)
			self.init(cgColor: color)
			#else
			self.init(cgColor: color)!
			#endif
		} else {
			self.init(white: 0.0, alpha: 1.0)
		}
	}
}
