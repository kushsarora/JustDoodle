#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
destination="${1:-platform=iOS Simulator,name=iPhone 17 Pro}"
results="${RESULTS_DIR:-$(mktemp -d /private/tmp/JustDoodleChecks.XXXXXX)}"
mkdir -p "$results"

plutil -lint JustDoodle/Info.plist JustDoodle/PrivacyInfo.xcprivacy JustDoodle.xcodeproj/project.pbxproj
ruby -rjson -e 'Dir["JustDoodle/Assets.xcassets/**/Contents.json"].each { |path| JSON.parse(File.read(path)) }'
git diff --check
xcodebuild -project JustDoodle.xcodeproj -scheme JustDoodle \
  -destination "$destination" -derivedDataPath "$results/DerivedData" \
  -resultBundlePath "$results/Tests.xcresult" \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
xcodebuild -project JustDoodle.xcodeproj -scheme JustDoodle \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$results/JustDoodle.xcarchive" \
  -derivedDataPath "$results/DerivedData" CODE_SIGNING_ALLOWED=NO archive
bash scripts/validate-archive.sh "$results/JustDoodle.xcarchive"
printf 'Test results and unsigned archive: %s\n' "$results"
