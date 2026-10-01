#!/bin/bash
set -euo pipefail
mkdir -p build
swiftc -swift-version 6 -parse-as-library -target "$(uname -m)-apple-macos27.0" Sources/Core/LibraryStore.swift Sources/App/LibraryModel.swift Scripts/ModelSmokeTest.swift -o build/ModelSmokeTest
build/ModelSmokeTest
