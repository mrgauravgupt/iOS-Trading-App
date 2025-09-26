//
//  ServiceProtocol.swift
//  iOS-Trading-App
//
//  Created by Code Generator.
//

import Foundation

/// Protocol defining the interface for service components
protocol ServiceProtocol {
    /// Initialize the service
    func initialize() throws
    
    /// Start the service operations
    func start() throws
    
    /// Stop the service operations
    func stop() throws
    
    /// Indicates if the service is currently active
    var isActive: Bool { get }
}