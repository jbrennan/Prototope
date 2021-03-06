//
//  ParticlePreset.swift
//  Prototope
//
//  Created by Jason Brennan on Feb-06-2015.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import Foundation


/** These are presets you can use when setting up a particle. 
	
	Use these as starting points for configuring your particles, 
	or use .IKnowWhatImDoing and configure everything yourself. */
public enum ParticlePreset {
	
	/** Particles explode in all directions. */
	case explode
	
	/** Particles fall like rain all the way down. */
	case rain
	
	/** Particles fly upward and and quickly burn out. */
	case sparkle
	
	/** Sets nothing on the particle. We trust you to do the right thing. */
	case iKnowWhatImDoing
	
	internal func configureParticle(_ particle: Particle) {
		var particle = particle
		switch self {
		case .explode:
			particle.lifetime = 3
			particle.lifetimeRange = 3
			
			particle.birthRate = 80
			
			particle.velocity = 100
			
			particle.emissionRange = Double.pi * 2.0
			
			particle.color = Color(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
			
			particle.redRange = 1.0
			particle.blueRange = 1.0
			particle.greenRange = 1.0
			particle.alphaRange = 1.0
			
		case .rain:
			particle.lifetime = 4
			particle.lifetimeRange = 5
			particle.birthRate = 25
			particle.velocity = 70
			particle.velocityRange = 160
			particle.yAcceleration = 1000
			particle.emissionRange = Radian.circle
			
			particle.color = Color(red: 0, green: 0, blue: 1, alpha: 0.3)
			particle.redRange = 0
			particle.greenRange = 0
			particle.blueRange = 1.0
			particle.alphaRange = 0.55
			
			particle.scale = 0.4
			
		case .sparkle:
			particle.lifetime = 0.71
			particle.lifetimeRange = 0.5
			particle.birthRate = 20
			
			particle.velocity = 6.5
			particle.yAcceleration = -300
			
			particle.spin = Radian(degrees: -200)
			particle.spinRange = Radian(degrees: 490)
			
			particle.color = Color(red: 1, green: 0.95, blue: 0.27, alpha: 0)
			particle.alphaSpeed = 3
			
			particle.scale = 0.70
			particle.scaleRange = 0.30
			
		case .iKnowWhatImDoing:
			break
		}
	}
}
