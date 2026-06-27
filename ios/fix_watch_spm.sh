#!/bin/bash
# Re-applies Watch/iOS SPM compatibility patches after flutter pub get.
# Run: cd ios && ./fix_watch_spm.sh

set -e

EPHEMERAL="Flutter/ephemeral/Packages"
FLUTTER_FW="$EPHEMERAL/.packages/FlutterFramework/Package.swift"
PLUGIN_PKG="$EPHEMERAL/FlutterGeneratedPluginSwiftPackage/Package.swift"

# 1. FlutterFramework: add iOS-only platform declaration so SPM skips watchOS.
if ! grep -q 'platforms:' "$FLUTTER_FW"; then
  sed -i '' 's/    name: "FlutterFramework",/    name: "FlutterFramework",\n    platforms: [\n        .iOS("13.0")\n    ],/' "$FLUTTER_FW"
  echo "Patched $FLUTTER_FW"
else
  echo "FlutterFramework already patched."
fi

# 2. FlutterGeneratedPluginSwiftPackage: add .when(platforms:[.iOS]) conditions.
if ! grep -q 'condition: .when' "$PLUGIN_PKG"; then
  sed -i '' \
    's/\.product(name: "\([^"]*\)", package: "\([^"]*\)")$/\.product(name: "\1", package: "\2", condition: .when(platforms: [.iOS]))/g' \
    "$PLUGIN_PKG"
  echo "Patched $PLUGIN_PKG"
else
  echo "FlutterGeneratedPluginSwiftPackage already patched."
fi

echo "Done. Clean Xcode derived data and rebuild."
