#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
TOOL_SOURCE_DIR="${MEDIA_TOOL_SOURCE_DIR:-/private/tmp/media-downloader-universal-inspect}"
BUILD_DIR='/private/tmp/media-downloader-universal-build'
APP_DIR="$PROJECT_DIR/dist/Программа скачивания.app"
CONTENTS="$APP_DIR/Contents"
HELPERS="$CONTENTS/Helpers"

for tool in "$TOOL_SOURCE_DIR/yt-dlp_macos" \
            "$TOOL_SOURCE_DIR/riedl-x64/ffmpeg" "$TOOL_SOURCE_DIR/riedl-arm64/ffmpeg" \
            "$TOOL_SOURCE_DIR/riedl-x64/ffprobe" "$TOOL_SOURCE_DIR/riedl-arm64/ffprobe" \
            "$TOOL_SOURCE_DIR/deno-x64/deno" "$TOOL_SOURCE_DIR/deno-arm64/deno"; do
    [[ -f "$tool" ]] || { echo "Не найден инструмент: $tool" >&2; exit 1; }
done

mkdir -p "$BUILD_DIR/x64-cache" "$BUILD_DIR/arm64-cache" \
         "$CONTENTS/MacOS" "$CONTENTS/Resources/Fonts" "$HELPERS"

SOURCES=(
    "$PROJECT_DIR/Sources/MediaModels.swift"
    "$PROJECT_DIR/Sources/MediaAnalyzer.swift"
    "$PROJECT_DIR/Sources/DownloadManager.swift"
    "$PROJECT_DIR/Sources/ReferenceLayout.swift"
    "$PROJECT_DIR/Sources/App.swift"
)

xcrun swiftc -parse-as-library -target x86_64-apple-macos13.0 \
    -module-cache-path "$BUILD_DIR/x64-cache" -O -framework AppKit \
    "${SOURCES[@]}" -o "$BUILD_DIR/MediaDownloader-x64"
xcrun swiftc -parse-as-library -target arm64-apple-macos13.0 \
    -module-cache-path "$BUILD_DIR/arm64-cache" -O -framework AppKit \
    "${SOURCES[@]}" -o "$BUILD_DIR/MediaDownloader-arm64"
lipo -create "$BUILD_DIR/MediaDownloader-x64" "$BUILD_DIR/MediaDownloader-arm64" \
    -output "$CONTENTS/MacOS/MediaDownloader"

lipo -create "$TOOL_SOURCE_DIR/riedl-x64/ffmpeg" "$TOOL_SOURCE_DIR/riedl-arm64/ffmpeg" \
    -output "$HELPERS/ffmpeg"
lipo -create "$TOOL_SOURCE_DIR/riedl-x64/ffprobe" "$TOOL_SOURCE_DIR/riedl-arm64/ffprobe" \
    -output "$HELPERS/ffprobe"
lipo -create "$TOOL_SOURCE_DIR/deno-x64/deno" "$TOOL_SOURCE_DIR/deno-arm64/deno" \
    -output "$HELPERS/deno"
cp -p "$TOOL_SOURCE_DIR/yt-dlp_macos" "$HELPERS/yt-dlp"
chmod 755 "$HELPERS/yt-dlp"

cp -p "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS/Info.plist"
cp -p "$PROJECT_DIR/Resources/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
cp -p "$PROJECT_DIR/Resources/Mask group-1.png" "$CONTENTS/Resources/Mask group-1.png"
cp -p "$PROJECT_DIR/Resources/отсудствие превью.png" "$CONTENTS/Resources/отсудствие превью.png"
cp -p "$PROJECT_DIR/Resources/oleg.png" "$CONTENTS/Resources/oleg.png"
cp -p "$PROJECT_DIR/Resources/Fonts/Bellota-Bold.ttf" "$CONTENTS/Resources/Fonts/Bellota-Bold.ttf"
cp -p "$PROJECT_DIR/Resources/Fonts/OFL.txt" "$CONTENTS/Resources/Fonts/OFL.txt"

for tool in "$HELPERS/ffmpeg" "$HELPERS/ffprobe" "$HELPERS/deno" "$HELPERS/yt-dlp"; do
    codesign --force --sign - "$tool" >/dev/null
done
codesign --force --sign - "$APP_DIR" >/dev/null
echo "Создано: $APP_DIR"
