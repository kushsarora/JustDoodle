#!/bin/bash
set -euo pipefail

archive="${1:?Usage: bash scripts/validate-archive.sh path/to/JustDoodle.xcarchive [--submission]}"
app="$archive/Products/Applications/JustDoodle.app"
test -d "$app"
plutil -lint "$app/Info.plist" "$app/PrivacyInfo.xcprivacy"
test -f "$app/Assets.car"
test -f "$app/JustDoodle"
sdk="$(plutil -extract DTSDKName raw -o - "$app/Info.plist")"
if [[ "$sdk" != iphoneos* || "${sdk#iphoneos}" == "$sdk" ]]; then
  printf 'Release archive must be built for a physical iOS device.\n' >&2
  exit 1
fi
sdk_version="${sdk#iphoneos}"
if (( ${sdk_version%%.*} < 26 )); then
  printf 'App Store uploads require the iOS 26 SDK or newer.\n' >&2
  exit 1
fi
lipo "$app/JustDoodle" -verify_arch arm64
plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist"
printf '\n'
plutil -extract CFBundleShortVersionString raw -o - "$app/Info.plist"
printf '\n'

if [[ "${2:-}" == "--submission" ]]; then
  privacy_url="$(plutil -extract JustDoodlePrivacyURL raw -o - "$app/Info.plist")"
  if [[ "$privacy_url" != https://* ]]; then
    printf 'Submission blocked: set JUST_DOODLE_PRIVACY_URL to the published HTTPS privacy page.\n' >&2
    exit 1
  fi
  curl --fail --location --proto '=https' --proto-redir '=https' --max-time 20 --output /dev/null "$privacy_url"
  codesign --verify --deep --strict "$app"
  test -f "$app/embedded.mobileprovision"
fi
