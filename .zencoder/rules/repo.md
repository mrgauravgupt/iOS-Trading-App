---
description: Repository Information Overview
alwaysApply: true
---

# Repository Information Overview

## Repository Summary
This repository contains two main projects: an iOS Trading App built with SwiftUI and a React web application. The iOS app is the primary focus, providing a trading platform with AI-driven capabilities for the Indian market, particularly for NIFTY options trading. The React app appears to be a supplementary web interface.

## Repository Structure
- **iOS-Trading-App/**: SwiftUI-based iOS trading application with AI capabilities
- **src/**: React web application source files
- **public/**: Static assets for the React web application
- **.zencoder/**: Configuration and documentation files
- **.vscode/**: VS Code editor configuration

## Projects

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

### React Web Application
**Configuration File**: No explicit configuration file found

#### Language & Runtime
**Language**: TypeScript
**Framework**: React
**Build System**: Likely Create React App (based on structure)

#### Dependencies
No package.json found, but based on imports and structure:
- React for UI components
- TypeScript for type safety
- Google Fonts (Inter family) for typography

#### Build & Installation
Standard React commands are likely used:
```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build
```

#### Key Features
- **Modern UI**: Clean interface with responsive design
- **Component-Based**: Structured with React components
- **Responsive Layout**: Adapts to different screen sizes
- **Typography**: Uses Inter font family from Google Fonts