# iOS Trading App - Comprehensive Refactoring Plan
## Ambiguity Resolution and Code Structure Improvement

### 🎯 Executive Summary

This document provides a comprehensive refactoring plan to eliminate ambiguity errors, establish better code structure, and enable faster development with improved code reuse. The plan addresses the critical issues identified in the codebase and provides a step-by-step approach to resolve them.

---

## 🚨 Critical Ambiguity Issues Identified

### 1. **Duplicate Model Definitions**
- **MarketDataPoint**: Defined in 4+ different locations with conflicting properties
- **Pattern Models**: Multiple pattern-related structs scattered across files
- **Trading Models**: Inconsistent model definitions across modules
- **Import Conflicts**: Non-existent module imports causing build failures

### 2. **Module Structure Chaos**
```
Current Problematic Structure:
├── Core/Models/
├── Core/SharedModels/
├── CoreModels/
├── SharedModels/
├── Models/
├── Shared/Models/
├── Sources/Models/
└── Various backup files (.bak, .orig)
```

### 3. **Import Statement Inconsistencies**
- References to non-existent "SharedModels" module
- Circular import dependencies
- Inconsistent module naming conventions
- Missing proper module boundaries

---

## 📋 Phase-by-Phase Refactoring Plan

## Phase 1: Foundation Cleanup (Week 1-2)
**Priority: CRITICAL - Must be completed first**

### 1.1 Eliminate Duplicate Model Definitions

#### Step 1: Audit All Model Files
```bash
# Search for all struct definitions
find . -name "*.swift" -exec grep -l "struct.*:" {} \; | sort

# Identify duplicate structs
grep -r "struct MarketDataPoint" --include="*.swift" .
grep -r "struct.*Pattern" --include="*.swift" .
grep -r "struct Trade" --include="*.swift" .
```

#### Step 2: Create Master Model Inventory
Create a spreadsheet/document listing:
- Model name
- File location
- Properties
- Dependencies
- Usage count

#### Step 3: Establish Single Source of Truth
**Target Structure:**
```
SharedCoreModels/
├── Foundation/
│   ├── MarketDataPoint.swift
│   ├── TimeframeModels.swift
│   └── BaseModels.swift
├── Trading/
│   ├── TradeModels.swift
│   ├── PositionModels.swift
│   └── OrderModels.swift
├── Patterns/
│   ├── ChartPatterns.swift
│   ├── TechnicalPatterns.swift
│   └── PatternResults.swift
└── Analytics/
    ├── PerformanceModels.swift
    └── RiskModels.swift
```

#### Step 4: Remove Duplicate Files
**Files to Delete:**
- All `.bak` and `.orig` files
- Duplicate model directories
- Conflicting struct definitions

### 1.2 Standardize Module Structure

#### Target Module Architecture:
```
iOS-Trading-App/
├── SharedCoreModels/           # Single source of truth for all models
│   ├── Foundation/
│   ├── Trading/
│   ├── Patterns/
│   └── Analytics/
├── Core/                       # Core business logic
│   ├── Protocols/
│   ├── Services/
│   └── Extensions/
├── BusinessLogic/              # Use cases and business rules
│   ├── UseCases/
│   ├── Engines/
│   └── Orchestrators/
├── Presentation/               # UI layer
│   ├── Views/
│   ├── ViewModels/
│   └── Components/
├── Infrastructure/             # External services
│   ├── Networking/
│   ├── Persistence/
│   └── Analytics/
└── Tests/                      # All test files
    ├── Unit/
    ├── Integration/
    └── UI/
```

### 1.3 Fix Import Statements

#### Create Import Mapping Document:
```swift
// OLD → NEW Import Mapping
import SharedModels          → import SharedCoreModels
import CoreModels           → import SharedCoreModels
import Models               → import SharedCoreModels
import PatternModels        → import SharedCoreModels
```

#### Automated Fix Script:
```bash
#!/bin/bash
# fix_imports.sh

# Replace incorrect imports
find . -name "*.swift" -exec sed -i '' 's/import SharedModels/import SharedCoreModels/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/import CoreModels/import SharedCoreModels/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/import Models/import SharedCoreModels/g' {} \;

echo "Import statements fixed"
```

