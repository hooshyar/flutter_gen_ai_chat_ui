#!/bin/bash

# Quick validation script - faster checks without pana
# Run this before the full validation for rapid feedback

echo "🔍 Quick Package Health Check"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗${NC} Flutter not found"
    exit 1
fi

echo -e "${GREEN}✓${NC} Flutter found"

# Quick analyze
echo ""
echo "Running quick analysis..."
if dart analyze --fatal-infos 2>&1 | head -20; then
    echo -e "${GREEN}✓${NC} No immediate issues"
else
    echo -e "${RED}✗${NC} Analysis issues found"
    ((ERRORS++))
fi

# Format check
echo ""
echo "Checking formatting..."
if dart format --output=none --set-exit-if-changed . > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Code is formatted"
else
    echo -e "${YELLOW}⚠${NC} Code needs formatting (run: dart format .)"
fi

# Test
echo ""
echo "Running tests..."
if flutter test > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Tests pass"
else
    echo -e "${RED}✗${NC} Tests failing"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Quick check passed!${NC} Run ./scripts/validate_pub_score.sh for full validation"
    exit 0
else
    echo -e "${RED}✗ Quick check found $ERRORS error(s)${NC}"
    exit 1
fi
