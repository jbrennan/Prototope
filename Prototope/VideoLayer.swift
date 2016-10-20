//
//  VideoLayer.swift
//  Prototope
//
//  Created by Jason Brennan on 2015-02-09.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif
import AVFoundation

/** This layer can play a video object. */
open class VideoLayer: Layer {
	
	/** The layer's current video. */
	var video: Video? {
		didSet {
			if let video = video {
				self.playerLayer.player = video.player
			}
		}
	}
	
	
	fileprivate var playerLayer: AVPlayerLayer {
		return (self.view as! VideoView).layer as! AVPlayerLayer
	}
	
	/** Creates a video layer with the given video. */
	public init(parent: Layer? = nil, video: Video?) {
		self.video = video
		
		super.init(parent: parent, name: video?.name, viewClass: VideoView.self)
		if let video = video {
			self.playerLayer.player = video.player
		}
	}
	
	
	/** Play the video. */
	open func play() {
		self.video?.player.play()
	}
	
	
	/** Pause the video. */
	open func pause() {
		self.video?.player.pause()
	}
	
	
	/** Underlying video view class. */
	fileprivate class VideoView: SystemView {
		#if os(iOS)
		override class var layerClass : AnyClass {
			return AVPlayerLayer.self
		}
		#else
		override func makeBackingLayer() -> CALayer {
			return AVPlayerLayer()
		}
		#endif
	}
}