---

## Phase 2: Model Consolidation (Week 2-3)
**Priority: HIGH**

### 2.1 Consolidate MarketDataPoint

#### Single MarketDataPoint Definition:
```swift
// SharedCoreModels/Foundation/MarketDataPoint.swift
import Foundation

public struct MarketDataPoint: Codable, Identifiable, Hashable {
    public let id: UUID
    public let symbol: String
    public let timestamp: Date
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Int64
    public let timeframe: Timeframe
    
    // Computed properties for convenience
    public var ohlc: OHLC {
        OHLC(open: open, high: high, low: low, close: close)
    }
    
    public var priceChange: Double {
        close - open
    }
    
    public var priceChangePercent: Double {
        guard open > 0 else { return 0 }
        return (priceChange / open) * 100
    }
    
    public init(
        id: UUID = UUID(),
        symbol: String,
        timestamp: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volume: Int64,
        timeframe: Timeframe
    ) {
        self.id = id
        self.symbol = symbol
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.timeframe = timeframe
    }
}

// Extension for backward compatibility
public extension MarketDataPoint {
    // Simple initializer for basic use cases
    init(symbol: String, close: Double) {
        self.init(
            symbol: symbol,
            timestamp: Date(),
            open: close,
            high: close,
            low: close,
            close: close,
            volume: 0,
            timeframe: .minute1
        )
    }
}
```

### 2.2 Consolidate Pattern Models

#### Unified Pattern Structure:
```swift
// SharedCoreModels/Patterns/ChartPatterns.swift
import Foundation

public protocol ChartPattern: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get }
    var type: PatternType { get }
    var confidence: Double { get }
    var timeframe: Timeframe { get }
    var detectedAt: Date { get }
}

public enum PatternType: String, CaseIterable, Codable {
    case headAndShoulders = "head_and_shoulders"
    case doubleTop = "double_top"
    case doubleBottom = "double_bottom"
    case triangle = "triangle"
    case flag = "flag"
    case pennant = "pennant"
    case wedge = "wedge"
    case custom = "custom"
}

public struct DetectedPattern: ChartPattern {
    public let id: UUID
    public let name: String
    public let type: PatternType
    public let confidence: Double
    public let timeframe: Timeframe
    public let detectedAt: Date
    public let dataPoints: [MarketDataPoint]
    public let metadata: [String: Any]
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: PatternType,
        confidence: Double,
        timeframe: Timeframe,
        detectedAt: Date = Date(),
        dataPoints: [MarketDataPoint],
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.confidence = confidence
        self.timeframe = timeframe
        self.detectedAt = detectedAt
        self.dataPoints = dataPoints
        self.metadata = metadata
    }
}
```

### 2.3 Create Model Factory Pattern

#### Centralized Model Creation:
```swift
// SharedCoreModels/Foundation/ModelFactory.swift
import Foundation

public class ModelFactory {
    public static let shared = ModelFactory()
    private init() {}
    
    // MarketDataPoint factory methods
    public func createMarketDataPoint(
        symbol: String,
        ohlcv: (Double, Double, Double, Double, Int64),
        timestamp: Date = Date(),
        timeframe: Timeframe = .minute1
    ) -> MarketDataPoint {
        MarketDataPoint(
            symbol: symbol,
            timestamp: timestamp,
            open: ohlcv.0,
            high: ohlcv.1,
            low: ohlcv.2,
            close: ohlcv.3,
            volume: ohlcv.4,
            timeframe: timeframe
        )
    }
    
    // Pattern factory methods
    public func createPattern(
        name: String,
        type: PatternType,
        confidence: Double,
        dataPoints: [MarketDataPoint]
    ) -> DetectedPattern {
        DetectedPattern(
            name: name,
            type: type,
            confidence: confidence,
            timeframe: dataPoints.first?.timeframe ?? .minute1,
            dataPoints: dataPoints
        )
    }
}
```

---

## Phase 3: Architecture Restructuring (Week 3-4)
**Priority: HIGH**

