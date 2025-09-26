//
//  ViewModelProtocol.swift
//  iOS-Trading-App
//
//  Created by Code Generator.
//

import Foundation
import SwiftUI

/// Protocol defining the interface for view models
protocol ViewModelProtocol: ObservableObject {
    /// The associated view type for this view model
    associatedtype Content: View
    
    /// Load data required by the view model
    func loadData() async
    
    /// Reset the view model to initial state
    func reset()
    
    /// Indicates if the view model is currently loading data
    var isLoading: Bool { get }
}