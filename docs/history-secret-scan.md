# History secret scan

Report only. Nothing in git history was rewritten, and repository visibility was not changed.

- Tool: gitleaks 8.28.0, `gitleaks detect --log-opts=--all --redact`.
- Cross-check: a prefix scan over `git log -p --all` for `ghp_`, `github_pat_`, `AKIA`, a private-key header, Slack tokens, `sk-`, `TYPESAFE_API_KEY`, and `OPENCODE_GO_API_KEY`. The scan counted matches and did not print match text.
- Range: the one commit on the default branch, `9a5139f`, plus the working tree of this branch. CI repeats the gitleaks scan on the full history of the pull request (`fetch-depth: 0`).
- Result: **CLEAN**. 0 findings from gitleaks. 0 prefix hits.

Owner rule, 2026-10-17 15:42 UTC+4: keys are never rotated or revoked. A live-looking key would be listed as path and commit only, and marked `repo must stay private (owner rule)`. No such key was found.
