#!/bin/bash
# Cross-Compilation Test Script
# Tests building for all supported platforms

set -e

echo "======================================"
echo "  Cross-Compilation Test"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Track results
PASSED=0
FAILED=0
declare -a FAILED_TARGETS

# Test function
test_build() {
    local target=$1
    local name=$2
    
    echo -e "${YELLOW}Testing: $name ($target)${NC}"
    
    if zig build -Dtarget="$target" -Doptimize=ReleaseFast 2>&1 | grep -q "error:"; then
        echo -e "${RED}✗ FAILED${NC}"
        FAILED=$((FAILED + 1))
        FAILED_TARGETS+=("$name")
    else
        # Check if binary exists
        if [ "$target" == *"windows"* ]; then
            if [ -f "zig-out/bin/midi_player.exe" ]; then
                local size=$(du -h zig-out/bin/midi_player.exe | cut -f1)
                echo -e "${GREEN}✓ PASSED${NC} (Binary: $size)"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}✗ FAILED (binary not found)${NC}"
                FAILED=$((FAILED + 1))
                FAILED_TARGETS+=("$name")
            fi
        else
            if [ -f "zig-out/bin/midi_player" ]; then
                local size=$(du -h zig-out/bin/midi_player | cut -f1)
                echo -e "${GREEN}✓ PASSED${NC} (Binary: $size)"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}✗ FAILED (binary not found)${NC}"
                FAILED=$((FAILED + 1))
                FAILED_TARGETS+=("$name")
            fi
        fi
    fi
    echo ""
}

echo "Testing cross-compilation for all platforms..."
echo ""

# Linux builds
test_build "x86_64-linux-gnu" "Linux x86_64"
test_build "aarch64-linux-gnu" "Linux ARM64"

# Windows build
test_build "x86_64-windows" "Windows x86_64"

# macOS builds
test_build "x86_64-macos" "macOS Intel"
test_build "aarch64-macos" "macOS Apple Silicon"

# BSD builds
test_build "x86_64-freebsd" "FreeBSD x86_64"

# Summary
echo "======================================"
echo "  Test Summary"
echo "======================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    echo "Failed targets:"
    for target in "${FAILED_TARGETS[@]}"; do
        echo -e "  ${RED}✗${NC} $target"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
fi
echo "======================================"
