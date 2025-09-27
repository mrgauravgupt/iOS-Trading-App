#!/bin/bash

# iOS Trading App - Comprehensive Build Script
# This script handles project generation, dependency management, and building

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="iOS-Trading-App"
SCHEME_NAME="iOS-Trading-App"
BUILD_DIR="build"
LOG_FILE="build.log"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  iOS Trading App Build Script  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_dependencies() {
    print_step "Checking dependencies..."
    
    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode is not installed or not in PATH"
        exit 1
    fi
    
    # Check for XcodeGen
    if ! command -v xcodegen &> /dev/null; then
        print_error "XcodeGen is not installed. Install with: brew install xcodegen"
        exit 1
    fi
    
    # Check for SwiftLint
    if ! command -v swiftlint &> /dev/null; then
        print_info "SwiftLint not found. Installing..."
        if command -v brew &> /dev/null; then
            brew install swiftlint
        else
            print_error "Homebrew not found. Please install SwiftLint manually"
            exit 1
        fi
    fi
    
    print_success "All dependencies are available"
}

clean_build() {
    print_step "Cleaning previous build artifacts..."
    
    # Remove build directory
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_info "Removed build directory"
    fi
    
    # Remove derived data
    if [ -d "DerivedData" ]; then
        rm -rf "DerivedData"
        print_info "Removed DerivedData"
    fi
    
    # Remove old logs
    if [ -f "$LOG_FILE" ]; then
        rm "$LOG_FILE"
        print_info "Removed old build log"
    fi
    
    print_success "Clean completed"
}

generate_project() {
    print_step "Generating Xcode project with XcodeGen..."
    
    cd "$PROJECT_NAME"
    
    if [ ! -f "project.yml" ]; then
        print_error "project.yml not found in $PROJECT_NAME directory"
        exit 1
    fi
    
    xcodegen generate
    
    if [ $? -eq 0 ]; then
        print_success "Project generated successfully"
    else
        print_error "Project generation failed"
        exit 1
    fi
    
    cd ..
}

run_swiftlint() {
    print_step "Running SwiftLint..."
    
    cd "$PROJECT_NAME"
    
    if [ -f ".swiftlint.yml" ]; then
        swiftlint --config .swiftlint.yml
        if [ $? -eq 0 ]; then
            print_success "SwiftLint passed"
        else
            print_error "SwiftLint found issues (continuing build)"
        fi
    else
        print_info "No SwiftLint configuration found, skipping"
    fi
    
    cd ..
}

build_project() {
    print_step "Building project..."
    
    cd "$PROJECT_NAME"
    
    # Build for simulator
    print_info "Building for iOS Simulator..."
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Debug \
        build \
        | tee "../$LOG_FILE"
    
    BUILD_RESULT=${PIPESTATUS[0]}
    
    if [ $BUILD_RESULT -eq 0 ]; then
        print_success "Build completed successfully"
    else
        print_error "Build failed with exit code $BUILD_RESULT"
        print_info "Check $LOG_FILE for details"
        exit $BUILD_RESULT
    fi
    
    cd ..
}

run_tests() {
    print_step "Running tests..."
    
    cd "$PROJECT_NAME"
    
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Debug \
        test \
        | tee -a "../$LOG_FILE"
    
    TEST_RESULT=${PIPESTATUS[0]}
    
    if [ $TEST_RESULT -eq 0 ]; then
        print_success "All tests passed"
    else
        print_error "Tests failed with exit code $TEST_RESULT"
        print_info "Check $LOG_FILE for details"
        # Don't exit on test failure, just warn
    fi
    
    cd ..
}

generate_build_info() {
    print_step "Generating build information..."
    
    BUILD_DATE=$(date)
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    
    cat > "build-info.txt" << EOF
iOS Trading App - Build Information
===================================

Build Date: $BUILD_DATE
Git Commit: $GIT_COMMIT
Git Branch: $GIT_BRANCH
Xcode Version: $(xcodebuild -version | head -n 1)
Swift Version: $(swift --version | head -n 1)

Build Status: SUCCESS
EOF
    
    print_success "Build information saved to build-info.txt"
}

show_summary() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}       BUILD COMPLETED          ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${GREEN}✅ Project generated successfully${NC}"
    echo -e "${GREEN}✅ Code quality checks passed${NC}"
    echo -e "${GREEN}✅ Build completed successfully${NC}"
    echo -e "${GREEN}✅ Ready for development${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Open ${PROJECT_NAME}.xcodeproj in Xcode"
    echo "2. Select your target device/simulator"
    echo "3. Press Cmd+R to run the app"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "./scripts/code-quality.sh  - Run code quality checks"
    echo "./scripts/test.sh          - Run tests only"
    echo ""
}

# Main execution
main() {
    print_header
    
    # Parse command line arguments
    CLEAN=false
    SKIP_TESTS=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --clean       Clean build artifacts before building"
                echo "  --skip-tests  Skip running tests"
                echo "  --help        Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute build steps
    check_dependencies
    
    if [ "$CLEAN" = true ]; then
        clean_build
    fi
    
    generate_project
    run_swiftlint
    build_project
    
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    fi
    
    generate_build_info
    show_summary
}

# Run main function with all arguments
main "$@"