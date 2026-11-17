#!/bin/bash
set -e
cd "$(dirname "$0")"
APP="build/ClipDeck.app"
rm -rf build && mkdir -p "$APP/Contents/MacOS"

swiftc -O \
  -framework Cocoa -framework Carbon -framework ServiceManagement \
  -o "$APP/Contents/MacOS/ClipDeck" \
  Sources/main.swift

cp Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
echo "✅ 빌드 완료: $APP"
