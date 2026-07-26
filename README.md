# Vyrax

Vyrax is a Flutter architecture and performance analyzer for developers and teams.

## Vision

Vyrax provides deep static analysis for Flutter projects by building on top of the Dart Analyzer API. The goal is to offer architectural clarity, performance insights, and actionable fixes without becoming another generic linter.

## Monorepo

This repository uses a Melos-managed monorepo to keep package boundaries explicit while enabling coordinated releases and tooling.

## Package Overview

- `vyrax_core`: Core abstractions, issue models, configuration types, and plugin interfaces.
- `vyrax_engine`: Analyzer engine scaffolding, rule orchestration surfaces, and future AST traversal entry points.
- `vyrax_rules`: Rule package reserved for Flutter-focused rule implementations.
- `vyrax_cli`: Command-line interface for future workflows (`init`, `analyze`, `doctor`, `score`, `explain`, `fix`).
- `vyrax_annotations`: Annotation package reserved for future source-level metadata.
- `examples/sample_app`: Standard Flutter app used as a target project for rule validation.

## Development

### Prerequisites

- Dart 3.x
- Flutter stable
- Melos (`dart pub global activate melos` or run via `dart run melos`)

### Setup

```bash
dart pub get
dart run melos bootstrap
```

### Common Tasks

```bash
dart run melos run format
dart run melos run analyze
dart run melos run test
```

## Roadmap

- Analyzer engine execution pipeline
- Flutter-specific architecture and performance rules
- Quick-fix framework
- Plugin ecosystem
- VS Code extension
- Dashboard and reporting surfaces

See `docs/ARCHITECTURE.md` and `docs/ROADMAP.md` for details.
