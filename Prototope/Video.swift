//
//  Video.swift
//  Prototope
//
//  Created by Jason Brennan on 2015-02-09.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import AVFoundation

/** Represents a video object. Can be any kind iOS natively supports. */
public struct Video: CustomStringConvertible {
	
	let name: String
	let player: AVPlayer
	
	/** Initialize the video with a filename. The name must include the file extension. */
	public init?(name: String) {
		self.name = name
		
		if let URL = Bundle.main.url(forResource: name, withExtension: nil) {
			self.player = AVPlayer(url: URL)
		} else {
            Environment.currentEnvironment?.exceptionHandler("Video named \(name) not found")
            return nil
		}
	}
	
	/// Initializes the video with a URL.
	public init(url: URL) {
		self.player = AVPlayer(url: url)
		self.name = url.lastPathComponent
	}
	
	public var description: String {
		return name
	}
	
	public var size: Size {
		if let size = player.currentItem?.presentationSize {
			return Size(size)
		}
		return Size()
	}
}
