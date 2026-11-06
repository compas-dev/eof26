#!/usr/bin/env bash
# Regenerate the press-kit images and videos from cards.html.
# Needs: Google Chrome, ImageMagick (magick), ffmpeg, qrencode.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="$SRC/../assets"
ROOT="$SRC/../.."
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
URL="https://compas.dev/eof26/"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

qrencode -t SVG -m 0 -l M -o "$SRC/qr.svg" "$URL"

shot() { # format width height output [scale]
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --force-device-scale-factor="${5:-1}" --window-size="$2,$3" \
    --screenshot="$4" "file://$SRC/cards.html#$1" 2>/dev/null
}

# Stills
shot og       1200  630 "$OUT/eof26-link-preview-1200x630.png"
shot square   1080 1080 "$OUT/eof26-square-1080x1080.png"
shot portrait 1080 1350 "$OUT/eof26-portrait-1080x1350.png"
shot slide    1920 1080 "$OUT/eof26-screen-1920x1080.png"
shot poster    794 1123 "$OUT/eof26-poster-a4.png" 3
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer --allow-file-access-from-files \
  --print-to-pdf="$OUT/eof26-poster-a4.pdf" "file://$SRC/cards.html#poster" 2>/dev/null

# Videos: card without the mark, then the GIF blended in with "lighten" so its
# #101010 background disappears into the gradient.
video() { # format width height mark_x mark_y mark_w output
  shot "$1-video" "$2" "$3" "$TMP/$1.png"
  ffmpeg -v error -y -loop 1 -i "$TMP/$1.png" -i "$ROOT/assets/eof-wire.gif" -filter_complex \
    "[1:v]scale=$6:-2:flags=lanczos,pad=$2:$3:$4:$5:black,format=gbrp[m];[0:v]format=gbrp[b];[b][m]blend=all_mode=lighten:shortest=1,format=yuv420p" \
    -r 20 -c:v libx264 -crf 18 -preset slow -movflags +faststart "$7"
}
video square 1080 1080   72 120 936 "$OUT/eof26-square-1080x1080.mp4"
video slide  1920 1080  900 250 900 "$OUT/eof26-screen-1920x1080.mp4"

# Small WebM previews for the press page (browsers without H.264, e.g. VS Code)
mkdir -p "$OUT/preview"
ffmpeg -v error -y -i "$OUT/eof26-square-1080x1080.mp4" -vf scale=540:-2 -c:v libvpx-vp9 -crf 38 -b:v 0 -an "$OUT/preview/eof26-square.webm"
ffmpeg -v error -y -i "$OUT/eof26-screen-1920x1080.mp4" -vf scale=960:-2 -c:v libvpx-vp9 -crf 38 -b:v 0 -an "$OUT/preview/eof26-screen.webm"

# Animation and still of the mark on its own
cp "$ROOT/assets/eof-wire.gif" "$OUT/eof26-mark-animated.gif"
magick "$ROOT/assets/eof-dark.png" -background '#101010' -flatten "$OUT/eof26-mark.png"
cp "$ROOT/assets/compas-header.png" "$OUT/compas-logo-horizontal.png"
cp "$SRC"/logos/nccr-dfab-logo-*.png "$OUT/"  # from dfab.ch; only small PNGs are published there

# Everything in one download
rm -f "$OUT/eof26-press-kit.zip"
(cd "$OUT" && zip -q -X eof26-press-kit.zip ./*.png ./*.pdf ./*.mp4 ./*.gif)

ls -la "$OUT"
