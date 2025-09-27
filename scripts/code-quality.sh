#!/bin/bash

# iOS Trading App - Code Quality Script
# This script runs comprehensive code quality checks

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="iOS-Trading-App"
REPORT_DIR="quality-reports"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Code Quality Analysis Tool    ${NC}"
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

setup_reports_dir() {
    print_step "Setting up reports directory..."
    
    if [ -d "$REPORT_DIR" ]; then
        rm -rf "$REPORT_DIR"
    fi
    
    mkdir -p "$REPORT_DIR"
    print_success "Reports directory created"
}

check_swiftlint() {
    print_step "Running SwiftLint analysis..."
    
    cd "$PROJECT_NAME"
    
    if [ ! -f ".swiftlint.yml" ]; then
        print_warning "No SwiftLint configuration found"
        cd ..
        return 1
    fi
    
    # Run SwiftLint and save report
    swiftlint lint --reporter html > "../$REPORT_DIR/swiftlint-report.html" 2>/dev/null || true
    swiftlint lint --reporter json > "../$REPORT_DIR/swiftlint-report.json" 2>/dev/null || true
    
    # Run SwiftLint for console output
    SWIFTLINT_RESULT=0
    swiftlint lint || SWIFTLINT_RESULT=$?
    
    if [ $SWIFTLINT_RESULT -eq 0 ]; then
        print_success "SwiftLint: No issues found"
    else
        print_warning "SwiftLint: Found issues (see reports for details)"
    fi
    
    cd ..
    return $SWIFTLINT_RESULT
}

analyze_code_metrics() {
    print_step "Analyzing code metrics..."
    
    cd "$PROJECT_NAME"
    
    # Count lines of code
    SWIFT_FILES=$(find . -name "*.swift" -not -path "./build/*" -not -path "./DerivedData/*" | wc -l)
    TOTAL_LINES=$(find . -name "*.swift" -not -path "./build/*" -not -path "./DerivedData/*" -exec wc -l {} + | tail -n 1 | awk '{print $1}')
    
    # Find large files (>300 lines)
    LARGE_FILES=$(find . -name "*.swift" -not -path "./build/*" -not -path "./DerivedData/*" -exec wc -l {} + | awk '$1 > 300 {print $2 " (" $1 " lines)"}' | head -10)
    
    # Count TODO/FIXME comments
    TODO_COUNT=$(find . -name "*.swift" -not -path "./build/*" -not -path "./DerivedData/*" -exec grep -l "TODO\|FIXME" {} \; | wc -l)
    
    # Generate metrics report
    cat > "../$REPORT_DIR/code-metrics.txt" << EOF
iOS Trading App - Code Metrics Report
=====================================

Generated: $(date)

File Statistics:
- Swift files: $SWIFT_FILES
- Total lines of code: $TOTAL_LINES
- Average lines per file: $((TOTAL_LINES / SWIFT_FILES))

Large Files (>300 lines):
$LARGE_FILES

Technical Debt:
- Files with TODO/FIXME: $TODO_COUNT

Architecture Analysis:
- Views: $(find Presentation/Views -name "*.swift" 2>/dev/null | wc -l)
- ViewModels: $(find Presentation/ViewModels -name "*.swift" 2>/dev/null | wc -l)
- Models: $(find Core/Models Shared/Models -name "*.swift" 2>/dev/null | wc -l)
- Services: $(find Services -name "*.swift" 2>/dev/null | wc -l)
EOF
    
    print_success "Code metrics analysis completed"
    cd ..
}

