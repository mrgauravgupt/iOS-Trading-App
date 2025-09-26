//
//  DataProviderProtocol.swift
//  iOS-Trading-App
//
//  Created by Code Generator.
//

import Foundation

/// Protocol defining the interface for data providers
protocol DataProviderProtocol {
    /// Fetch data from the provider
    /// - Parameters:
    ///   - symbol: The symbol to fetch data for
    ///   - completion: Completion handler with result
    func fetchData(for symbol: String, completion: @escaping (Result<Data, Error>) -> Void)
    
    /// Check if the provider is currently connected
    var isConnected: Bool { get }
    
    /// Connect to the data provider
    /// - Parameter completion: Completion handler with success status
    func connect(completion: @escaping (Bool) -> Void)
    
    /// Disconnect from the data provider
    func disconnect()
}