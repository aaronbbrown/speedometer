# Copilot Instructions for Speedometer (iOS)

## Execution Policy: Prefer Make Targets

- Use Makefile targets as the default interface for this repository.
- Prefer these commands over ad-hoc xcodebuild/simctl commands when possible:
1. make generate
2. make build
3. make build-clean
4. make test
5. make warnings
6. make sim-run
7. make clean
- Only drop to raw xcodebuild/simctl when debugging a Make target itself.

## Quality Gate: Warnings and Deprecations

- Treat new compiler warnings as defects to fix in the same change when feasible.
- Proactively check for API deprecations after edits to Swift files, especially Location, Locale, and UIKit APIs.
- Prefer current stable APIs over deprecated ones, even if older APIs still compile.

## Required Validation for Swift/iOS Changes

For changes that touch Swift source, project config, or plist metadata:

1. Run make build or make build-clean for simulator validation.
2. Run make warnings to scan for warning/deprecation patterns.
3. If warnings appear and are related to the change, fix them before considering the task done.

## Info.plist and Runtime Metadata Safety

- Preserve required iOS runtime keys when editing plist files.
- If plist changes are made, validate app launch behavior in simulator (no letterboxing/black bars/regressions).

## Scope and Pragmatism

- Do not over-engineer migrations; make the smallest safe forward-compatible update.
- If a warning comes from third-party or generated code, report it clearly and avoid risky unrelated edits.
