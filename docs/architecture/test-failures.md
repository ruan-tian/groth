# Test Failures Analysis

## Summary

- Total tests: 345
- Passed: 315
- Skipped: 2
- Failed: 28

## Failure Categories

### Category 1: ProviderContainer Already Disposed (20 tests)

**Root Cause**: `MusicPlayerController.dispose()` and `WaterPlanController._settingsWriter()` try to access providers after the test's `ProviderContainer` is disposed.

**Status**: Pre-existing, not caused by architecture upgrade.

**Fix**: Update test teardown order to dispose services before container.

### Category 2: Opacity Assertion Error (5 tests)

**Root Cause**: `launch_intro_overlay.dart` animation opacity value exceeds 0.0-1.0 range during test.

**Status**: Pre-existing, not caused by architecture upgrade.

**Fix**: Clamp opacity values in animation controller.

### Category 3: NotificationService LateInitializationError (3 tests)

**Root Cause**: `NotificationService` not properly initialized in test environment.

**Status**: Pre-existing, not caused by architecture upgrade.

**Fix**: Mock NotificationService in test setup.

## Action Plan

1. **Short-term**: Document failures, ensure architecture changes don't add new failures
2. **Medium-term**: Fix Category 1 (ProviderContainer disposal) - highest impact
3. **Long-term**: Fix Category 2 and 3

## Verification

After each architecture change, verify:
- No new test failures introduced
- Existing failure count remains at 28
