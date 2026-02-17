# Contributing

Thanks for contributing to MacWiFi.

## Prerequisites

1. macOS 14+
2. Xcode 16+
3. Swift toolchain compatible with `swift-tools-version: 5.9`

## Local Setup

1. Fork and clone the repository.
2. Build from terminal:

```bash
./scripts/build_local.sh
```

3. Run from terminal:

```bash
./scripts/build-and-run.sh
```

## Run Checks

Run the same commands CI runs before opening a PR:

```bash
swift build
if [ -d Tests ]; then swift test; else echo "No Tests target yet"; fi
```

Optional sanitization check:

```bash
rg -n "\\bapk-installer\\b|\\bkiran\\b|CERT_PASSWORD" Sources scripts docs README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md .github/workflows
git ls-files | rg "(\\.cer$|\\.p12$|xcuserdata|xcuserstate)"
```

## Development Guidelines

- Keep changes focused and reviewable.
- Add or update tests for behavior changes where practical.
- Update docs in the same PR when behavior or workflows change.
- Avoid hardcoded machine-specific paths.
- Do not commit secrets, certificates, provisioning profiles, or generated binaries.

## Pull Request Guidelines

1. Link related issue(s) when available.
2. Explain what changed and why.
3. Include testing evidence (commands run and results).
4. Add screenshots/GIFs for UI changes.
5. Confirm no unrelated refactors or formatting-only churn.

## Commit Style

Conventional Commits are recommended:

- `feat: ...`
- `fix: ...`
- `docs: ...`
- `test: ...`
- `refactor: ...`
- `chore: ...`

## Security Issues

Do not open public issues for vulnerabilities. Follow `SECURITY.md` for responsible disclosure.
