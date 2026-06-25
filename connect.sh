#!/bin/bash

# First setup, just run once:
flutter create --platforms web .
flutter pub get

# Android -> Terminal 1: 
adb disconnect
adb connect host.docker.internal:5555
adb devices
flutter run --target lib/main.dart

# Admin web -> Terminal 2:
# METHOD A – Dev mode (hot reload enabled, but uses ~2GB of RAM):
flutter run -d web-server --web-port 8100 --web-hostname 0.0.0.0 --target lib/main_web.dart

# METHOD B – Production mode (lightweight, single build):
flutter build web --release --target lib/main_web.dart
python3 -m http.server 8100 --directory build/web --bind 0.0.0.0

# (Rebuild the Flutter web app if there are changes to the admin code)
# Open your browser and go to: http://localhost:8100

# Run for Android
adb disconnect
adb connect host.docker.internal:5555
adb devices
