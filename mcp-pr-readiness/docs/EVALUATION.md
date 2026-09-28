# Evaluation Results

## Test PR Results

Results from running the PR Readiness server against the demo repository.

| PR | Branch | Tests | Linter | Dependencies | TODOs | Expected | Actual |
|---|---|---|---|---|---|---|---|
| #1 | pr-a-clean | PASS (4 passed, 0 failed) | PASS (0 findings) | PASS (0 vulns) | PASS | Ready | *To be filled after demo* |
| #2 | pr-b-failing | FAIL (3 passed, 1 failed) | FAIL (1 finding) | PASS (0 vulns) | PASS | Needs changes | *To be filled after demo* |
| #3 | pr-c-vulnerable | PASS (4 passed, 0 failed) | PASS (0 findings) | WARN/FAIL (known CVEs in golang.org/x/text v0.3.0) | PASS | Dependency warning | *To be filled after demo* |

## SHA Mismatch Test

| Step | Input | Expected | Actual |
|---|---|---|---|
| Checkout with matching SHA | `expected_head_sha` matches HEAD | PASS with "SHA match" | *To be filled* |
| Checkout with mismatched SHA | `expected_head_sha` differs from HEAD | WARN with "SHA mismatch" | *To be filled* |

## Tool Listing

*To be filled with actual output from the client demo.*

## Resource Verification

| Resource | Available | Content |
|---|---|---|
| `repo://conventions` | *To verify* | Should contain CONTRIBUTING.md + README.md |
| `report://latest` | *To verify* | "No report" initially, then the last report |

## Notes

- Results will be filled with real outputs after running the full demo workflow.
- The vulnerable dependency test requires that `golang.org/x/text v0.3.0` has active CVEs in OSV.dev (verified: CVE-2020-14040, CVE-2020-28852 are present as of 2024).
