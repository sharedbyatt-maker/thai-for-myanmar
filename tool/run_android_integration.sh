#!/usr/bin/env bash
# Keep device logs before android-emulator-runner shuts its emulator down.
set -uo pipefail
mkdir -p ci-diagnostics
flutter test --no-pub -d emulator-5554 integration_test/app_flow_test.dart --reporter expanded
test_status=$?
if [ "$test_status" -ne 0 ]; then
  timeout 20s adb -s emulator-5554 logcat -d -t 3000 > ci-diagnostics/android-logcat.txt 2>&1 || true
  timeout 15s adb -s emulator-5554 shell dumpsys activity exit-info > ci-diagnostics/app-exit-info.txt 2>&1 || true
fi
exit "$test_status"
