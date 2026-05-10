#!/usr/bin/env bash
# Run once: generates android/, ios/, macos/, web/ so physical devices and emulators work.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Generating platform folders..."
flutter create . --platforms=android,ios,macos,web
echo "Done. Next: connect your phone (USB debugging on), then: flutter devices && flutter run -d <device_id>"
