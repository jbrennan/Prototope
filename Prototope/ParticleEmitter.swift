//
//  ParticleEmitter.swift
//  Prototope
//
//  Created by Jason Brennan on Feb-05-2015.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import QuartzCore

/** A particle emitter shows one or more kinds of Particles, and can show them in different formations. */
open class ParticleEmitter {
	let particles: [Particle]
	
	let emitterLayer = CAEmitterLayer()
	
	/** Creates a particle emitter with an array of particles. */
	public init(particles: [Particle]) {
		self.particles = particles
		self.emitterLayer.emitterCells = self.particles.map {
			(particle: Particle) -> CAEmitterCell in
			return particle.emitterCell
		}
	}
	
	
	/** Creates a particle emitter with one kind of particle. */
	public convenience init(particle: Particle) {
		self.init(particles: [particle])
	}
	
	
	/** How often new baby particles are born. */
	open var birthRate: Double {
		get { return Double(self.emitterLayer.birthRate) }
		set { self.emitterLayer.birthRate = Float(newValue) }
	}
	
	/** The render mode of the emitter. */
	open var renderMode: String {
		get { return convertFromCAEmitterLayerRenderMode(self.emitterLayer.renderMode) }
		set { self.emitterLayer.renderMode = convertToCAEmitterLayerRenderMode(newValue) }
	}
	
	
	/** The shape of the emitter. c.f., CAEmitterLayer for valid strings. */
	open var shape: String {
		get { return convertFromCAEmitterLayerEmitterShape(self.emitterLayer.emitterShape) }
		set { self.emitterLayer.emitterShape = convertToCAEmitterLayerEmitterShape(newValue) }
	}

	/** The mode of the emission shape. c.f. CAEmitterLayer for valid strings.
		TODO make a real enum for this, lazy bum. */
	open var shapeMode: String {
		get { return convertFromCAEmitterLayerEmitterMode(self.emitterLayer.emitterMode) }
		set { self.emitterLayer.emitterMode = convertToCAEmitterLayerEmitterMode(newValue) }
	}
	
	
	/** The render mode of the emitter. */
	open var size: Size {
		get { return Size(self.emitterLayer.emitterSize) }
		set { self.emitterLayer.emitterSize = CGSize(newValue) }
	}
	
	
	/** The render mode of the emitter. */
	open var position: Point {
		get { return Point(self.emitterLayer.emitterPosition) }
		set { self.emitterLayer.emitterPosition = CGPoint(newValue) }
	}
	
	
	/** The x position of the emitter. This is a shortcut for `position`. */
	open var x: Double {
		get { return self.position.x }
		set { self.position = Point(x: newValue, y: self.y) }
	}
	
	
	/** The y position of the emitter. This is a shortcut for `position`. */
	open var y: Double {
		get { return self.position.y }
		set { self.position = Point(x: self.x, y: newValue) }
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCAEmitterLayerRenderMode(_ input: CAEmitterLayerRenderMode) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAEmitterLayerRenderMode(_ input: String) -> CAEmitterLayerRenderMode {
	return CAEmitterLayerRenderMode(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCAEmitterLayerEmitterShape(_ input: CAEmitterLayerEmitterShape) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAEmitterLayerEmitterShape(_ input: String) -> CAEmitterLayerEmitterShape {
	return CAEmitterLayerEmitterShape(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCAEmitterLayerEmitterMode(_ input: CAEmitterLayerEmitterMode) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAEmitterLayerEmitterMode(_ input: String) -> CAEmitterLayerEmitterMode {
	return CAEmitterLayerEmitterMode(rawValue: input)
}
