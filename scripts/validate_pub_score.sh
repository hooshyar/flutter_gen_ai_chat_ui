#!/bin/bash

# Flutter Package Excellence - Pub.dev Score Validation Script
# This script validates all aspects required for a perfect 160/160 pub.dev score

set -e  # Exit on any error

echo "🚀 Flutter Package Excellence Validation"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
ERRORS=0
WARNINGS=0

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -1)"
echo ""

# ============================================
# PHASE 1: Dependencies Check
# ============================================
echo "📦 Phase 1: Dependencies"
echo "------------------------"

echo "Installing dependencies..."
flutter pub get > /dev/null 2>&1
print_success "Dependencies installed"

echo "Checking for outdated dependencies..."
OUTDATED=$(flutter pub outdated --json 2>&1 || echo "")
if echo "$OUTDATED" | grep -q "resolvable"; then
    print_warning "Some dependencies may have updates available"
    echo "   Run: flutter pub outdated"
else
    print_success "All dependencies are current"
fi

echo ""

# ============================================
# PHASE 2: Static Analysis
# ============================================
echo "🔍 Phase 2: Static Analysis"
echo "---------------------------"

echo "Running dart analyze..."
if dart analyze --fatal-infos; then
    print_success "No analysis issues found"
else
    print_error "Static analysis found issues"
    echo "   Fix with: dart fix --apply"
fi

echo ""

# ============================================
# PHASE 3: Code Formatting
# ============================================
echo "✨ Phase 3: Code Formatting"
echo "---------------------------"

echo "Checking code formatting..."
if dart format --output=none --set-exit-if-changed .; then
    print_success "All code is properly formatted"
else
    print_error "Code formatting issues found"
    echo "   Fix with: dart format ."
fi

echo ""

# ============================================
# PHASE 4: Tests
# ============================================
echo "🧪 Phase 4: Tests"
echo "-----------------"

echo "Running tests..."
if flutter test --coverage; then
    print_success "All tests passed"

    # Check coverage if lcov is available
    if command -v lcov &> /dev/null; then
        COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}')
        if [ ! -z "$COVERAGE" ]; then
            print_success "Test coverage: $COVERAGE"
        fi
    fi
else
    print_error "Some tests failed"
fi

echo ""

# ============================================
# PHASE 5: Documentation
# ============================================
echo "📚 Phase 5: Documentation"
echo "-------------------------"

echo "Generating dartdoc..."
if dart doc . --output doc/api 2>&1 | tee /tmp/dartdoc_output.txt; then
    # Check for warnings
    if grep -qi "warning\|error" /tmp/dartdoc_output.txt; then
        print_warning "Dartdoc generated with warnings"
        grep -i "warning\|error" /tmp/dartdoc_output.txt | head -5
    else
        print_success "Documentation generated without warnings"
    fi
else
    print_error "Documentation generation failed"
fi

echo ""

# ============================================
# PHASE 6: Pub Score (pana)
# ============================================
echo "🎯 Phase 6: Pub.dev Score (pana)"
echo "--------------------------------"

# Check if pana is installed
if ! command -v pana &> /dev/null; then
    print_warning "pana not installed"
    echo "   Install with: dart pub global activate pana"
    echo "   Then run: pana ."
else
    echo "Running pana analysis (this may take a minute)..."
    if pana --no-warning > /tmp/pana_output.txt 2>&1; then
        # Extract score
        SCORE=$(grep -oP 'Points: \K\d+' /tmp/pana_output.txt | tail -1)
        if [ ! -z "$SCORE" ]; then
            if [ "$SCORE" -eq 160 ]; then
                print_success "Perfect pub.dev score: ${SCORE}/160 🎉"
            elif [ "$SCORE" -ge 150 ]; then
                print_warning "Good pub.dev score: ${SCORE}/160 (target: 160)"
            else
                print_error "Pub.dev score: ${SCORE}/160 (target: 160)"
            fi

            # Show breakdown
            echo ""
            echo "Score breakdown:"
            grep -A 10 "Points:" /tmp/pana_output.txt | head -15
        fi
    else
        print_error "pana analysis failed"
        echo "   Check output: /tmp/pana_output.txt"
    fi
fi

echo ""

# ============================================
# PHASE 7: Package Structure
# ============================================
echo "📁 Phase 7: Package Structure"
echo "------------------------------"

# Check required files
for file in "LICENSE" "README.md" "CHANGELOG.md" "pubspec.yaml"; do
    if [ -f "$file" ]; then
        print_success "$file present"
    else
        print_error "$file missing"
    fi
done

# Check example directory
if [ -d "example" ] && [ -f "example/pubspec.yaml" ]; then
    print_success "example/ directory properly structured"
else
    print_error "example/ directory missing or incomplete"
fi

echo ""

# ============================================
# SUMMARY
# ============================================
echo "========================================"
echo "📊 VALIDATION SUMMARY"
echo "========================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 PERFECT! Package is ready for 160/160 pub.dev score!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Package is good but has $WARNINGS warning(s)${NC}"
    echo "   Review warnings above and address if needed"
    exit 0
else
    echo -e "${RED}❌ Package has $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo "   Fix errors above before publishing"
    exit 1
fi
