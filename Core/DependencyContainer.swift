//
//  DependencyContainer.swift
//  iOS-Trading-App
//
//  Created by Code Generator.
//

import Foundation

/// A simple dependency injection container
class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Services
    private var services: [String: Any] = [:]
    
    /// Register a service with the container
    /// - Parameters:
    ///   - service: The service instance to register
    ///   - type: The type of the service
    func register<T>(_ service: T, type: T.Type) {
        let key = String(describing: type)
        services[key] = service
    }
    
    /// Resolve a service from the container
    /// - Parameter type: The type of service to resolve
    /// - Returns: The resolved service or nil if not found
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
    
    /// Remove all registered services
    func reset() {
        services.removeAll()
    }
}