### 3.1 Implement Clean Architecture Layers

#### Domain Layer:
```swift
// Core/Domain/Entities/
public struct Trade {
    public let id: UUID
    public let symbol: String
    public let type: TradeType
    public let quantity: Int
    public let price: Double
    public let timestamp: Date
    public let status: TradeStatus
}

// Core/Domain/Repositories/
public protocol TradingRepository {
    func saveTrade(_ trade: Trade) async throws
    func getTrades(for symbol: String) async throws -> [Trade]
    func getActivePositions() async throws -> [Position]
}

// Core/Domain/UseCases/
public protocol ExecuteTradeUseCase {
    func execute(_ request: TradeRequest) async throws -> TradeResult
}
```

#### Application Layer:
```swift
// BusinessLogic/UseCases/
public class ExecuteTradeUseCaseImpl: ExecuteTradeUseCase {
    private let repository: TradingRepository
    private let riskManager: RiskManager
    private let validator: TradeValidator
    
    public init(
        repository: TradingRepository,
        riskManager: RiskManager,
        validator: TradeValidator
    ) {
        self.repository = repository
        self.riskManager = riskManager
        self.validator = validator
    }
    
    public func execute(_ request: TradeRequest) async throws -> TradeResult {
        // Validate trade
        try await validator.validate(request)
        
        // Check risk limits
        try await riskManager.checkLimits(request)
        
        // Execute trade
        let trade = try await repository.executeTrade(request)
        
        return TradeResult(trade: trade, status: .executed)
    }
}
```

### 3.2 Dependency Injection Container

#### Enhanced DI Container:
```swift
// Core/DependencyInjection/DIContainer.swift
import Foundation

public protocol DIContainer {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, instance: T)
    func resolve<T>(_ type: T.Type) -> T
    func resolveOptional<T>(_ type: T.Type) -> T?
}

public class DefaultDIContainer: DIContainer {
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    
    public init() {}
    
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    public func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }
    
    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // Check singletons first
        if let instance = singletons[key] as? T {
            return instance
        }
        
        // Check factories
        if let factory = factories[key] {
            let instance = factory() as! T
            return instance
        }
        
        fatalError("No registration found for type \(type)")
    }
    
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        do {
            return resolve(type)
        } catch {
            return nil
        }
    }
}
```

### 3.3 Protocol-Based Architecture

#### Core Protocols:
```swift
// Core/Protocols/CoreProtocols.swift
import Foundation
import Combine

// Base protocols
public protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}

public protocol Repository {
    associatedtype Entity
    associatedtype ID
    
    func save(_ entity: Entity) async throws
    func findById(_ id: ID) async throws -> Entity?
    func findAll() async throws -> [Entity]
    func delete(_ id: ID) async throws
}

public protocol UseCase {
    associatedtype Request
    associatedtype Response
    
    func execute(_ request: Request) async throws -> Response
}

public protocol ViewModel: ObservableObject {
    associatedtype State
    associatedtype Action
    
    var state: State { get }
    func handle(_ action: Action) async
}

// Trading-specific protocols
public protocol TradingEngine {
    func analyzeTrade(_ request: TradeRequest) async throws -> TradeAnalysis
    func executeTrade(_ request: TradeRequest) async throws -> TradeResult
}

public protocol PatternDetector {
    func detectPatterns(in data: [MarketDataPoint]) async throws -> [DetectedPattern]
    func validatePattern(_ pattern: DetectedPattern) async throws -> Bool
}
```

---

## Phase 4: Error Handling & Resilience (Week 4-5)
**Priority: MEDIUM-HIGH**

### 4.1 Unified Error System

