# Architecture

## Purpose

This document defines the long-term architecture for Vyrax as a scalable developer toolchain.

## Current Scope

- Monorepo boundaries and package responsibilities
- Shared abstractions and extension seams
- Delivery surfaces (CLI now, editor integration later)

## High-Level Direction

- `vyrax_core` remains framework-agnostic.
- `vyrax_engine` owns analysis orchestration and execution flow.
- `vyrax_rules` hosts rule implementations grouped by concern.
- `vyrax_cli` exposes user-facing commands and reporting output.
- `vyrax_annotations` provides optional metadata support.

## Placeholder Sections

- Execution pipeline design
- Rule lifecycle and metadata contract
- Plugin loading protocol
- Quick-fix strategy
- Performance and caching model
