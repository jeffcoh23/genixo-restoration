#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SRC="$ROOT_DIR/assets/source/genixo-site-icon-270.png"
WORDMARK_SRC="$ROOT_DIR/assets/source/genixio-horizontal-white-caps.png"
BRAND_BG="#14363e"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick (magick) is required." >&2
  exit 1
fi

if [[ ! -f "$ICON_SRC" || ! -f "$WORDMARK_SRC" ]]; then
  echo "Missing source assets in mobile/assets/source." >&2
  exit 1
fi

render_splash() {
  local out="$1"
  local width="$2"
  local height="$3"
  local logo_w="$4"

  magick -size "${width}x${height}" "xc:${BRAND_BG}" \
    \( "$WORDMARK_SRC" -resize "${logo_w}x" \) \
    -gravity center -composite \
    "$out"
}

render_android_foreground() {
  local out="$1"
  local size="$2"
  local inset=$(( size * 78 / 100 ))

  magick -size "${size}x${size}" xc:none \
    \( "$ICON_SRC" -resize "${inset}x${inset}" \) \
    -gravity center -composite \
    "$out"
}

echo "Generating iOS app icon..."
magick "$ICON_SRC" -resize 1024x1024 "$ROOT_DIR/ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png"

echo "Generating iOS splash images..."
for splash in \
  "$ROOT_DIR/ios/App/App/Assets.xcassets/Splash.imageset/splash-2732x2732.png" \
  "$ROOT_DIR/ios/App/App/Assets.xcassets/Splash.imageset/splash-2732x2732-1.png" \
  "$ROOT_DIR/ios/App/App/Assets.xcassets/Splash.imageset/splash-2732x2732-2.png"
do
  render_splash "$splash" 2732 2732 980
done

echo "Generating Android launcher icons..."
for spec in \
  mdpi:48:108 \
  hdpi:72:162 \
  xhdpi:96:216 \
  xxhdpi:144:324 \
  xxxhdpi:192:432
do
  IFS=":" read -r density icon_size fg_size <<<"$spec"
  base_dir="$ROOT_DIR/android/app/src/main/res/mipmap-${density}"
  magick "$ICON_SRC" -resize "${icon_size}x${icon_size}" "$base_dir/ic_launcher.png"
  magick "$ICON_SRC" -resize "${icon_size}x${icon_size}" "$base_dir/ic_launcher_round.png"
  render_android_foreground "$base_dir/ic_launcher_foreground.png" "$fg_size"
done

echo "Generating Android splash images..."
while IFS=":" read -r rel width height logo_w; do
  render_splash "$ROOT_DIR/$rel" "$width" "$height" "$logo_w"
done <<'EOF'
android/app/src/main/res/drawable/splash.png:480:320:240
android/app/src/main/res/drawable-port-mdpi/splash.png:320:480:220
android/app/src/main/res/drawable-port-hdpi/splash.png:480:800:300
android/app/src/main/res/drawable-port-xhdpi/splash.png:720:1280:420
android/app/src/main/res/drawable-port-xxhdpi/splash.png:960:1600:540
android/app/src/main/res/drawable-port-xxxhdpi/splash.png:1280:1920:700
android/app/src/main/res/drawable-land-mdpi/splash.png:480:320:240
android/app/src/main/res/drawable-land-hdpi/splash.png:800:480:300
android/app/src/main/res/drawable-land-xhdpi/splash.png:1280:720:440
android/app/src/main/res/drawable-land-xxhdpi/splash.png:1600:960:560
android/app/src/main/res/drawable-land-xxxhdpi/splash.png:1920:1280:700
EOF

echo "Brand asset generation complete."
