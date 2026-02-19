# Sprint 4.7 - Quality Gates & Compliance

**Sprint Duration**: 1 day
**Sprint Goal**: Establish consistent quality gates, SPDX/OpenSSF compliance, and GHCR container registry
**Start Date**: 2026-02-13
**End Date**: 2026-02-13
**Version**: v0.4.7

## Sprint Objective

Add an escalating quality gate chain (pre-commit / pre-push / CI) via lefthook, meet Erlef Aegis and OpenSSF Scorecard requirements, and migrate container images to GitHub Container Registry.

## Completed Work

### Quality Gates (lefthook)
- `.editorconfig` for consistent editor formatting
- `.lefthook.yml` with pre-commit (format, compile, docs-coverage, gitleaks) and pre-push (test)
- `.gitleaks.toml` allowlist for mock data false positives
- `mix docs.coverage` task for API reference generation

### Erlef Aegis & OpenSSF Compliance
- SPDX copyright/licence headers on all source files
- `SECURITY.md` with solo-maintainer security policy
- Dependabot for Mix and GitHub Actions dependencies
- OpenSSF Scorecard in CI (`ossf/scorecard-action@v2.4.1`, main only)
- Branch protection on `main` (no force push, no deletion)

### GHCR Container Registry
- CI workflow uses `ghcr.io/jrjsmrtn/mock-pve-api` with GITHUB_TOKEN auth
- Container SBOM generation for published images

### Test Coverage
- Added unit tests to reach 92% code coverage (562 tests, 0 failures)
- Fixed version compatibility tests and capability system (52/52 passing)
- Modernised GitHub Actions workflow (actions/cache@v4, upload-artifact@v4)

### Documentation
- Extracted `docs/reference/quality-gates.md` from ADR-0002

## Commits

| Hash | Description |
|------|-------------|
| `1abc523` | refactor: apply mix format and add docs.coverage task |
| `a8a3c61` | fix: repair version compatibility tests and capability system |
| `cc2a45f` | chore: bump version to 0.4.7 |
| `003c9ff` | chore: add quality gates, SPDX headers, and OpenSSF compliance |
| `85c12ab` | chore: add OpenSSF Scorecard, switch to GHCR, extract quality gates doc |
| `6aaaa12` | test: add unit tests to reach 92% code coverage |

## Sprint Retrospective

### What Went Well
- Lefthook hook chain catches issues early without slowing development
- SPDX headers applied cleanly across all source files
- Test coverage jump from baseline to 92%

### What Could Be Improved
- Sprint document should have been written at the time, not retroactively

---

**Sprint Status**: COMPLETED
**Next Sprint**: Sprint 4.8 - pve-openapi Integration & Code Quality
