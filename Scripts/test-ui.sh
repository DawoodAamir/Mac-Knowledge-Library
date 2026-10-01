#!/bin/bash
set -euo pipefail
mkdir -p build
result="build/Workflow-$(date +%s).xcresult"
xcodebuild -project 'Mac Knowledge Library.xcodeproj' -scheme 'Mac Knowledge Library' -destination 'platform=macOS' -derivedDataPath build/DerivedData test -collect-test-diagnostics never -resultBundlePath "$result"
xcrun xcresulttool export attachments --path "$result" --output-path build/Screenshots
