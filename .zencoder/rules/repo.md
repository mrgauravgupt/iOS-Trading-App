---
description: Repository Information Overview
alwaysApply: true
---

# Repository Information Overview

## Repository Summary
This repository contains an iOS Trading App built with SwiftUI, providing a trading platform with AI-driven capabilities for the Indian market, particularly for NIFTY options trading.

## Repository Structure
- **iOS-Trading-App/**: SwiftUI-based iOS trading application with AI capabilities
- **scripts/**: Build and code quality scripts
- **.zencoder/**: Configuration and documentation files
- **.vscode/**: VS Code editor configuration

## Project

### iOS Trading App
**Configuration File**: project.yml

#### Language & Runtime
**Language**: Swift
**Version**: Swift 6.1.2
**Build System**: Xcode
**Deployment Target**: iOS 18.0
**Architecture**: arm64, x86_64

#### Dependencies
The app uses native iOS frameworks without external package dependencies:
- SwiftUI for UI components
- Foundation for core functionality
- Security for keychain operations
- WebKit for web view integration
- Combine for reactive programming

#### Build & Installation
```bash
# Open the project in Xcode
open iOS-Trading-App/iOS-Trading-App.xcodeproj

# Build using xcodebuild
xcodebuild -project iOS-Trading-App/iOS-Trading-App.xcodeproj -scheme iOS-Trading-App -configuration Debug
```

#### Testing
**Framework**: XCTest
**Test Location**: UnitTests.swift, IntegrationTests.swift, UATTests.swift
**Run Command**:
```bash
xcodebuild test -project iOS-Trading-App/iOS-Trading-App.xcodeproj -scheme iOS-Trading-App
```

#### Key Features
- **Zerodha API Integration**: Trading via Zerodha broker API with real-time data
- **Keychain Security**: Enhanced credential storage with UserDefaults fallback
- **AI Trading Agents**: Multiple AI-driven trading strategy components
- **Options Trading**: Specialized for NIFTY options with Greeks calculations
- **Technical Analysis**: Built-in indicators and pattern recognition
- **Backtesting**: Historical data analysis and strategy testing
- **Risk Management**: Advanced risk assessment and position sizing
- **Real-time Data**: WebSocket integration for live market updates

#### Data Models
The app includes comprehensive data models for options trading:
- NIFTYOptionContract: Detailed options contract specifications
- NIFTYOptionsChain: Complete options chain with calls and puts
- IntradayOptionsData: Intraday trading data with OHLC and volume
- OptionsStrategy: Strategy modeling with risk/reward calculations
- AIModelState: AI model state tracking for market analysis