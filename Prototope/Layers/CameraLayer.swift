//
//  CameraLayer.swift
//  Prototope
//
//  Created by Andy Matuschak on 3/5/15.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import Foundation
import AVFoundation

/** A layer that shows the output of one of the device's cameras. Defaults to using the front camera. */
open class CameraLayer: Layer {
	public enum CameraPosition: CustomStringConvertible {
		/** The device's front-facing camera. */
		case front
		
		#if os(iOS)
		/** The device's back-facing camera. */
		case back

		fileprivate var avCaptureDevicePosition: AVCaptureDevice.Position {
			switch self {
			case .front: return .front
			case .back: return .back
			}
		}
		#else
		fileprivate var avCaptureDevicePosition: AVCaptureDevice.Position {
			switch self {
			// On Macs, it seems like the camera's position is "unspecified."
			case .front: return .unspecified
			}
		}
		#endif

		public var description: String {
			switch self {
			case .front: return "Front"
				#if os(iOS)
			case .back: return "Back"
				#endif
			}
		}
	}

	/** Selects which camera to use. */
	open var cameraPosition: CameraPosition {
		didSet { checkAuthorizationThenUpdateSession() }
	}

	/// Indicates whether the video is mirrored, horizontally. Defaults to `true`,
	/// which is suitable for something like a video chat app.
	open var isVideoMirrored: Bool = true {
		didSet { checkAuthorizationThenUpdateSession() }
	}

	fileprivate var captureSession: AVCaptureSession?

	public init(parent: Layer? = Layer.root, name: String? = nil, cameraPosition: CameraPosition = .front) {
		self.cameraPosition = cameraPosition
		super.init(parent: parent, name: name, viewClass: CameraView.self)
		DispatchQueue.main.async {
			self.checkAuthorizationThenUpdateSession()
		}
	}

	deinit {
		captureSession?.stopRunning()
	}
	
	private func checkAuthorizationThenUpdateSession() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized: // The user has previously granted access to the camera.
				DispatchQueue.main.async {
					self.updateSession()
				}
			
			case .notDetermined: // The user has not yet been asked for camera access.
				print("Not yet authorized for camera, requesting now")
				AVCaptureDevice.requestAccess(for: .video) { granted in
					print("Camera request came back as: \(granted)")
					if granted {
						DispatchQueue.main.async {
							self.updateSession()
						}
					}
				}
			
			case .denied, .restricted: // The user can't grant access due to restrictions.
				print("The user has probably denied camera access. To use the camera layer, please enable this app in System Preferences > Privacy > Camera.")
				return
		@unknown default:
			fatalError()
		}
	}
	
	private let stillImageOutput = AVCaptureStillImageOutput()

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
				
				captureSession?.addOutput(stillImageOutput)
				
				captureSession!.startRunning()
				
				cameraLayer.session = captureSession!
				cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

				cameraLayer.connection?.automaticallyAdjustsVideoMirroring = false
				cameraLayer.connection?.isVideoMirrored = isVideoMirrored
			} catch let error1 as NSError {
				error = error1
				Environment.currentEnvironment!.exceptionHandler("Couldn't create camera device: \(String(describing: error))")
			}

		} else {
			Environment.currentEnvironment!.exceptionHandler("Could not find a \(cameraPosition.description.lowercased()) camera on this device")
		}
	}
	
	/// Asynchronously takes a photo, returning it via the completion handler.
	///
	/// The handler is called asynchronously on the main queue.
	open func takePhoto(completionHandler: @escaping (Result<Image, Error>) -> Void) {
		enum PhotoTakingError: Error {
			case noCameraConnection
			case unableToCreateJPEGData
			case unableToCreateSystemImageFromJPEGData
			case noErrorButAlsoNoSampleBufferIDK
		}
		
		func async(_ work: @autoclosure @escaping () -> Void) {
			DispatchQueue.main.async {
				work()
			}
		}
		
		guard let captureConnection = stillImageOutput.connection(with: .video) else {
			return async(completionHandler(.failure(PhotoTakingError.noCameraConnection)))
		}
		
		stillImageOutput.captureStillImageAsynchronously(from: captureConnection, completionHandler: { sampleBuffer, error in
			
			if let error = error {
				return async(completionHandler(.failure(error)))
			}
			
			if let sampleBuffer = sampleBuffer {
				guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) else {
					return async(completionHandler(.failure(PhotoTakingError.unableToCreateJPEGData)))
				}
				
				guard let systemImage = SystemImage(data: data) else {
					return async(completionHandler(.failure(PhotoTakingError.unableToCreateSystemImageFromJPEGData)))
				}
				let image = Image(systemImage)
				return async(completionHandler(.success(image)))
			} else {
				return async(completionHandler(.failure(PhotoTakingError.noErrorButAlsoNoSampleBufferIDK)))
			}
		})
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