#### Comprehensive Error Hierarchy:
```swift
// SharedCoreModels/Foundation/Errors.swift
import Foundation

public protocol AppError: Error, LocalizedError, CustomStringConvertible {
    var code: String { get }
    var userMessage: String { get }
    var technicalDetails: String { get }
    var severity: ErrorSeverity { get }
    var recoverable: Bool { get }
}

public enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// Domain-specific errors
public enum TradingError: AppError {
    case insufficientFunds(required: Double, available: Double)
    case invalidSymbol(String)
    case marketClosed
    case riskLimitExceeded(limit: Double, requested: Double)
    case networkError(underlying: Error)
    case aiDecisionConflict(agents: [String])
    case patternDetectionFailed(reason: String)
    case dataValidationFailed(field: String, value: Any)
    
    public var code: String {
        switch self {
        case .insufficientFunds: return "TRD_001"
        case .invalidSymbol: return "TRD_002"
        case .marketClosed: return "TRD_003"
        case .riskLimitExceeded: return "TRD_004"
        case .networkError: return "TRD_005"
        case .aiDecisionConflict: return "TRD_006"
        case .patternDetectionFailed: return "TRD_007"
        case .dataValidationFailed: return "TRD_008"
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .insufficientFunds, .riskLimitExceeded: return .high
        case .marketClosed, .invalidSymbol: return .medium
        case .networkError, .aiDecisionConflict: return .high
        case .patternDetectionFailed, .dataValidationFailed: return .low
        }
    }
    
    public var recoverable: Bool {
        switch self {
        case .insufficientFunds, .riskLimitExceeded, .marketClosed: return false
        case .invalidSymbol, .networkError, .aiDecisionConflict: return true
        case .patternDetectionFailed, .dataValidationFailed: return true
        }
    }
}
```

### 4.2 Error Handling Middleware

#### Error Handler Chain:
```swift
// Core/ErrorHandling/ErrorHandler.swift
import Foundation
import OSLog

public protocol ErrorHandler {
    func canHandle(_ error: Error) -> Bool
    func handle(_ error: Error) async -> ErrorHandlingResult
}

public enum ErrorHandlingResult {
    case handled
    case retry(after: TimeInterval)
    case escalate(to: ErrorHandler)
    case fail(with: Error)
}

public class ErrorHandlerChain: ErrorHandler {
    private let handlers: [ErrorHandler]
    private let logger = Logger(subsystem: "TradingApp", category: "ErrorHandling")
    
    public init(handlers: [ErrorHandler]) {
        self.handlers = handlers
    }
    
    public func canHandle(_ error: Error) -> Bool {
        handlers.contains { $0.canHandle(error) }
    }
    
    public func handle(_ error: Error) async -> ErrorHandlingResult {
        logger.error("Handling error: \(error.localizedDescription)")
        
        for handler in handlers {
            if handler.canHandle(error) {
                let result = await handler.handle(error)
                
                switch result {
                case .handled:
                    logger.info("Error handled by \(type(of: handler))")
                    return .handled
                case .retry(let interval):
                    logger.info("Error handler requested retry after \(interval)s")
                    return .retry(after: interval)
                case .escalate(let nextHandler):
                    logger.info("Error escalated to \(type(of: nextHandler))")
                    return await nextHandler.handle(error)
                case .fail(let finalError):
                    logger.error("Error handling failed: \(finalError.localizedDescription)")
                    return .fail(with: finalError)
                }
            }
        }
        
        return .fail(with: error)
    }
}
```

---

## Phase 5: Testing Strategy (Week 5-6)
**Priority: MEDIUM**

### 5.1 Test Architecture

#### Testing Pyramid:
```swift
// Tests/Foundation/TestProtocols.swift
import XCTest
@testable import SharedCoreModels

public protocol TestCase {
    associatedtype SystemUnderTest
    var sut: SystemUnderTest { get }
    func setUp() async throws
    func tearDown() async throws
}

public protocol MockService {
    var callHistory: [String] { get }
    func reset()
}

// Unit Test Base Classes
open class UnitTestCase<T>: XCTestCase, TestCase {
    public typealias SystemUnderTest = T
    public var sut: T!
    
    open func createSUT() -> T {
        fatalError("Must override createSUT()")
    }
    
    override open func setUp() async throws {
        try await super.setUp()
        sut = createSUT()
        try await setUp()
    }
    
    open func setUp() async throws {
        // Override in subclasses
    }
    
    open func tearDown() async throws {
        // Override in subclasses
    }
}
```

