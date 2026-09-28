# Demo Script

## Prerequisites

1. Go installed (1.21+)
2. Git installed
3. A GitHub account with a personal access token (read-only scopes)
4. The PR Readiness server built: `make build`

## Setup (5 minutes)

### 1. Create the Demo Repository

```bash
# On Linux/macOS:
./demo/setup-demo-repo.sh ./demo-repo

# On Windows PowerShell:
.\demo\setup-demo-repo.ps1 -Target .\demo-repo
```

### 2. Push to GitHub

```bash
cd demo-repo
git remote add origin https://github.com/YOUR_USER/demo-calc.git
git push -u origin main pr-a-clean pr-b-failing pr-c-vulnerable
```

### 3. Open Pull Requests

On GitHub, create 3 PRs:
- **PR #1**: `pr-a-clean` → `main` (title: "Add Divide function")
- **PR #2**: `pr-b-failing` → `main` (title: "Add Modulo and Power")
- **PR #3**: `pr-c-vulnerable` → `main` (title: "Add text normalization")

### 4. Configure the Server

Create `.prready.json` in the project root:

```json
{
  "repo_path": "/absolute/path/to/demo-repo",
  "base_branch": "main",
  "test_cmd": ["go", "test", "./...", "-json"],
  "test_format": "gotest-json",
  "lint_cmd": ["go", "vet", "./..."],
  "dependency_file": "go.mod",
  "report_dir": "./reports"
}
```

### 5. Configure the Host

#### VS Code + Copilot

Copy `configs/vscode.mcp.json.example` to `.vscode/mcp.json` and fill in paths.

#### Antigravity

Add the server config to your MCP settings (see `configs/antigravity.mcp_config.json.example`).

## Demo Workflow (5 minutes)

### Option A: Using the Editor Host

1. Open the workspace in VS Code or Antigravity
2. Open Copilot Chat in agent mode (or the Antigravity chat)
3. Type: "Use the review_pr prompt to review PR #1"
4. Watch the assistant:
   - Call `checkout_pr` to switch to the PR branch
   - Call `run_tests`, `run_linter`, `audit_dependencies`
   - Read `repo://conventions`
   - Generate and save the report
5. Repeat for PR #2 (failing) and PR #3 (vulnerable)

### Option B: Using the Standalone Client

```bash
make demo
# Or manually:
./bin/prready-client --server ./bin/prready-server --config .prready.json
```

This lists all tools, resources, and prompts, then calls `get_repo_status` and `run_tests`.

## Expected Results

| PR | Tests | Linter | Dependencies | Recommendation |
|---|---|---|---|---|
| #1 (pr-a-clean) | PASS | PASS | PASS | Ready for review |
| #2 (pr-b-failing) | FAIL | FAIL | PASS | Needs changes |
| #3 (pr-c-vulnerable) | PASS | PASS | WARN/FAIL | Dependency warning |

## SHA Mismatch Test

To test SHA verification:
1. Note the HEAD SHA of PR #1 on GitHub
2. Push a new commit to the `pr-a-clean` branch
3. Call `checkout_pr` with the old SHA as `expected_head_sha`
4. The result should show WARN with "SHA mismatch"
