# Architecture

## System Diagram

```
              MCP Host (VS Code + Copilot agent mode  /  Antigravity)
   +--------------------------------------------------------------+
   |  LLM + MCP Client (one connection per server)                |
   +----------------+--------------------------+------------------+
                    | HTTP (remote) or Docker  | stdio (local process)
                    v                          v
        +---------------------+    +---------------------------------+
        | GitHub MCP Server   |    | PR Readiness MCP Server (Go)    |
        | (existing)          |    |  Tools | Resources | Prompts    |
        +----------+----------+    +---------------+-----------------+
                   |                               |
                   v                               v
              GitHub API             Local repo (git) -> go test, go vet,
        (PR, diff, commits)          OSV.dev API (dependency audit)
```

## MCP Concept Mapping

| MCP Concept | Our Implementation |
|---|---|
| **Host** | VS Code with Copilot or Antigravity IDE — runs the LLM |
| **Client** | Connector inside the host, one per server; also the standalone `prready-client` |
| **Server** | `prready-server` binary running as a local stdio process |
| **Transport** | stdio (stdout = MCP protocol messages, stderr = diagnostic logs) |
| **Tools** | Model-controlled actions: `get_repo_status`, `checkout_pr`, `run_tests`, `run_linter`, `audit_dependencies`, `find_todos`, `save_report` |
| **Resources** | User/app-attached read-only context: `repo://conventions`, `report://latest` |
| **Prompts** | User-triggered templates: `review_pr` |

## Tools

| Tool | Read-Only | Input | Returns |
|---|---|---|---|
| `get_repo_status` | Yes | none | Branch, commit, uncommitted file count |
| `checkout_pr` | **No** | `pr_number`, `branch?`, `expected_head_sha?` | Checkout result with SHA match status |
| `run_tests` | Yes | none | Pass/fail/skip counts, failing test names |
| `run_linter` | Yes | none | Finding count, file:line:col details |
| `audit_dependencies` | Yes | none | Vulnerability counts by severity |
| `find_todos` | Yes | none | TODO/FIXME count in added lines |
| `save_report` | **No** | `pr_number`, `markdown` | Saved file path |

## Resources

| URI | MIME Type | Content |
|---|---|---|
| `repo://conventions` | `text/markdown` | Concatenation of CONTRIBUTING.md + README.md (capped at 64 KB) |
| `report://latest` | `text/markdown` | Most recent report or "No report yet" fallback |

## Prompts

| Prompt | Arguments | Returns |
|---|---|---|
| `review_pr` | `pr_number` (required, digits only) | User-role message instructing the assistant through the full review workflow |

## Data Flow

1. User triggers `review_pr` prompt with a PR number
2. LLM reads PR data from GitHub MCP server
3. LLM calls `checkout_pr` to check out the branch locally
4. LLM calls `run_tests`, `run_linter`, `audit_dependencies`, `find_todos`
5. LLM reads `repo://conventions` for project rules
6. LLM produces a structured report and calls `save_report`
7. Human reviews the report and makes the merge decision

## Dependencies

| Dependency | Reason |
|---|---|
| `github.com/modelcontextprotocol/go-sdk` | Official Go SDK for MCP servers and clients |
| `golang.org/x/mod/modfile` | Parse go.mod files to extract module dependencies for vulnerability audit |

All other functionality uses the Go standard library (`net/http`, `encoding/json`, `os/exec`, `testing`).

## Design Decisions

- **stdio transport**: chosen because the server runs locally alongside the editor. No network exposure, no authentication needed.
- **No shell**: all commands use `exec.CommandContext` with argument arrays to prevent injection.
- **CheckResult struct**: stable JSON interface for all tools, making output parseable and consistent.
- **OSV.dev over govulncheck**: OSV provides a simple HTTP API that doesn't require installing additional tools. govulncheck is a fallback.
