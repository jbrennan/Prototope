//
//  PDFLayer.swift
//  Prototope
//
//  Created by Jason Brennan on 2018-06-30.
//  Copyright © 2018 Jason Brennan. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import AppKit
import Quartz
#endif

/// Layer class for rendering a PDF.
open class PDFLayer: Layer {
	
	typealias SystemPDFView = PDFView
	
	public init(parent: Layer? = nil, name: String? = nil, pdf: PDF) {
		super.init(parent: parent, name: name, viewClass: PrototopePDFView.self)
		pdfView.document = pdf.document
			//PDFDocument(url: Bundle.init(for: PDFLayer.self).url(forResource: "playground", withExtension: "pdf")!)
		pdfView.displaysPageBreaks = false
		pdfView.backgroundColor = .white
		
		if #available(OSX 10.13, *) {
			
			pdfView.minScaleFactor = 1.0
			pdfView.maxScaleFactor = 1.0// pdfView.scaleFactorForSizeToFit
		} else {
			// Fallback on earlier versions
		}
		sizeToFit()
	}
	
	private func sizeToFit() {
		guard let firstPage = pdfView.document?.page(at: 0) else { return }
		let size = firstPage.bounds(for: .mediaBox).size
		self.size = Size(size)
	}
	
	private var pdfView: PrototopePDFView {
		return view as! PrototopePDFView
	}
}

public extension PDFLayer {
	public struct PDF {
		let document: PDFDocument
		
		/// Initialize the PDF from the given URL. Assumes `url` points to a valid PDF, or else it crashes.
		public init(url: URL) {
			document = PDFDocument(url: url)!
		}
		
		/// Initializes the PDF by searching for a file with the given `name` in the caller's bundle. `name` should not include an extension.
		public init(named name: String, in bundle: Bundle = Bundle.main) {
			let url = bundle.url(forResource: name, withExtension: "pdf")!
			document = PDFDocument(url: url)!
		}
	}
}

private extension PDFLayer {
	
	class PrototopePDFView: SystemPDFView, InteractionHandling {

		// note: nothing sets this to false, but leaving here in case I ever need to make it work
		var mouseInteractionEnabled = true
		override func hitTest(_ point: NSPoint) -> NSView? {
			guard mouseInteractionEnabled else { return nil }

			return super.hitTest(point)
		}

		// We want the coordinates to be flipped so they're the same as on iOS.
		override var isFlipped: Bool {
			return true
		}

		var mouseDownHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseDown(with event: NSEvent) {
			// when changing this implementation, remember to update the impls in Scroll and ShapeLayer, etc
			//			let locationInView = convert(event.locationInWindow, from: nil)
			//			dragBehavior?.dragDidBegin(atLocationInLayer: Point(locationInView))
			mouseDownHandler?(InputEvent(event: event))
		}


		var mouseMovedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseMoved(with event: NSEvent) {
			mouseMovedHandler?(InputEvent(event: event))
			// TODO: when there's no handler, or when the handler indicates it should not handle the event, call super.
		}


		var mouseUpHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseUp(with event: NSEvent) {
			mouseUpHandler?(InputEvent(event: event))
		}

		var mouseDraggedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseDragged(with event: NSEvent) {
			// when changing this implementation, remember to update the impls in Scroll and ShapeLayer, etc
			//			let locationInSuperView = superview!.convert(event.locationInWindow, from: nil)
			//			dragBehavior?.dragDidChange(atLocationInParentLayer: Point(locationInSuperView))
			mouseDraggedHandler?(InputEvent(event: event))
		}
		var mouseEnteredHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseEntered(with event: NSEvent) {
			mouseEnteredHandler?(InputEvent(event: event))
		}
		var mouseExitedHandler: MouseHandler? { didSet { setupTrackingAreaIfNeeded() } }
		override func mouseExited(with event: NSEvent) {
			mouseExitedHandler?(InputEvent(event: event))
		}

		var keyEquivalentHandler: Layer.KeyEquivalentHandler?
		override func performKeyEquivalent(with event: NSEvent) -> Bool {
			if let handler = keyEquivalentHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return true
				case .unhandled: break
				}
			}

			return super.performKeyEquivalent(with: event)
		}

		var keyDownHandler: Layer.KeyEquivalentHandler?
		override func keyDown(with event: NSEvent) {
			if let handler = keyDownHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return
				case .unhandled: break
				}
			}

			return super.keyDown(with: event)
		}

		var flagsChangedHandler: Layer.KeyEquivalentHandler?
		override func flagsChanged(with event: NSEvent) {
			if let handler = flagsChangedHandler {
				switch handler(InputEvent(event: event)) {
				case .handled: return
				case .unhandled: break
				}
			}
			return super.flagsChanged(with: event)
		}

		override var acceptsFirstResponder: Bool {
			return true
		}
	}
}