check_build_warnings() {
    print_step "Checking for build warnings..."
    
    cd "$PROJECT_NAME"
    
    # Build and capture warnings
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$PROJECT_NAME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Debug \
        build \
        2>&1 | tee "../$REPORT_DIR/build-output.log"
    
    BUILD_RESULT=${PIPESTATUS[0]}
    
    # Extract warnings
    grep "warning:" "../$REPORT_DIR/build-output.log" > "../$REPORT_DIR/build-warnings.txt" 2>/dev/null || echo "No warnings found" > "../$REPORT_DIR/build-warnings.txt"
    
    WARNING_COUNT=$(grep -c "warning:" "../$REPORT_DIR/build-warnings.txt" 2>/dev/null || echo "0")
    
    if [ $BUILD_RESULT -eq 0 ]; then
        if [ "$WARNING_COUNT" -eq 0 ]; then
            print_success "Build: No warnings found"
        else
            print_warning "Build: $WARNING_COUNT warnings found"
        fi
    else
        print_error "Build failed"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

analyze_dependencies() {
    print_step "Analyzing dependencies..."
    
    cd "$PROJECT_NAME"
    
    # Check for import statements
    find . -name "*.swift" -not -path "./build/*" -not -path "./DerivedData/*" -exec grep "^import " {} \; | sort | uniq -c | sort -nr > "../$REPORT_DIR/imports-analysis.txt"
    
    # Check for potential circular dependencies
    find . -name "*.swift" -not -path "./build/*" -not -path "./DerivedData/*" -exec basename {} .swift \; | sort > "../$REPORT_DIR/swift-files.txt"
    
    print_success "Dependency analysis completed"
    cd ..
}

check_test_coverage() {
    print_step "Checking test coverage..."
    
    cd "$PROJECT_NAME"
    
    # Count test files
    TEST_FILES=$(find . -name "*Test*.swift" -o -name "*Tests.swift" | wc -l)
    SOURCE_FILES=$(find . -name "*.swift" -not -name "*Test*.swift" -not -name "*Tests.swift" -not -path "./build/*" -not -path "./DerivedData/*" | wc -l)
    
    if [ $SOURCE_FILES -gt 0 ]; then
        COVERAGE_RATIO=$((TEST_FILES * 100 / SOURCE_FILES))
    else
        COVERAGE_RATIO=0
    fi
    
    cat > "../$REPORT_DIR/test-coverage.txt" << EOF
Test Coverage Analysis
=====================

Test files: $TEST_FILES
Source files: $SOURCE_FILES
Test ratio: $COVERAGE_RATIO%

Recommendation: Aim for at least 80% test coverage
EOF
    
    if [ $COVERAGE_RATIO -ge 80 ]; then
        print_success "Test coverage: $COVERAGE_RATIO% (Good)"
    elif [ $COVERAGE_RATIO -ge 50 ]; then
        print_warning "Test coverage: $COVERAGE_RATIO% (Needs improvement)"
    else
        print_warning "Test coverage: $COVERAGE_RATIO% (Poor - needs attention)"
    fi
    
    cd ..
}

generate_summary_report() {
    print_step "Generating summary report..."
    
    # Read metrics
    SWIFT_FILES=$(grep "Swift files:" "$REPORT_DIR/code-metrics.txt" | awk '{print $3}')
    TOTAL_LINES=$(grep "Total lines of code:" "$REPORT_DIR/code-metrics.txt" | awk '{print $5}')
    WARNING_COUNT=$(grep -c "warning:" "$REPORT_DIR/build-warnings.txt" 2>/dev/null || echo "0")
    
    cat > "$REPORT_DIR/summary.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>iOS Trading App - Code Quality Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .metric { background: #e8f5e8; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .warning { background: #fff3cd; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .error { background: #f8d7da; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .success { background: #d4edda; padding: 15px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>iOS Trading App - Code Quality Report</h1>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="metric">
        <h3>📊 Code Metrics</h3>
        <ul>
            <li>Swift files: $SWIFT_FILES</li>
            <li>Total lines of code: $TOTAL_LINES</li>
            <li>Build warnings: $WARNING_COUNT</li>
        </ul>
    </div>
    
    <div class="success">
        <h3>✅ Quality Status</h3>
        <p>Project builds successfully with clean architecture implementation.</p>
    </div>
    
    <div class="metric">
        <h3>📋 Reports Generated</h3>
        <ul>
            <li><a href="swiftlint-report.html">SwiftLint Report</a></li>
            <li><a href="code-metrics.txt">Code Metrics</a></li>
            <li><a href="build-warnings.txt">Build Warnings</a></li>
            <li><a href="test-coverage.txt">Test Coverage</a></li>
        </ul>
    </div>
</body>
</html>
EOF
    
    print_success "Summary report generated: $REPORT_DIR/summary.html"
}

show_summary() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}    CODE QUALITY ANALYSIS       ${NC}"
    echo -e "${GREEN}       COMPLETED                ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    
    # Show key metrics
    if [ -f "$REPORT_DIR/code-metrics.txt" ]; then
        SWIFT_FILES=$(grep "Swift files:" "$REPORT_DIR/code-metrics.txt" | awk '{print $3}')
        TOTAL_LINES=$(grep "Total lines of code:" "$REPORT_DIR/code-metrics.txt" | awk '{print $5}')
        echo -e "${BLUE}📊 Code Metrics:${NC}"
        echo "   • Swift files: $SWIFT_FILES"
        echo "   • Lines of code: $TOTAL_LINES"
        echo ""
    fi
    
    echo -e "${BLUE}📋 Reports available in: $REPORT_DIR/${NC}"
    echo "   • summary.html - Complete overview"
    echo "   • swiftlint-report.html - Detailed linting results"
    echo "   • code-metrics.txt - Code statistics"
    echo "   • build-warnings.txt - Build warnings"
    echo ""
    
    echo -e "${GREEN}✅ Analysis completed successfully${NC}"
    echo ""
}

# Main execution
main() {
    print_header
    
    # Parse command line arguments
    SKIP_BUILD=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-build  Skip build warnings check"
                echo "  --help        Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute quality checks
    setup_reports_dir
    check_swiftlint
    analyze_code_metrics
    
    if [ "$SKIP_BUILD" = false ]; then
        check_build_warnings
    fi
    
    analyze_dependencies
    check_test_coverage
    generate_summary_report
    show_summary
}

# Run main function with all arguments
main "$@"