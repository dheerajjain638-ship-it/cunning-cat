#!/usr/bin/env bash
# Creates android/ and ios/ with `flutter create` when they are not committed yet,
# then applies Cunning Cat's app name. Safe to run repeatedly.
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
