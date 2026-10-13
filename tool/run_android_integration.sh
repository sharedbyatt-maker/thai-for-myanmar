#!/usr/bin/env bash
# Keep device logs before android-emulator-runner shuts its emulator down.
set -uo pipefail
mkdir -p ci-diagnostics
# Use Skia with the emulated GPU; production keeps Flutter's default renderer.
flutter test --no-pub --no-enable-impeller -d emulator-5554 integration_test/app_flow_test.dart --reporter expanded
test_status=$?
if [ "$test_status" -ne 0 ]; then
  timeout 20s adb -s emulator-5554 logcat -d -t 3000 > ci-diagnostics/android-logcat.txt 2>&1 || true
  timeout 15s adb -s emulator-5554 shell dumpsys activity exit-info > ci-diagnostics/app-exit-info.txt 2>&1 || true
  free -h > ci-diagnostics/live-host-memory.txt 2>&1 || true
  ps -eo pid,comm,%cpu,%mem,rss --sort=-rss | head -20 > ci-diagnostics/live-host-processes.txt 2>&1 || true
fi
exit "$test_status"