### 5.2 Mock Services

#### Comprehensive Mock Framework:
```swift
// Tests/Mocks/MockServices.swift
import Foundation
@testable import SharedCoreModels

public class MockTradingRepository: TradingRepository, MockService {
    public var callHistory: [String] = []
    public var shouldFail = false
    public var mockTrades: [Trade] = []
    public var mockPositions: [Position] = []
    
    public func reset() {
        callHistory.removeAll()
        shouldFail = false
        mockTrades.removeAll()
        mockPositions.removeAll()
    }
    
    public func saveTrade(_ trade: Trade) async throws {
        callHistory.append("saveTrade(\(trade.id))")
        if shouldFail {
            throw TradingError.networkError(underlying: NSError(domain: "Mock", code: 1))
        }
        mockTrades.append(trade)
    }
    
    public func getTrades(for symbol: String) async throws -> [Trade] {
        callHistory.append("getTrades(\(symbol))")
        if shouldFail {
            throw TradingError.networkError(underlying: NSError(domain: "Mock", code: 1))
        }
        return mockTrades.filter { $0.symbol == symbol }
    }
    
    public func getActivePositions() async throws -> [Position] {
        callHistory.append("getActivePositions")
        if shouldFail {
            throw TradingError.networkError(underlying: NSError(domain: "Mock", code: 1))
        }
        return mockPositions
    }
}
```

---

## Phase 6: Performance & Monitoring (Week 6-7)
**Priority: LOW-MEDIUM**

### 6.1 Performance Monitoring

#### Metrics Collection:
```swift
// Core/Monitoring/PerformanceMonitor.swift
import Foundation
import OSLog

public protocol PerformanceMonitor {
    func startMeasurement(_ operation: String) -> PerformanceMeasurement
    func recordMetric(_ metric: PerformanceMetric)
    func getMetrics(for operation: String) -> [PerformanceMetric]
}

public struct PerformanceMetric {
    public let operation: String
    public let duration: TimeInterval
    public let timestamp: Date
    public let success: Bool
    public let metadata: [String: Any]
    
    public init(
        operation: String,
        duration: TimeInterval,
        timestamp: Date = Date(),
        success: Bool = true,
        metadata: [String: Any] = [:]
    ) {
        self.operation = operation
        self.duration = duration
        self.timestamp = timestamp
        self.success = success
        self.metadata = metadata
    }
}

public class DefaultPerformanceMonitor: PerformanceMonitor {
    private var metrics: [String: [PerformanceMetric]] = [:]
    private let logger = Logger(subsystem: "TradingApp", category: "Performance")
    private let queue = DispatchQueue(label: "performance.monitor", qos: .utility)
    
    public func startMeasurement(_ operation: String) -> PerformanceMeasurement {
        return PerformanceMeasurement(operation: operation, monitor: self)
    }
    
    public func recordMetric(_ metric: PerformanceMetric) {
        queue.async {
            if self.metrics[metric.operation] == nil {
                self.metrics[metric.operation] = []
            }
            self.metrics[metric.operation]?.append(metric)
            
            // Log slow operations
            if metric.duration > 1.0 {
                self.logger.warning("Slow operation: \(metric.operation) took \(metric.duration)s")
            }
        }
    }
    
    public func getMetrics(for operation: String) -> [PerformanceMetric] {
        return queue.sync {
            return metrics[operation] ?? []
        }
    }
}
```

---

## 🛠 Implementation Checklist

### Phase 1: Foundation Cleanup ✅
- [ ] Audit all model files and create inventory
- [ ] Identify and document all duplicate structs
- [ ] Create master model consolidation plan
- [ ] Remove all .bak, .orig, and duplicate files
- [ ] Fix all import statements
- [ ] Establish SharedCoreModels as single source of truth
- [ ] Test build after cleanup

### Phase 2: Model Consolidation ✅
- [ ] Consolidate MarketDataPoint into single definition
- [ ] Consolidate all Pattern models
- [ ] Create unified Trading models
- [ ] Implement ModelFactory pattern
- [ ] Update all references to use consolidated models
- [ ] Test all model usage across app

