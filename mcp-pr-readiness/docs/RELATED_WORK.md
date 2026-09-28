# Related Work

## Comparison Table

| Project | What It Provides | Gap Addressed by PR Readiness Server |
|---|---|---|
| [GitHub MCP Server](https://github.com/github/github-mcp-server) | Read/write access to GitHub: PRs, issues, repos, diffs, commits, code search | GitHub-side data only; no local checkout, test execution, or dependency audit |
| [Reference `git` MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/git) | Local git operations (status, diff, log, branch) | General git ops; no test/lint execution, no PR workflow, no vulnerability scanning |
| [Reference `filesystem` MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) | File read/write/search on local filesystem | File access only; no git awareness, no test execution |
| [Semgrep MCP](https://semgrep.dev/docs/semgrep-assistant/overview/) | Static analysis and security scanning via Semgrep rules | Focused on SAST patterns; doesn't run tests, check dependencies, or manage PR workflow |
| GitHub Actions / CI Systems | Automated test/lint/build pipelines triggered by events | Runs after push; no interactive LLM-guided review, no real-time developer feedback |
| [Dependabot](https://github.com/dependabot) / [Renovate](https://github.com/renovatebot/renovate) | Automated dependency updates and vulnerability alerts | Creates PRs for updates; doesn't review existing PRs or run tests in context |

## Gap Analysis

Existing MCP servers cover either **GitHub-side data** (PR metadata, diff, commits) or **local operations** (git, filesystem). No project found combines:

1. PR retrieval (via the existing GitHub MCP server)
2. Local checkout of the PR branch
3. Test execution with structured result parsing
4. Lint execution with finding extraction
5. OSV-based dependency vulnerability audit
6. Convention checking against project rules
7. Structured report generation and persistence

The PR Readiness server fills this gap by providing the local validation and report generation layer, designed to work alongside the GitHub MCP server in a multi-server setup.

## Background References

- **MCP Specification**: [Model Context Protocol](https://modelcontextprotocol.io/specification) — the protocol standard for connecting LLMs to external tools and data sources.
- **ReAct** (Yao et al., 2022): "ReAct: Synergizing Reasoning and Acting in Language Models" — the reasoning+acting paradigm that MCP tool use builds upon.
- **Toolformer** (Schick et al., 2023): "Toolformer: Language Models Can Teach Themselves to Use Tools" — foundational work on LLMs learning to invoke external tools.
- **Gorilla** (Patil et al., 2023): "Gorilla: Large Language Model Connected with Massive APIs" — demonstrated effective API calling by LLMs.

## MCP Registry Search

As of September 2026, the [MCP server registry](https://github.com/modelcontextprotocol/servers) and community directories were searched for servers providing PR review, test execution, or dependency auditing capabilities. No existing server was found that combines all aspects of the PR readiness workflow described in this project.
