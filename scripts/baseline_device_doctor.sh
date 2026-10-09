#!/bin/sh
set -eu
# This harness has no account, backend, flavor, credentials or reset endpoint.
test -f integration_test/baseline_test.dart
test -f test_driver/baseline_driver.dart
flutter devices
printf '%s\n' 'Select a disposable Android emulator. BASELINE_PHASE=draft requires verified empty storage; complete/review preserve the preceding phase.'
