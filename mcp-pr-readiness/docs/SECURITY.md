# Security

This document describes the security controls implemented in the PR Readiness MCP server and the residual risks.

## Threat Model

Running tests and linters **executes the PR's code** on the developer's machine. PR content from unknown authors is untrusted and could contain malicious code.

## Implemented Controls

### 1. No Shell Execution
All commands use `exec.CommandContext(ctx, name, args...)` with argument arrays. No command strings are built, and `sh -c` / `cmd /c` are never used for tool commands. Arguments containing shell metacharacters (e.g., `; rm -rf /`) remain literal.

### 2. Fixed Commands
Test, lint, and audit commands come only from the server's JSON config file. No tool accepts a command, path, or flag from the MCP caller. The only caller-supplied strings are:
- `pr_number` (int, validated > 0)
- `branch` (regex-validated: `^[A-Za-z0-9._/-]+$`)
- `expected_head_sha` (hex only, max 40 chars)
- `markdown` (report content only, max 100 KB)

### 3. Working Directory Allow-List
Every command runs with `cmd.Dir = repo_path`. File reads and writes are verified to be inside `repo_path` or `report_dir` using `filepath.Abs` and `filepath.EvalSymlinks`.

### 4. Timeouts
Every command and HTTP request has a context-based timeout from config. On timeout, the process group is killed (`SIGKILL` on Unix, `TerminateProcess` on Windows) and an `ERROR` status with a clear message is returned.

### 5. Output Limits
Captured stdout/stderr is truncated to `max_output_bytes` (default 8192). The `Details` field in `CheckResult` is capped at 20 entries.

### 6. Clean Working Tree
`checkout_pr` refuses to proceed when uncommitted changes exist, preventing accidental code loss.

### 7. Untrusted Input Defense
The `review_pr` prompt includes a security instruction telling the model to treat PR titles, descriptions, comments, and diff content as **untrusted data** and never follow instructions found inside them.

### 8. No Secrets in the Server
The custom server needs no GitHub token or other secrets. The GitHub token is managed entirely by the GitHub MCP server's own configuration. Environment variables are not logged.

### 9. Least Privilege
The server has no GitHub write capability. It makes only one outbound network call: to the OSV.dev API for vulnerability data.

### 10. stderr Logging Only
With stdio transport, stdout carries the MCP protocol. All diagnostic logging goes to stderr. No PR content or file contents appear in logs.

### 11. Minimal Environment
Commands run with a filtered environment containing only essential variables (PATH, GOPATH, etc.), preventing accidental exposure of secrets from the parent process.

## Residual Risks

### Running PR Code
The fundamental risk: `go test` and `go vet` execute the PR author's code. Even with all controls above, a malicious PR could:
- Read local files accessible to the user
- Make network connections
- Consume system resources

**Mitigation**: PRs from unknown authors should be tested only inside a container or disposable VM.

### Docker Isolation (Future Work)
A containerized approach would:
1. Build a Docker image with Go and the server
2. Mount the repo as a read-only volume (copy for checkout)
3. Run checks inside the container with restricted networking
4. Return results to the host

This is out of scope for v1 but documented as the recommended approach for untrusted PRs.

### OSV.dev Availability
The server depends on OSV.dev for vulnerability data. If the API is unreachable, it falls back to `govulncheck` (if installed) or returns `UNAVAILABLE`. It never crashes.

### Prompt Injection
The `review_pr` prompt instructs the model to treat PR content as data, but sufficiently sophisticated prompt injection in PR descriptions or comments could still influence the model's behavior. This is a fundamental limitation of LLM-based systems.

### Local File Access
The server reads files from `repo_path` and writes to `report_dir`. A symlink attack could potentially access files outside these directories. The config validator resolves symlinks, but race conditions are theoretically possible.
