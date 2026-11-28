#!/usr/bin/env bash
set -euo pipefail

package=com.sharedbyatt.thaiformyanmar
recording=/sdcard/chang-thai-startup.mp4

adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat -b all -c
mkdir -p build/review-artifacts
adb shell input keyevent KEYCODE_HOME
adb shell am force-stop "$package"
adb shell screenrecord --time-limit 15 "$recording" &
recording_pid=$!
sleep 1
adb shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n "$package/.StartupActivity"
wait "$recording_pid"
adb pull "$recording" build/review-artifacts/chang-thai-startup.mp4
sleep 5
adb logcat -b crash -d
adb logcat -b main -d -s AndroidRuntime:E flutter:E
adb shell dumpsys activity exit-info "$package"
adb shell pidof "$package"
