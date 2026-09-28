# setup-demo-repo.ps1 - Creates a Go demo repository with 3 PR branches.
#
# This script creates a small Go module with a calc package, tests, and
# CONTRIBUTING.md. It then creates three branches simulating different PRs:
#   - pr-a-clean: Clean PR (new function + test, vet passes)
#   - pr-b-failing: Failing PR (bad test + vet finding)
#   - pr-c-vulnerable: Vulnerable dependency (old golang.org/x/text)
#
# Usage: .\setup-demo-repo.ps1 [-Target <directory>]

param(
    [string]$Target = ".\demo-repo"
)

$ErrorActionPreference = "Stop"

if (Test-Path $Target) {
    Remove-Item -Recurse -Force $Target
}

Write-Host "Creating demo repository at $Target..."

New-Item -ItemType Directory -Path $Target -Force | Out-Null
Push-Location $Target

try {
    # Initialize git repo and Go module.
    git init
    git config user.email "demo@example.com"
    git config user.name "Demo User"

    go mod init example.com/demo-calc

    # Create the main calc package.
    New-Item -ItemType Directory -Path "calc" -Force | Out-Null

    @'
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
'@ | Set-Content -Path "calc\calc.go" -Encoding UTF8

    @'
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
'@ | Set-Content -Path "calc\calc_test.go" -Encoding UTF8

    # CONTRIBUTING.md
    @'
# Contributing to demo-calc

## Rules

1. **Tests required**: Every new function must have corresponding test cases.
2. **go vet must pass**: Run `go vet ./...` before submitting. No warnings allowed.
3. **Commit message style**: Use imperative mood (e.g., "Add Divide function").
4. **No TODO/FIXME in PRs**: Address all TODOs before submitting for review.
5. **Documentation**: All exported functions must have doc comments.
'@ | Set-Content -Path "CONTRIBUTING.md" -Encoding UTF8

    # README.md
    @'
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
'@ | Set-Content -Path "README.md" -Encoding UTF8

    git add .
    git commit -m "Initial commit: calc package with Add, Subtract, Multiply"
    git branch -M main

    Write-Host ""
    Write-Host "=== Creating PR branches ==="

    # --- PR A: Clean PR ---
    git checkout -b pr-a-clean

    @'

// Divide returns the quotient of a divided by b.
// Returns 0 if b is zero (division by zero).
func Divide(a, b int) int {
    if b == 0 {
        return 0
    }
    return a / b
}
'@ | Add-Content -Path "calc\calc.go" -Encoding UTF8

    @'

func TestDivide(t *testing.T) {
    tests := []struct {
        a, b, want int
    }{
        {10, 2, 5},
        {7, 3, 2},
        {10, 0, 0},
    }
    for _, tt := range tests {
        got := Divide(tt.a, tt.b)
        if got != tt.want {
            t.Errorf("Divide(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
        }
    }
}
'@ | Add-Content -Path "calc\calc_test.go" -Encoding UTF8

    git add .
    git commit -m "Add Divide function with tests"
    Write-Host "Created branch pr-a-clean (expected: Ready)"

    # --- PR B: Failing PR ---
    git checkout main
    git checkout -b pr-b-failing

    @'

// Modulo returns the remainder of a divided by b.
func Modulo(a, b int) int {
    return a % b
}

// Power computes a^b (integer exponentiation).
func Power(a, b int) int {
    result := 1
    for i := 0; i < b; i++ {
        result *= a
    }
    return result
}
'@ | Add-Content -Path "calc\calc.go" -Encoding UTF8

    @'

func TestModulo(t *testing.T) {
    got := Modulo(10, 3)
    if got != 2 {
        t.Errorf("Modulo(10, 3) = %d, want 2", got)
    }
}
'@ | Add-Content -Path "calc\calc_test.go" -Encoding UTF8

    @'
package calc

import "fmt"

// DebugPrint prints a calculation result (has a go vet finding).
func DebugPrint(name string, value int) {
    fmt.Printf("%d: %s\n", name, value)
}
'@ | Set-Content -Path "calc\debug.go" -Encoding UTF8

    git add .
    git commit -m "Add Modulo and Power (has issues)"
    Write-Host "Created branch pr-b-failing (expected: Needs changes)"

    # --- PR C: Vulnerable dependency ---
    git checkout main
    git checkout -b pr-c-vulnerable

    @'
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
'@ | Set-Content -Path "calc\transform.go" -Encoding UTF8

    @'

func TestNormalizeString(t *testing.T) {
    got := NormalizeString("hello")
    if got != "hello" {
        t.Errorf("NormalizeString(\"hello\") = %%q, want \"hello\"", got)
    }
}
'@ | Add-Content -Path "calc\calc_test.go" -Encoding UTF8

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    go get "golang.org/x/text@v0.3.0" 2>&1 | Out-Null
    go mod tidy 2>&1 | Out-Null
    $ErrorActionPreference = $prevEAP

    git add .
    git commit -m "Add text normalization with golang.org/x/text dependency"
    Write-Host "Created branch pr-c-vulnerable (expected: Dependency warning/fail)"

    git checkout main

    Write-Host ""
    Write-Host "=== Demo repository created at $Target ==="
    Write-Host ""
    Write-Host "Branches:"
    git branch
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Create a GitHub repository and push all branches"
    Write-Host "2. Open 3 PRs on GitHub (one per branch -> main)"
    Write-Host "3. Configure .prready.json with the absolute path to this repo"

} finally {
    Pop-Location
}
