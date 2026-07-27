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

Verify the active version right after install/update:

```bash
vyrax --version
```

Do not add `vyrax_cli` under your app `dependencies` or `dev_dependencies` in `pubspec.yaml`.
Use it as a global CLI tool.

Global means machine-wide (single install), not one install per project.

### Update Policy (Recommended)

For end users, always update from pub.dev:

```bash
dart pub global activate vyrax_cli
vyrax --version
```

Do not use `--source path` unless you are developing the CLI itself.

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

Example:

```yaml
rules:
  future_inside_build:
    enabled: true
    severity: error
  widget_tree_complexity:
    enabled: false

output:
  format: text
```

Rule keys support aliases (for example `VYX001` or `future_inside_build`), but the recommended approach is to use canonical rule keys.

### Available Rules

Use these keys under `rules:` to enable/disable each check.

| Key | ID | What it checks | Why it exists |
| --- | --- | --- | --- |
| `future_inside_build` | `VYX001` | `FutureBuilder`/future usage patterns inside `build` | Avoid repeated async work and unnecessary rebuild cost |
| `network_inside_build` | `VYX002` | HTTP/network calls executed from `build` | Prevent duplicate requests and UI jank |
| `multiple_public_classes` | `VYX003` | More than one public class in a file | Improve file ownership and maintainability |
| `build_complexity` | `VYX004` | Large/complex widget `build` blocks | Keep UI code easier to reason about and test |
| `large_consumer_scope` | `VYX005` | High-level `Consumer`/`BlocBuilder` wrapping big UI sections | Reduce broad reactive rebuilds |
| `set_state_with_state_management` | `VYX006` | `setState` use when app-wide state management is configured | Keep state strategy consistent across the app |
| `unbounded_scrollable_in_column` | `VYX007` | Scrollables inside `Column` without proper constraints | Prevent overflow/layout exceptions |
| `clean_architecture_without_use_cases` | `VYX008` | Clean architecture selected but use-case layer not detected | Enforce expected domain boundaries |
| `presentation_depends_on_data_layer` | `VYX009` | Presentation/UI importing from data layer directly | Reduce layer coupling |
| `direct_external_package_in_presentation` | `VYX010` | UI imports external infra packages directly | Improve testability through abstractions |
| `singleton_overuse` | `VYX011` | Singleton-style implementations in app code | Limit global shared state risk |
| `missing_internationalization` | `VYX012` | No clear i18n setup detected | Encourage localization-ready projects |
| `broad_reactive_rebuild_scope` | `VYX013` | Reactive subscriptions inside very large build subtrees | Minimize unnecessary subtree rebuilds |
| `error_model_without_factory_mapper` | `VYX014` | Error/failure models with no mapper/factory constructor | Standardize error translation and testing |
| `hardcoded_ui_text` | `VYX015` | User-facing strings hardcoded in UI | Improve localization and copy management |
| `repeated_magic_numbers` | `VYX016` | Repeated numeric literals in the same file | Improve readability with named constants |
| `large_file` | `VYX017` | Files exceeding configured max lines | Keep modules focused and reviewable |
| `solid_single_responsibility` | `VYX018` | Classes that appear to mix too many responsibilities | Encourage SRP and separation of concerns |
| `solid_open_closed` | `VYX019` | Large branching structures that are hard to extend | Encourage OCP-friendly extension patterns |
| `solid_dependency_inversion` | `VYX020` | High-level modules instantiating concrete dependencies | Promote dependency inversion and mocking |
| `solid_opportunity` | `VYX021` | General SOLID opportunities at file level | Surface broad maintainability improvements |
| `widget_lifecycle` | `VYX022` | Risky lifecycle patterns in Flutter `State` classes | Prevent leaks and timing-related bugs |
| `widget_tree_complexity` | `VYX023` | Deep or wrapper-heavy widget trees | Improve UI readability and rendering stability |

### Enable Or Disable Rules

```yaml
rules:
  future_inside_build:
    enabled: true

  network_inside_build:
    enabled: false

  large_file:
    enabled: true
    severity: warning
```

Notes:
- `enabled: false` disables that rule.
- `severity` is optional and supports: `info`, `warning`, `error`, `critical`.
- If a rule is omitted, it stays enabled by default.

## Troubleshooting

### Command not found

If `vyrax` is not found after global activation, verify your Dart pub global binary path is exported in your shell profile.

### CLI Version Mismatch (missing rules or old behavior)

Symptoms:
- `vyrax init` does not include recently added rules.
- `vyrax --help` does not show newer commands/options.

Recovery steps:

```bash
dart pub global deactivate vyrax_cli
dart pub global activate vyrax_cli
vyrax --version
```

Expected after recovery:
- `vyrax --version` prints the latest published version.
- `vyrax init` prints `Default rules enabled: 23`.

If your environment still behaves like an old version after re-activate, clear stale snapshots once and retry:

```bash
rm -f ~/.pub-cache/bin/vyrax
dart pub global activate vyrax_cli
vyrax --version
```

### Not a Flutter project

Run commands from a Flutter app directory (must contain a valid `pubspec.yaml` with Flutter SDK dependency), or pass `--project <path>`.

## License

See [LICENSE](LICENSE).
