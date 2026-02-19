# Quality Gates

This document describes the escalating quality gate chain used in mock-pve-api:
**pre-commit (fast) -> pre-push (thorough) -> CI (comprehensive)**.

See [ADR-0002](../adr/0002-adopt-development-best-practices.md) for the decision
rationale behind these practices.

## Quality Gate Chain

| Check | Pre-commit | Pre-push | CI |
|-------|-----------|----------|-----|
| `mix format --check-formatted` | yes | - | yes |
| `mix compile --warnings-as-errors` | yes | - | yes (`--force`) |
| `mix docs.coverage --check` | conditional | - | - |
| `gitleaks protect --staged` | yes | - | - |
| `gitleaks detect` | - | - | yes |
| OpenSSF Scorecard | - | - | yes (main only) |
| `mix test` | - | yes | yes (`--cover`) |
| `mix docs` | - | - | yes |
| Security audit / SBOM | - | - | yes |
| Container build + integration | - | - | yes |

## Local Development

### EditorConfig

`.editorconfig` enforces consistent formatting across editors:

- UTF-8, LF line endings, final newline, trim trailing whitespace
- 2-space indent for Elixir (`.ex`, `.exs`), YAML, JSON
- Tab indent for `Makefile`
- Trailing whitespace preserved for Markdown

### Lefthook

[Lefthook](https://github.com/evilmartians/lefthook) manages git hooks,
replacing the previous ad-hoc shell script. Configuration lives in
`.lefthook.yml`.

#### Pre-commit (parallel)

Runs on every `git commit` when `.ex`/`.exs` files are staged:

| Command | Trigger | What it catches |
|---------|---------|-----------------|
| `mix format --check-formatted` | `*.{ex,exs}` staged | Formatting violations |
| `mix compile --warnings-as-errors` | `*.{ex,exs}` staged | Compiler warnings |
| `mix docs.coverage --check` | `lib/mock_pve_api/coverage.ex` staged | Outdated API reference docs |
| `gitleaks protect --staged` | always | Secrets in staged changes |

All four commands run in parallel for speed.

#### Pre-push

Runs on every `git push`:

| Command | What it catches |
|---------|-----------------|
| `mix test` | Test regressions |

### Installation

```bash
make install-hooks    # Downloads lefthook if needed, then installs hooks
make uninstall-hooks  # Removes hooks
make check-deps       # Verifies lefthook and gitleaks are available
```

### Skipping hooks

In exceptional cases (e.g. work-in-progress commits):

```bash
LEFTHOOK=0 git commit -m "wip"    # Skip pre-commit
LEFTHOOK=0 git push               # Skip pre-push
```

## CI (GitHub Actions)

The CI pipeline is defined in `.github/workflows/ci.yml`. Jobs run on pushes
to `main` and `develop`, and on pull requests to `main`.

### Jobs

| Job | Trigger | Dependencies | Purpose |
|-----|---------|-------------|---------|
| `test` | all | - | Matrix build (Elixir 1.15-1.17 x OTP 26-27), format, compile, test, docs |
| `secret-scan` | all | - | Gitleaks full history scan |
| `scorecard` | main only | - | OpenSSF Scorecard evaluation |
| `security-audit` | all | test | SBOM generation (Syft), vulnerability scan (Grype) |
| `docker-build` | all | test, security-audit | Multi-arch container build, container SBOM |
| `integration-test` | non-PR | docker-build | Smoke tests against PVE 7.4, 8.3, 9.0 containers |

### Test matrix

```
Elixir 1.15 + OTP 26
Elixir 1.16 + OTP 26, 27
Elixir 1.17 + OTP 26, 27
```

### OpenSSF Scorecard

The `scorecard` job runs `ossf/scorecard-action@v2.4.1` on pushes to `main`.
Results are uploaded as a build artifact (`scorecard-results.json`, 90-day
retention).

Baseline score (2026-02-13): **2.2 / 10**

| Score | Check | Notes |
|-------|-------|-------|
| 10/10 | Binary-Artifacts | No binaries in repo |
| 10/10 | Vulnerabilities | No known vulnerabilities |
| 0/10 | Branch-Protection | Enabled (no force push, no deletion) |
| 0/10 | License | Detected once changes reach `main` |
| 0/10 | Security-Policy | `SECURITY.md` added |
| 0/10 | Dependency-Update-Tool | Dependabot configured |
| 0/10 | Maintained | Will improve with time (repo <90 days old) |
| 0/10 | Code-Review | Will improve as PRs flow |
| 0/10 | Contributors | Solo project |
| ? | CI-Tests | Will score once PRs are opened |

Several checks (License, Security-Policy, Dependency-Update-Tool,
Branch-Protection) will improve once the current `develop` changes are merged
to `main` and the scorecard runs against them.

## Secret Detection

[Gitleaks](https://github.com/gitleaks/gitleaks) runs at two levels:

- **Pre-commit**: `gitleaks protect --staged` scans only staged changes (fast)
- **CI**: `gitleaks/gitleaks-action@v2` scans full git history with
  `fetch-depth: 0`

Custom rules can be added via `.gitleaks.toml` if needed.

## SPDX Headers

All source files carry machine-readable copyright and licence metadata:

```
# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT
```

This covers `.ex`, `.exs`, `.sh`, `Dockerfile`, `Makefile`, and CI workflow
files.

## Dependency Updates

Dependabot is configured in `.github/dependabot.yml` for:

- **Mix dependencies**: weekly checks, up to 5 open PRs
- **GitHub Actions**: weekly checks, up to 5 open PRs

## Erlef Aegis & OpenSSF Alignment

The quality gates align with the [EEF Security Working Group's Aegis
initiative](https://security.erlef.org/aegis/) and [OpenSSF](https://openssf.org/)
best practices:

- **SBOM generation**: SPDX and CycloneDX formats (see
  [sbom-and-security.md](sbom-and-security.md))
- **SPDX headers**: Machine-readable licence metadata on all source files
- **Secret detection**: Gitleaks at pre-commit and in CI
- **Vulnerability scanning**: Grype in CI pipeline
- **Dependency tracking**: `mix.lock` with Dependabot updates
- **Security policy**: `SECURITY.md` with disclosure process
- **Branch protection**: `main` protected against force push and deletion
- **OpenSSF Scorecard**: Automated evaluation in CI on pushes to `main`

Items pending external dependencies:

- Hex.pm account security recommendations (as Aegis tooling matures)
- Signed container image provenance (pending Docker Hub release)
