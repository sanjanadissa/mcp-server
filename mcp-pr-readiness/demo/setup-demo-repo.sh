#!/usr/bin/env bash
# setup-demo-repo.sh - Creates a Go demo repository with 3 PR branches.
#
# This script creates a small Go module with a calc package, tests, and
# CONTRIBUTING.md. It then creates three branches simulating different PRs:
#   - pr-a-clean: Clean PR (new function + test, vet passes)
#   - pr-b-failing: Failing PR (bad test + vet finding)
#   - pr-c-vulnerable: Vulnerable dependency (old golang.org/x/text)
#
# Usage: ./setup-demo-repo.sh [target-directory]

set -euo pipefail

TARGET="${1:-./demo-repo}"

if [ -d "$TARGET" ]; then
    echo "ERROR: Directory $TARGET already exists. Remove it first."
    exit 1
fi

echo "Creating demo repository at $TARGET..."

mkdir -p "$TARGET"
cd "$TARGET"

# Initialize git repo and Go module.
git init
git config user.email "demo@example.com"
git config user.name "Demo User"

go mod init example.com/demo-calc

# Create the main calc package.
mkdir -p calc

cat > calc/calc.go << 'EOF'
// Package calc provides simple arithmetic functions for demonstration.
package calc

// Add returns the sum of two integers.
func Add(a, b int) int {
    return a + b
}

// Subtract returns the difference of two integers.
func Subtract(a, b int) int {
    return a - b
}

// Multiply returns the product of two integers.
func Multiply(a, b int) int {
    return a * b
}
EOF

cat > calc/calc_test.go << 'EOF'
package calc

import "testing"

func TestAdd(t *testing.T) {
    tests := []struct {
        a, b, want int
    }{
        {1, 2, 3},
        {0, 0, 0},
        {-1, 1, 0},
        {100, 200, 300},
    }
    for _, tt := range tests {
        got := Add(tt.a, tt.b)
        if got != tt.want {
            t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
        }
    }
}

func TestSubtract(t *testing.T) {
    got := Subtract(10, 3)
    if got != 7 {
        t.Errorf("Subtract(10, 3) = %d, want 7", got)
    }
}

func TestMultiply(t *testing.T) {
    got := Multiply(4, 5)
    if got != 20 {
        t.Errorf("Multiply(4, 5) = %d, want 20", got)
    }
}
EOF

# Create CONTRIBUTING.md with real rules.
cat > CONTRIBUTING.md << 'EOF'
# Contributing to demo-calc

## Rules

1. **Tests required**: Every new function must have corresponding test cases.
2. **go vet must pass**: Run `go vet ./...` before submitting. No warnings allowed.
3. **Commit message style**: Use imperative mood (e.g., "Add Divide function").
4. **No TODO/FIXME in PRs**: Address all TODOs before submitting for review.
5. **Documentation**: All exported functions must have doc comments.
EOF

# Create README.md.
cat > README.md << 'EOF'
# demo-calc

A simple Go calculator package for demonstrating the PR Readiness MCP server.

## Usage

```go
import "example.com/demo-calc/calc"

result := calc.Add(2, 3) // 5
```

## Testing

```bash
go test ./...
```
EOF

# Commit the main branch.
git add .
git commit -m "Initial commit: calc package with Add, Subtract, Multiply"

# Rename default branch to main if needed.
git branch -M main

echo ""
echo "=== Creating PR branches ==="

# --- PR A: Clean PR ---
git checkout -b pr-a-clean
cat >> calc/calc.go << 'EOF'

// Divide returns the quotient of a divided by b.
// Returns 0 if b is zero (division by zero).
func Divide(a, b int) int {
    if b == 0 {
        return 0
    }
    return a / b
}
EOF

cat >> calc/calc_test.go << 'EOF'

func TestDivide(t *testing.T) {
    tests := []struct {
        a, b, want int
    }{
        {10, 2, 5},
        {7, 3, 2},
        {10, 0, 0}, // division by zero returns 0
    }
    for _, tt := range tests {
        got := Divide(tt.a, tt.b)
        if got != tt.want {
            t.Errorf("Divide(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
        }
    }
}
EOF

git add .
git commit -m "Add Divide function with tests"
echo "Created branch pr-a-clean (expected: Ready)"

# --- PR B: Failing PR ---
git checkout main
git checkout -b pr-b-failing

cat >> calc/calc.go << 'EOF'

// Modulo returns the remainder of a divided by b.
func Modulo(a, b int) int {
    return a % b // BUG: doesn't handle b==0
}

// Power computes a^b (integer exponentiation).
func Power(a, b int) int {
    // go vet will flag this: Printf format mismatch
    result := 1
    for i := 0; i < b; i++ {
        result *= a
    }
    return result
}
EOF

cat >> calc/calc_test.go << 'EOF'

func TestModulo(t *testing.T) {
    got := Modulo(10, 3)
    if got != 2 { // BUG: 10 % 3 = 1, not 2
        t.Errorf("Modulo(10, 3) = %d, want 2", got)
    }
}
EOF

# Add a file with a go vet finding.
cat > calc/debug.go << 'EOF'
package calc

import "fmt"

// DebugPrint prints a calculation result (has a go vet finding).
func DebugPrint(name string, value int) {
    fmt.Printf("%d: %s\n", name, value) // Wrong: %d for string, %s for int
}
EOF

git add .
git commit -m "Add Modulo and Power (has issues)"
echo "Created branch pr-b-failing (expected: Needs changes)"

# --- PR C: Vulnerable dependency ---
git checkout main
git checkout -b pr-c-vulnerable

# Add an old, vulnerable version of golang.org/x/text.
# golang.org/x/text v0.3.0 has known CVEs (e.g., CVE-2020-14040, CVE-2020-28852).
cat > calc/transform.go << 'EOF'
package calc

import (
    "golang.org/x/text/transform"
    "golang.org/x/text/unicode/norm"
    "strings"
)

// NormalizeString applies NFC normalization to a string.
func NormalizeString(s string) string {
    result, _, _ := transform.String(norm.NFC, s)
    return result
}

// ToUpperNormalized normalizes and uppercases a string.
func ToUpperNormalized(s string) string {
    return strings.ToUpper(NormalizeString(s))
}
EOF

cat >> calc/calc_test.go << 'EOF'

func TestNormalizeString(t *testing.T) {
    // Basic test that normalization works.
    got := NormalizeString("hello")
    if got != "hello" {
        t.Errorf("NormalizeString(\"hello\") = %q, want \"hello\"", got)
    }
}
EOF

# Pin to vulnerable version.
go get golang.org/x/text@v0.3.0 2>/dev/null || true
go mod tidy 2>/dev/null || true

git add .
git commit -m "Add text normalization with golang.org/x/text dependency"
echo "Created branch pr-c-vulnerable (expected: Dependency warning/fail)"

# Return to main.
git checkout main

echo ""
echo "=== Demo repository created at $TARGET ==="
echo ""
echo "Branches:"
git branch
echo ""
echo "Next steps:"
echo "1. Create a GitHub repository and push all branches:"
echo "   git remote add origin https://github.com/YOUR_USER/demo-calc.git"
echo "   git push -u origin main pr-a-clean pr-b-failing pr-c-vulnerable"
echo "2. Open 3 PRs on GitHub (one per branch -> main)"
echo "3. Configure .prready.json with the absolute path to this repo"
echo "4. Run the PR Readiness server"
