# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

React Native native module providing access to store-level age signals for compliance with state-level age verification laws (Texas SB2420, Utah, Louisiana). Supports both iOS (Apple Declared Age Range API) and Android (Google Play Age Signals API).

## Development Commands

```sh
# Install dependencies (uses Yarn workspaces, npm not supported)
yarn

# Type checking
yarn typecheck

# Linting
yarn lint
yarn lint --fix  # Auto-fix formatting issues

# Run tests
yarn test

# Build library
yarn prepare  # Uses react-native-builder-bob

# Run example app
yarn example start       # Start Metro bundler
yarn example ios         # Run on iOS
yarn example android     # Run on Android

# Release (publishes to npm)
yarn release
```

## Architecture

**Legacy Native Module Architecture** - Uses traditional React Native bridge (not Turbo Modules).

### TypeScript Layer (`src/index.tsx`)
- Exports two main functions: `getAndroidPlayAgeRangeStatus()` and `requestIOSDeclaredAgeRange()`
- Platform-guards each function, returning null results for wrong platform
- TypeScript interfaces: `PlayAgeRangeStatusResult`, `DeclaredAgeRangeResult`, `AndroidAgeRangeConfig`

### iOS Native (`ios/StoreAgeSignalsNativeModules.swift`)
- Uses `DeclaredAgeRange` framework (iOS 26.0+)
- `AgeRangeService.shared.requestAgeRange()` requires a view controller context
- Compile-time guards with `#if compiler(>=6.0) && canImport(DeclaredAgeRange)`
- Returns status: 'sharing' | 'declined' | null with optional age bounds

### Android Native (`android/.../StoreAgeSignalsNativeModulesModule.kt`)
- Uses Google Play `AgeSignalsApi` via `AgeSignalsManagerFactory.create()`
- Maps `AgeSignalsVerificationStatus` to: VERIFIED→OVER_AGE, SUPERVISED→UNDER_AGE, UNKNOWN
- Built-in mock mode using `FakeAgeSignalsManager` for testing

### Mock Mode
Both platforms support mock mode for development/testing without production builds. Android mock is configured via `AndroidAgeRangeConfig.isMock` with mock status/error options.

## Commit Conventions

Uses [Conventional Commits](https://www.conventionalcommits.org/): `fix:`, `feat:`, `refactor:`, `docs:`, `test:`, `chore:`

Pre-commit hooks verify commit message format.

## Platform Constraints

- **iOS**: Requires iOS 26.0+, paid Apple Developer account, "Declared Age Range" capability in Xcode entitlements. Age thresholds must create 2+ year ranges.
- **Android**: Requires Google Play Services. No manual setup needed.
