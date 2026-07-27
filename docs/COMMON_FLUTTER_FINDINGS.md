# Common Flutter Findings

> A collection of common issues found during Flutter code reviews.

This document serves as the foundation for Vyrax rules.

Every rule implemented by Vyrax should solve a real problem that commonly appears during Pull Request reviews.

---

# Performance

## Future created inside build()

Severity

Error

Problem

Creating a Future directly inside build() causes the Future to be recreated every time the widget rebuilds.

Recommendation

Move the Future outside build().

Status

Implemented

Rule

VYX001

---

## Network request inside build()

Severity

Error

Problem

Network requests should never be executed inside build().

Recommendation

Move network logic to ViewModel, Bloc, Cubit, Provider or Repository.

Rule

VYX002

---

## Heavy computation inside build()

Severity

Warning

Problem

Expensive computations executed during build() hurt rendering performance.

Examples

- sorting
- filtering
- grouping
- parsing
- JSON conversion

Recommendation

Compute once and cache.

Status

Planned

---

## setState() called multiple times

Severity

Warning

Problem

Calling setState repeatedly instead of batching updates causes unnecessary rebuilds.

Status

Planned

---

## Entire screen rebuilt by Consumer

Severity

Warning

Problem

Consumer wraps Scaffold or another top-level widget.

Example

Consumer

↓

Scaffold

↓

Entire page rebuilds

Recommendation

Move Consumer closer to the widget that actually depends on the state.

Rule

VYX005

---

## BlocBuilder wrapping entire screen

Severity

Warning

Same recommendation.

Status

Planned

---

## Nested ListViews

Severity

Warning

Problem

Nested scrollables often cause performance issues and layout exceptions.

Rule

VYX007

---

## Missing const constructors

Severity

Info

Problem

Widgets that could be const aren't.

Recommendation

Mark immutable widgets as const.

Status

Planned

---

# Architecture

## Business logic inside Widget

Severity

Warning

Problem

Widgets should describe UI.

Business rules belong elsewhere.

Examples

- calculations
- validation
- repository access

Status

Planned

---

## Repository used directly from UI

Severity

Warning

Example

```dart
repository.save();
```

Recommendation

Go through ViewModel / Bloc / Controller.

Rule

VYX009

---

## Domain depending on Flutter

Severity

Error

Problem

Domain layer imports Flutter.

Example

```dart
import 'package:flutter/material.dart';
```

Status

Planned

---

## Circular dependencies

Severity

Critical

Problem

Modules depending on each other.

Status

Planned

---

## Feature crossing boundaries

Severity

Warning

Problem

Feature A importing Feature B internals.

Status

Planned

---

# State Management

## Provider scope too large

Severity

Warning

Rule

VYX013

---

## Nested Consumers

Severity

Warning

Status

Planned

---

## Multiple Providers that can be merged

Severity

Info

Status

Planned

---

## Unused Provider

Severity

Info

Status

Planned

---

## Bloc event dispatched inside build()

Severity

Error

Status

Planned

---

## BlocBuilder inside ListView.builder()

Severity

Warning

Status

Planned

---

## setState used with state management

Severity

Warning

Rule

VYX006

---

# Widgets

## Widget too large

Severity

Warning

Metrics

- Lines
- Children
- Nesting

Status

Planned

---

## build() too complex

Severity

Warning

Metrics

- Widget depth
- Builders
- Conditions

Rule

VYX004

---

## Widget with too many responsibilities

Severity

Warning

Status

Planned

---

## Deep widget nesting

Severity

Info

Status

Planned

---

## Too many anonymous callbacks

Severity

Info

Status

Planned

---

## Large build method

Severity

Warning

Status

Planned

---

## Scrollable inside Column without bounds

Severity

Warning

Problem

Scrollable content inside Column without Expanded/Flexible can overflow or become invisible on smaller screens.

Rule

VYX007

---

# Domain

## Multiple public classes per file

Severity

Warning

Rule

VYX003

---

## Entity with too many fields

Severity

Warning

Status

Planned

---

## Data class mixed with business logic

Severity

Warning

Status

Planned

---

## Mutable domain model

Severity

Warning

Status

Planned

---

## God Model

Severity

Warning

Symptoms

- hundreds of lines
- many unrelated responsibilities
- dozens of properties

Status

Planned

---

## Clean architecture without use cases

Severity

Warning

Rule

VYX008

---

## Presentation depends on data layer

Severity

Warning

Rule

VYX009

---

# Networking

## Dio created multiple times

Severity

Warning

Status

Planned

---

## Hardcoded URLs

Severity

Warning

Status

Planned

---

## HTTP logic inside UI

Severity

Error

Status

Planned

---

## Missing timeout

Severity

Info

Status

Planned

---

## Missing interceptors

Severity

Info

Status

Planned

---

# Testing

## Widget without tests

Severity

Info

Status

Planned

---

## ViewModel without tests

Severity

Info

Status

Planned

---

## Repository without tests

Severity

Info

Status

Planned

---

## Golden tests missing

Severity

Info

Status

Planned

---

## Error model without factory mapper

Severity

Warning

Rule

VYX014

---

# Project Structure

## Feature too large

Severity

Warning

Status

Planned

---

## File too large

Severity

Warning

Problem

Files that exceed the team's configured line limit are harder to review, test, and refactor.

Recommendation

Split the file into smaller modules or, for UI files, extract independent widgets.

Rule

VYX017

Config

`limits.max_lines_per_file`

---

## Folder with too many files

Severity

Info

Status

Planned

---

## Unused assets

Severity

Info

Status

Planned

---

## Unused dependencies

Severity

Warning

Status

Planned

---

## Duplicate dependencies

Severity

Warning

Status

Planned

---

# Documentation

## Public API undocumented

Severity

Info

Status

Planned

---

## Missing README

Severity

Info

Status

Planned

---

## Hardcoded user-facing text

Severity

Info

Rule

VYX015

---

## Widget lifecycle misuse

Severity

Warning

Problem

A State object starts async work in `initState()` or keeps disposable controllers/subscriptions without cleanup.

Recommendation

Keep `initState()` synchronous, move async work to a dedicated method or post-frame callback, and dispose owned resources.

Rule

VYX022

Status

Implemented

Why it helps

This prevents leaks, avoids brittle lifecycle timing, and makes widget tests more predictable.

---

## Widget tree complexity

Severity

Warning

Problem

The build tree becomes too deep or wrapper-heavy to reason about comfortably.

Recommendation

Extract leaf widgets, flatten wrapper chains, and split repeated subtrees into focused widgets.

Rule

VYX023

Status

Implemented

Why it helps

Smaller widget trees are easier to read, diff, and optimize, which is closer to how a compiler reasons about structure.

---

# Future Ideas

Potential future rules:

- Riverpod anti-patterns
- Bloc anti-patterns
- GetIt anti-patterns
- Freezed best practices
- GoRouter validation
- Clean Architecture validation
- MVVM validation
- MVC validation
- Feature First validation
- Memory leaks beyond simple cleanup heuristics
- AST-level widget topology analysis
- Repeated magic numbers / constants extraction
