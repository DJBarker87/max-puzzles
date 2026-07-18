#!/bin/sh

set -eu

if [ "${CONFIGURATION:-}" != "Release" ]; then
    exit 0
fi

fail() {
    echo "error: $1" >&2
    exit 1
}

if [ "${ENABLE_CODE_COVERAGE:-}" != "NO" ]; then
    fail "Release builds must set ENABLE_CODE_COVERAGE=NO."
fi

if [ "${CLANG_COVERAGE_MAPPING:-}" != "NO" ]; then
    fail "Release builds must set CLANG_COVERAGE_MAPPING=NO."
fi

resource_root="${SRCROOT}/MaxPuzzles/Resources"
splash_set="${resource_root}/Assets.xcassets/splash_background.imageset"

if [ -e "${resource_root}/Sounds/lose_music.wav" ]; then
    fail "Unused lose_music.wav must not be shipped."
fi

if [ -d "${resource_root}/Assets.xcassets/HubBackground.imageset" ]; then
    fail "Unused HubBackground.imageset must not be shipped."
fi

if [ ! -s "${splash_set}/splash_background.jpg" ]; then
    fail "The splash JPEG is missing."
fi

if [ -e "${splash_set}/splash_background.png" ]; then
    fail "The splash JPEG must not use a .png filename."
fi

if ! /usr/bin/file "${splash_set}/splash_background.jpg" | /usr/bin/grep -q "JPEG image data"; then
    fail "splash_background.jpg is not JPEG data."
fi
