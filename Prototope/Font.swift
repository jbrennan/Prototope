//
//  Font.swift
//  Prototope
//
//  Created by Jason Brennan on 2017-10-19.
//  Copyright © 2017 Jason Brennan. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
	public typealias SystemFont = UIFont
	public func systemFontSize() -> CGFloat { return UIFont.systemFontSize }
#else
	import AppKit
	public typealias SystemFont = NSFont
#endif

/// A typographic element used for displaying text.
public struct Font {
	let systemFont: SystemFont
	
	/// Initializes the font at the given size, family, and weight. Defaults to Regular System font of systemFontSize().
	public init(size: Double = Font.systemFontSize(), family: Family = .system, weight: Weight = .regular) {
		// TODO: handle fonts other than the system font family
		systemFont = SystemFont.systemFont(ofSize: CGFloat(size), weight: weight.nsFontWeight)
	}
	
	public static func systemFontSize() -> Double { return Double(SystemFont.systemFontSize) }
}

public extension Font {
	
	/// The family for a font.
	enum Family {
		/// The system font, as chosen by the OS (in recent OS versions, this is San Francisco).
		case system
		
		/// A font family under the given name.
		case named(String)
	}
	
	/// The weight for a font.
	enum Weight {
		case light
		case regular
		case medium
		case semibold
		case bold
		case heavy
		case black
		
		var nsFontWeight: NSFont.Weight {
			switch self {
			case .light: return NSFont.Weight.light
			case .regular: return NSFont.Weight.regular
			case .medium: return NSFont.Weight.medium
			case .semibold: return NSFont.Weight.semibold
			case .bold: return NSFont.Weight.bold
			case .heavy: return NSFont.Weight.heavy
			case .black: return NSFont.Weight.black
			}
		}
	}
}
