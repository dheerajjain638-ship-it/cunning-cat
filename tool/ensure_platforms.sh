#!/usr/bin/env bash
# Prepares the Android/iOS projects: creates android/ and ios/ with
# `flutter create` when they are not committed yet, applies the app name,
# and generates the app icon and splash screen from the brand images.
# Run after `python3 tool/make_icon.py` and `flutter pub get`. Safe to re-run.
set -euo pipefail

if [ ! -d android ] || [ ! -d ios ]; then
  flutter create --platforms=android,ios --org com.cunningcat --project-name cunning_cat .
  # flutter create adds a counter-app test that doesn't match our app.
  rm -f test/widget_test.dart
fi

# Display name on the phone's home screen.
if [ -f android/app/src/main/AndroidManifest.xml ]; then
  sed -i.bak 's/android:label="[^"]*"/android:label="Cunning Cat"/' android/app/src/main/AndroidManifest.xml
  rm -f android/app/src/main/AndroidManifest.xml.bak
fi
if [ -f ios/Runner/Info.plist ]; then
  /usr/bin/perl -0pi -e 's/(<key>CFBundleDisplayName<\/key>\s*<string>)[^<]*(<\/string>)/${1}Cunning Cat${2}/' ios/Runner/Info.plist
fi

# Release builds need the INTERNET permission for live prices and photos.
MANIFEST=android/app/src/main/AndroidManifest.xml
if [ -f "$MANIFEST" ] && ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  perl -0pi -e 's/(<manifest[^>]*>)/$1\n    <uses-permission android:name="android.permission.INTERNET"\/>/' "$MANIFEST"
fi
grep -q 'android.permission.INTERNET' "$MANIFEST"

# App icon + native splash from assets/brand/*.png
dart run flutter_launcher_icons
dart run flutter_native_splash:create
