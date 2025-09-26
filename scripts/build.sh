#!/bin/bash

# Build script for iOS Trading App
# This script regenerates the Xcode project and builds the app

echo "Regenerating Xcode project..."
xcodegen generate

if [ $? -eq 0 ]; then
    echo "Project regenerated successfully."
    echo "Building the iOS Trading App..."
    xcodebuild -project iOS-Trading-App.xcodeproj -scheme iOS-Trading-App clean build
else
    echo "Failed to regenerate project. Please check project.yml for errors."
    exit 1
fi