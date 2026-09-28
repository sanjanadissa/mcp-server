# PR Readiness MCP Server

A **Model Context Protocol (MCP)** server that reviews pull requests locally before merge. It checks out PR branches, runs tests, lints code, audits dependencies for vulnerabilities, and generates structured readiness reports.

## Quick Start

### Build

```bash
go build -o bin/prready-server ./cmd/prready-server
go build -o bin/prready-client ./cmd/prready-client
# Or:
make build
```

### Configure

Copy `.prready.example.json` to `.prready.json` and set `repo_path` to the absolute path of your target repository:

```json
{
  "repo_path": "/path/to/your/repo",
  "base_branch": "main"
}
```

### Connect

#### VS Code + Copilot

Copy `configs/vscode.mcp.json.example` to `.vscode/mcp.json` in your workspace. Set paths and your GitHub token.

#### Antigravity

Add server config from `configs/antigravity.mcp_config.json.example` to your MCP settings.

### Demo

```bash
# Create the demo repository with 3 test PRs:
./demo/setup-demo-repo.sh ./demo-repo  # or .ps1 on Windows

# Run the standalone client demo:
make demo
```

In the editor, use the `review_pr` prompt: *"Review PR #1"*

## Architecture

Two MCP servers work together:

| Server | Role |
|---|---|
| **GitHub MCP** (existing) | Reads PR data from GitHub |
| **PR Readiness** (this project) | Local checks: tests, lint, dependency audit, conventions |

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Tools

- `get_repo_status` — Current branch, commit SHA, dirty state
- `checkout_pr` — Check out a PR branch (with SHA verification)
- `run_tests` — Execute test suite, parse results
- `run_linter` — Run linter, extract findings
- `audit_dependencies` — OSV.dev vulnerability scan
- `find_todos` — Scan diff for TODO/FIXME
- `save_report` — Save readiness report to disk

## Resources

- `repo://conventions` — Project rules from CONTRIBUTING.md + README.md
- `report://latest` — Most recent report

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Security](docs/SECURITY.md)
- [Demo Script](docs/DEMO_SCRIPT.md)
- [Related Work](docs/RELATED_WORK.md)
- [Evaluation](docs/EVALUATION.md)
- [Specification](docs/SPEC.md)
