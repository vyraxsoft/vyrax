# vyrax_cli

Command-line interface for Vyrax, focused on Flutter architecture and performance analysis.

The CLI currently supports:
- Project-aware `vyrax init` with stack detection and safe overwrite prompts.
- `vyrax analyze` in text or JSON format.

## Installation

### From pub.dev (global)

```bash
dart pub global activate vyrax_cli
```

Then ensure your pub global binaries path is in `PATH`.

Do not add `vyrax_cli` under your app `dependencies` or `dev_dependencies` in `pubspec.yaml`.
Use it as a global CLI tool.

## Quick Start

Run in your Flutter project root:

```bash
vyrax init
vyrax analyze
```

## Commands

### `vyrax init`

Inspects your Flutter project and generates `vyrax.yaml`.

What it detects:
- State management (`riverpod`, `bloc`, `provider`, etc.)
- Dependency injection (`get_it`, `injectable`, etc.)
- Networking (`dio`, `http`, etc.)
- Routing (`go_router`, `auto_route`, `navigator`)
- Serialization (`freezed`, `json_serializable`, etc.)
- Architecture (`clean`, `feature_first`, `mvvm`, `mvc`, `unknown`)
- Quality tools (`flutter_lints`, `custom_lint`, `build_runner`, `melos`, etc.)

Options:

```bash
vyrax init --project <path>
```

Behavior:
- If project is not Flutter, command exits with code `1`.
- If `vyrax.yaml` exists, asks for confirmation before overwrite.

### `vyrax analyze`

Runs Vyrax rules against the target project.

Options:

```bash
vyrax analyze --project <path> --format <text|json>
```

Examples:

```bash
vyrax analyze
vyrax analyze --format json
vyrax analyze --project ./examples/sample_app --format text
```

Exit codes:
- `0`: no issues
- `1`: warnings only
- `2`: at least one error or critical issue
- `3`: invalid input or project resolution failure

## Configuration

`vyrax init` generates a baseline `vyrax.yaml` that you can customize.

Minimal example:

```yaml
rules:
	future_inside_build:
		enabled: true
	network_inside_build:
		enabled: true

output:
	format: text
```

The analyzer supports rule aliases in configuration, including code IDs and readable names.

## Troubleshooting

### Command not found

If `vyrax` is not found after global activation, verify your Dart pub global binary path is exported in your shell profile.

### Not a Flutter project

Run commands from a Flutter app directory (must contain a valid `pubspec.yaml` with Flutter SDK dependency), or pass `--project <path>`.

## License

See [LICENSE](LICENSE).
