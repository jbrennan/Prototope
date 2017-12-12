//
//  Sound.swift
//  Prototope
//
//  Created by Andy Matuschak on 11/19/14.
//  Copyright (c) 2014 Khan Academy. All rights reserved.
//

import AVFoundation
import Foundation

/** Provides a simple way to play sound files. Supports .aif, .aiff, .wav, and .caf files. */
public struct Sound: CustomStringConvertible {

	fileprivate let player: AVAudioPlayer
	fileprivate let name: String!

	/** Creates a sound from a filename. No need to include the file extension: Prototope will
		try all the valid extensions. */
	public init?(name: String) {
		if let data = Environment.currentEnvironment!.soundProvider(name) {
			player = try! AVAudioPlayer(data: data as Data)
			player.prepareToPlay()
			self.name = name
		} else {
            Environment.currentEnvironment?.exceptionHandler("Sound named \(name) not found")
            return nil
		}
	}
	
	public var description: String {
		return self.name
	}

	/// From 0.0 to 1.0
	public var volume: Double {
		get { return Double(player.volume) }
		set { player.volume = Float(newValue) }
	}

	public func play() {
		player.currentTime = 0
		if player.delegate == nil {
			let delegate = AVAudioPlayerDelegate()
			player.delegate = delegate
			playingAVAudioPlayerDelegates.insert(delegate)
		}
		playingAVAudioPlayers.insert(player)
		player.play()
	}

	public func stop() {
		player.stop()
		if let delegate = (player.delegate as? Sound.AVAudioPlayerDelegate) {
			playingAVAudioPlayerDelegates.remove(delegate)
			player.delegate = nil
		}
		playingAVAudioPlayers.remove(player)
	}
	
	#if os(macOS)
	/// Beep beep!
	public static func beep() {
		NSBeep()
	}
	#endif

	public static let supportedExtensions = ["caf", "aif", "aiff", "wav"]

	// Fancy scheme to keep playing AVAudioPlayers from deallocating while they're playing.
	@objc fileprivate class AVAudioPlayerDelegate: NSObject, AVFoundation.AVAudioPlayerDelegate {
		@objc func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
			player.delegate = nil
			playingAVAudioPlayers.remove(player)
			playingAVAudioPlayerDelegates.remove(self)
		}

		@objc func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
			player.delegate = nil
			playingAVAudioPlayers.remove(player)
			playingAVAudioPlayerDelegates.remove(self)
		}
	}
}

private var playingAVAudioPlayers = Set<AVAudioPlayer>()
private var playingAVAudioPlayerDelegates = Set<Sound.AVAudioPlayerDelegate>()