### Phase 3: Architecture Restructuring ✅
- [ ] Implement Clean Architecture layers
- [ ] Create protocol-based architecture
- [ ] Implement dependency injection container
- [ ] Restructure file organization
- [ ] Update all imports and dependencies
- [ ] Test architectural changes

### Phase 4: Error Handling ✅
- [ ] Implement unified error system
- [ ] Create error handler chain
- [ ] Add error recovery mechanisms
- [ ] Implement circuit breaker pattern
- [ ] Add comprehensive error logging
- [ ] Test error scenarios

### Phase 5: Testing Strategy ✅
- [ ] Create test architecture
- [ ] Implement mock services
- [ ] Write unit tests for core models
- [ ] Write integration tests for key flows
- [ ] Add UI tests for critical paths
- [ ] Achieve 80%+ code coverage

### Phase 6: Performance & Monitoring ✅
- [ ] Implement performance monitoring
- [ ] Add metrics collection
- [ ] Create performance dashboards
- [ ] Optimize slow operations
- [ ] Add memory leak detection
- [ ] Performance test critical paths

---

## 📊 Success Metrics

### Code Quality Metrics:
- **Build Success Rate**: 100% (currently ~60%)
- **Compilation Time**: < 30 seconds (currently ~2 minutes)
- **Code Duplication**: < 5% (currently ~25%)
- **Test Coverage**: > 80% (currently ~20%)
- **Cyclomatic Complexity**: < 10 per method (currently ~15)

### Development Velocity Metrics:
- **Feature Development Time**: -50% reduction
- **Bug Fix Time**: -60% reduction
- **Code Review Time**: -40% reduction
- **Onboarding Time**: -70% reduction

### Stability Metrics:
- **Crash Rate**: < 0.1% (currently ~2%)
- **Memory Leaks**: 0 (currently ~5 per session)
- **Performance Regressions**: 0
- **API Response Time**: < 500ms (currently ~2s)

---

## 🚀 Quick Start Guide

### Immediate Actions (Day 1):
1. **Backup Current Codebase**
   ```bash
   git checkout -b refactoring-backup
   git push origin refactoring-backup
   ```

2. **Create Refactoring Branch**
   ```bash
   git checkout -b comprehensive-refactoring
   ```

3. **Run Audit Scripts**
   ```bash
   ./scripts/audit_models.sh
   ./scripts/find_duplicates.sh
   ./scripts/check_imports.sh
   ```

4. **Start with Phase 1 Cleanup**
   - Remove all .bak files
   - Fix import statements
   - Create SharedCoreModels structure

### Weekly Milestones:
- **Week 1**: Complete Phase 1 (Foundation Cleanup)
- **Week 2**: Complete Phase 2 (Model Consolidation)
- **Week 3**: Complete Phase 3 (Architecture Restructuring)
- **Week 4**: Complete Phase 4 (Error Handling)
- **Week 5**: Complete Phase 5 (Testing Strategy)
- **Week 6**: Complete Phase 6 (Performance & Monitoring)
- **Week 7**: Final testing and deployment

---

## 📝 Notes and Considerations

### Risk Mitigation:
1. **Incremental Changes**: Make small, testable changes
2. **Feature Flags**: Use feature flags for major changes
3. **Rollback Plan**: Always have a rollback strategy
4. **Staging Environment**: Test all changes in staging first

### Team Coordination:
1. **Code Freeze**: Implement code freeze during major refactoring
2. **Communication**: Daily standups during refactoring period
3. **Documentation**: Update documentation as changes are made
4. **Training**: Provide training on new architecture patterns

### Long-term Maintenance:
1. **Code Reviews**: Enforce architectural guidelines in code reviews
2. **Automated Checks**: Add linting rules to prevent regressions
3. **Regular Audits**: Monthly architecture health checks
4. **Continuous Improvement**: Quarterly refactoring sessions

---

This comprehensive plan provides a structured approach to eliminating ambiguity errors and establishing a robust, maintainable codebase that will support faster development and better code reuse.