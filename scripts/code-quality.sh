#!/bin/bash

# Code Quality Script for iOS Trading App
# This script runs various code quality checks

echo "Running code quality checks..."

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null
then
    echo "SwiftLint could not be found. Please install it with 'brew install swiftlint'"
    exit 1
fi

echo "Running SwiftLint..."
swiftlint lint --quiet

echo "Checking for build errors..."
cd /Users/hexa/Desktop/latest-nifty/iOS-Trading-App
xcodebuild -project iOS-Trading-App.xcodeproj -scheme iOS-Trading-App clean build 2>&1 | grep "error:" || echo "No build errors found"

echo "Code quality checks completed."