# Contributing

## Development Workflow

1. Fork and clone the repository.
2. Run `dart pub get` and `dart run melos bootstrap`.
3. Run `dart run melos run format`, `dart run melos run analyze`, and `dart run melos run test` before opening a PR.

## Guidelines

- Keep package boundaries strict.
- Avoid introducing business logic into scaffolding layers.
- Prefer additive, backward-compatible API changes.
- Document architectural trade-offs in PR descriptions.

## Placeholder Sections

- Commit conventions
- Release strategy
- Rule authoring guide
