## 0.2.1

- Fix quality score reporting to avoid integer-rounding loss; text and JSON now keep one decimal place.
- Bump CLI version output to `0.2.1`.

## 0.2.0

- Add contextual analysis scopes: `--changed`, `--staged`, `--against <branch>`, directory path, and file path.
- Improve text output by grouping findings by severity section.
- Keep report generation defaults with configurable opt-out and path controls.

## 0.1.8

- Add automatic `.txt` analyze report generation with opt-out controls (`--no-report`, `output.report.enabled`).
- Add configurable report output path with `--report-path` or `output.report.path`.

## 0.1.7

- Align package release version with the 0.1.7 workspace release.

## 0.1.6

- Align package release version with the 0.1.6 workspace release.

## 0.1.5

- Align package release version with the 0.1.5 workspace release.

## 0.1.4

- Align package release version with the 0.1.4 workspace release.

## 0.1.3

- Align package release version with the 0.1.3 workspace release.

## 0.1.2

- Implement smart `vyrax init` project inspection and stack detection.
- Add interactive confirmation flow for config generation and overwrite safety.
- Add integration-style CLI tests for init confirmations, overwrite behavior, and non-Flutter exit handling.

## 0.1.1

- Add `vyrax init` and improve `vyrax analyze` workflow.
- Prepare automated release tags from `main` and pub.dev publication flow.

## 0.1.0

- Initial pre-alpha release of `vyrax_cli`.
