# Publishing Vyrax Packages

This workspace is configured as a monorepo, but packages are now publish-ready for pub.dev.

## Publish Order

Publish in this order to satisfy dependencies:

1. `vyrax_core`
2. `vyrax_engine`
3. `vyrax_rules`
4. `vyrax_cli`

## One-Time Setup

1. Verify your pub.dev account has publish permissions.
2. For each package, enable automated publishing from GitHub Actions in the package Admin tab on pub.dev:
	 - Repository: `vyraxsoft/vyrax`
	 - Tag patterns:
		 - `vyrax_core-v{{version}}`
		 - `vyrax_engine-v{{version}}`
		 - `vyrax_rules-v{{version}}`
		 - `vyrax_cli-v{{version}}`

Note: You must publish the first version manually before automated publishing can be enabled.

## Pre-Publish Checks

From repo root:

```bash
dart run melos bootstrap
dart run melos run analyze
dart run melos run test
```

For each package, run dry-run before publishing:

```bash
cd packages/<package_name>
dart pub publish --dry-run
```

## Manual First Release (Required Once)

Run these in sequence for first publication:

```bash
cd packages/vyrax_core && dart pub publish --force
cd ../vyrax_engine && dart pub publish --force
cd ../vyrax_rules && dart pub publish --force
cd ../vyrax_cli && dart pub publish --force
```

## GitHub Actions Publish Flow

Workflow file:

`/.github/workflows/publish_pubdev.yaml`

Tag creation workflow:

`/.github/workflows/tag_from_pubspec.yaml`

Behavior:

- On tag push, the workflow publishes exactly one package based on tag prefix.
- On manual run (`workflow_dispatch`), the workflow runs `dart pub publish --dry-run` for selected package.
- Manual publish from `workflow_dispatch` is blocked on purpose because pub.dev trusted publishing only allows tag refs (`refType=tag`).
- On push/merge to `main`, tags are auto-created from each package `pubspec.yaml` version if they do not already exist.

Required GitHub secret for auto-tag workflow:

- `GH_RELEASE_TOKEN`: Personal Access Token with repository write access.

Why this secret is needed:

- Tags pushed using the default `GITHUB_TOKEN` do not trigger downstream workflows reliably for release chaining.
- Using `GH_RELEASE_TOKEN` ensures pushed tags trigger the publish workflow.

Tag examples:

```bash
git tag vyrax_core-v0.1.3
git push origin vyrax_core-v0.1.3

git tag vyrax_engine-v0.1.3
git push origin vyrax_engine-v0.1.3
```

## Verify CLI Install (Public Flow)

After `vyrax_cli` is published:

```bash
dart pub global activate vyrax_cli
vyrax --help
```

Inside any Flutter project:

```bash
vyrax init
vyrax analyze
```

## Local Development Note

Local development still works through `pubspec_overrides.yaml` path overrides generated/managed in the workspace, so publish-ready version constraints do not block local iteration.