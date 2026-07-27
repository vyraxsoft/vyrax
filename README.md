# 🛡️ Vyrax

> **Flutter Architecture & Performance Analyzer**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Status](https://img.shields.io/badge/status-Pre--Alpha-orange)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)

---

# Vision

Vyrax is an open-source Flutter Architecture & Performance Analyzer.

Unlike traditional linters, Vyrax understands Flutter applications and provides actionable insights about:

- Widget rebuilds
- Performance bottlenecks
- State management misuse
- Flutter architecture
- Domain modeling
- Technical debt
- Project health

The goal is simple:

> Help Flutter teams detect architecture and performance problems before they reach production.

---

# Why Vyrax?

Current tools already solve problems like:

- formatting
- naming conventions
- import ordering
- cyclomatic complexity
- style consistency

Vyrax focuses on problems that are **specific to Flutter**.

Examples:

- Future recreated inside build()
- Consumer rebuilding an entire widget tree
- BlocBuilder wrapping a Scaffold
- Unnecessary widget rebuilds
- Large Flutter widgets
- Large domain models
- Violations of the project's architecture

---

# Philosophy

Every feature must follow these principles.

## Flutter First

If a rule is equally applicable to Java, Kotlin, Swift or JavaScript,
it probably does not belong inside Vyrax.

Vyrax exists to understand Flutter.

---

## Explain Before Warning

A diagnostic is incomplete if it only reports a problem.

Every issue should explain:

- What happened?
- Why it happened?
- Why it matters?
- How to fix it?
- Can it be fixed automatically?

Vyrax should educate developers.

---

## Low False Positives

A warning that developers ignore is a failed warning.

Vyrax should prioritize accuracy over quantity.

---

# Product Goals

The project aims to become the quality platform for Flutter applications.

Future capabilities include:

- Flutter-specific static analysis
- Widget Tree Analysis
- Architecture validation
- Domain analysis
- Project health scoring
- Quick Fixes
- CLI
- VS Code Extension
- CI integration
- AI explanations

---

# Repository Structure

```
vyrax/

packages/

		vyrax_core/

		vyrax_engine/

		vyrax_rules/

		vyrax_cli/

		vyrax_annotations/

examples/

		sample_app/

docs/

scripts/
```

---

# Packages

## vyrax_core

Shared models and abstractions.

Responsibilities:

- Rule interfaces
- Issue model
- Severity
- Categories
- Configuration
- Plugin contracts

This package must remain framework agnostic.

---

## vyrax_engine

Core analysis engine.

Responsibilities:

- Rule execution
- Analyzer integration
- AST traversal
- Rule registry
- Issue generation

No Flutter-specific rules should live here.

---

## vyrax_rules

Flutter-specific rules.

Examples:

- FutureInsideBuildRule
- ConsumerScopeRule
- BlocBuilderScopeRule
- LargeModelRule
- BuildComplexityRule

Rules must be isolated from each other.

---

## vyrax_cli

Command line interface.

Future commands:

```bash
vyrax init

vyrax analyze

vyrax doctor

vyrax score

vyrax explain

vyrax fix
```

---

## vyrax_annotations

Annotations used inside Flutter projects.

Example:

```dart
@VyraxIgnore()
```

---

# Widget Tree Analysis

This is the main differentiator of Vyrax.

Instead of counting lines of code,
Vyrax will understand the Flutter widget tree.

Example:

```
Consumer

↓

Scaffold

↓

Column

↓

Expanded

↓

ListView

↓

Cards
```

The analyzer should detect that Consumer rebuilds the entire subtree.

---

# Architecture Analysis

Vyrax should adapt to the project's architecture.

Supported architectures:

- Clean Architecture
- MVVM
- MVC
- Feature First
- Hybrid

Architecture-specific rules should only execute when applicable.

---

# Project Configuration

Projects describe themselves using `vyrax.yaml`.

Example:

```yaml
project:
	name: Example

flutter:
	architecture:
		layers: clean
		organization: feature_first
		presentation: mvvm

state_management:
	type: riverpod

network:
	client: dio

routing:
	type: go_router

dependency_injection:
	type: get_it

serialization:
	models: freezed
	json: json_serializable
```

Vyrax should adapt its analysis using this configuration.

---

# Auto Detection

Future command:

```bash
vyrax init
```

Should automatically detect:

- Flutter version
- State management
- Routing
- Networking
- Dependency Injection
- Serialization
- Project architecture

Then generate `vyrax.yaml`.

---

# Rule Categories

- Performance
- Architecture
- Widgets
- State Management
- Domain
- Networking
- Memory
- Testing
- Security
- Project Health

---

# Severity

- Info
- Warning
- Error
- Critical

---

# MVP

The first release should implement:

## Engine

- Rule Engine
- Issue model
- Rule registry

## CLI

- init
- analyze

## Rules

- Future inside build
- HTTP inside build
- Consumer scope
- Large model
- Build complexity

Nothing more.

---

# Long-Term Vision

Vyrax should become for Flutter what:

- ESLint is for JavaScript
- Detekt is for Kotlin
- SwiftLint is for Swift

But with Flutter-specific intelligence.

---

# Contributing

We value:

- Simplicity
- Readability
- Performance
- Extensibility
- Developer Experience

Every contribution should preserve the architecture.

---

# Development Principles

- Prefer composition over inheritance
- Keep packages independent
- Avoid global mutable state
- Keep APIs stable
- Every public API must be documented
- Every rule must have tests
- Every package must compile independently

---

# AI Development

AI is used as an engineering assistant.

AI should:

- preserve architecture
- avoid overengineering
- keep APIs clean
- prioritize maintainability
- propose improvements when appropriate

AI should not introduce breaking architectural changes without justification.

---

# License

MIT License.

Built with ❤️ by the team at **Vyrax**.
