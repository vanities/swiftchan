#!/bin/bash
set -euo pipefail

# XCTest's timeout often omits the app's blocked stack. Capture it while the app is alive.
bundle exec fastlane tests &
test_pid=$!
(
  while kill -0 "$test_pid" 2>/dev/null; do
    sleep 60
    for app_pid in $(pgrep -x swiftchan || true); do
      output_dir="fastlane/test_output/main-thread-samples"
      mkdir -p "$output_dir"
      sample "$app_pid" 1 -file "$output_dir/$app_pid-$(date +%s).txt" >/dev/null 2>&1 || true
    done
  done
) &
monitor_pid=$!
trap 'kill "$monitor_pid" 2>/dev/null || true' EXIT
wait "$test_pid"
