//
//  EngineProtocol.swift
//  iOS-Trading-App
//
//  Created by Code Generator.
//

import Foundation

/// Protocol defining the interface for engine components
protocol EngineProtocol {
    /// Initialize the engine
    func initialize() async throws
    
    /// Start the engine operations
    func start() async throws
    
    /// Stop the engine operations
    func stop() async throws
    
    /// Reset the engine to initial state
    func reset() async throws
    
    /// Indicates if the engine is currently running
    var isRunning: Bool { get }
}