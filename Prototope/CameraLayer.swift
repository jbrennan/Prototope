//
//  CameraLayer.swift
//  Prototope
//
//  Created by Andy Matuschak on 3/5/15.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import Foundation
import AVFoundation

/** A layer that shows the output of one of the device's cameras. Defaults to using the back camera. */
open class CameraLayer: Layer {
	public enum CameraPosition: CustomStringConvertible {
		/** The device's front-facing camera. */
		case front

		/** The device's back-facing camera. */
		case back

		fileprivate var avCaptureDevicePosition: AVCaptureDevice.Position {
			switch self {
			case .front: return .front
			case .back: return .back
			}
		}

		public var description: String {
			switch self {
			case .front: return "Front"
			case .back: return "Back"
			}
		}
	}

	/** Selects which camera to use. */
	open var cameraPosition: CameraPosition {
		didSet { updateSession() }
	}

	fileprivate var captureSession: AVCaptureSession?

	public init(parent: Layer? = Layer.root, name: String? = nil) {
		self.cameraPosition = .back
		super.init(parent: parent, name: name, viewClass: CameraView.self)
		updateSession()
	}

	deinit {
		captureSession?.stopRunning()
	}

	fileprivate func updateSession() {
		// Find device matching camera setting
		let devices = AVCaptureDevice.devices(for: AVMediaType.video) 
		if let device = devices.filter({ device in return device.position == self.cameraPosition.avCaptureDevicePosition }).first {
			var error: NSError?
			do {
				let input = try AVCaptureDeviceInput(device: device)
				captureSession?.stopRunning()

				captureSession = AVCaptureSession()
				captureSession!.addInput(input)
				captureSession!.startRunning()
				cameraLayer.session = captureSession!
				cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
			} catch let error1 as NSError {
				error = error1
				Environment.currentEnvironment!.exceptionHandler("Couldn't create camera device: \(String(describing: error))")
			}

		} else {
			Environment.currentEnvironment!.exceptionHandler("Could not find a \(cameraPosition.description.lowercased()) camera on this device")
		}

	}

	fileprivate var cameraLayer: AVCaptureVideoPreviewLayer {
		return (self.view as! CameraView).layer as! AVCaptureVideoPreviewLayer
	}

	/** Underlying camera view class. */
	fileprivate class CameraView: SystemView {
		#if os(iOS)
		override class var layerClass : AnyClass {
			return AVCaptureVideoPreviewLayer.self
		}
		#else
		override func makeBackingLayer() -> CALayer {
			return AVCaptureVideoPreviewLayer()
		}
		#endif
	}
}
