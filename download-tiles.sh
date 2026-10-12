#!/usr/bin/env bash
# download-tiles.sh: Download a PMTiles basemap for the demo.
#
# This script downloads a geographic extract from the Protomaps daily
# planet build using the pmtiles CLI. The result is a small file
# (its size grows with --maxzoom) placed in the static resources
# directory where Spring Boot can serve it.
#
# Prerequisites:
#   - pmtiles CLI: https://github.com/protomaps/go-pmtiles/releases
#     (single binary, no install needed)
#
# Usage:
#   ./download-tiles.sh                  # Italy, zoom 0-6 (default, ~1.6 MB)
#   ./download-tiles.sh --maxzoom 10     # Italy, zoom 0-10 (larger file)
#   BBOX="-5.14,41.33,9.56,51.09" ./download-tiles.sh   # France instead (see README)

set -euo pipefail

DEST="src/main/resources/static/data/planet_z6.pmtiles"
BBOX="${BBOX:-6.63,36.62,18.52,47.09}"   # Italy by default
MAXZOOM="${1:-}"
MAXZOOM_FLAG=""

if [ "$MAXZOOM" = "--maxzoom" ] && [ -n "${2:-}" ]; then
    MAXZOOM_FLAG="--maxzoom=$2"
elif [ -z "$MAXZOOM" ]; then
    MAXZOOM_FLAG="--maxzoom=6"
fi

# Protomaps keeps daily builds for one week: default to yesterday's build (UTC).
# Override with a specific build, another URL or a local file:
#   SOURCE=https://build.protomaps.com/20261005.pmtiles ./download-tiles.sh
#   SOURCE=./planet.pmtiles ./download-tiles.sh
yesterday() {
    date -u -d yesterday +%Y%m%d 2>/dev/null || date -u -v-1d +%Y%m%d   # GNU || macOS
}
SOURCE="${SOURCE:-https://build.protomaps.com/$(yesterday).pmtiles}"

echo "Extracting tiles for bbox=$BBOX $MAXZOOM_FLAG ..."
echo "Source: $SOURCE"
echo "(Protomaps daily planet builds: https://docs.protomaps.com/basemaps/downloads)"
echo ""

if ! command -v pmtiles &> /dev/null; then
    echo "Error: 'pmtiles' CLI not found."
    echo "Download it from: https://github.com/protomaps/go-pmtiles/releases"
    echo ""
    echo "Quick install (Linux/macOS):"
    echo "  curl -L https://github.com/protomaps/go-pmtiles/releases/latest/download/go-pmtiles_Linux_x86_64.tar.gz | tar xz"
    echo "  sudo mv pmtiles /usr/local/bin/"
    exit 1
fi

mkdir -p "$(dirname "$DEST")"

if ! pmtiles extract "$SOURCE" "$DEST" --bbox="$BBOX" $MAXZOOM_FLAG; then
    echo "Extraction failed. If that build is not available, pick a date from"
    echo "https://maps.protomaps.com/builds and run:"
    echo "  SOURCE=https://build.protomaps.com/YYYYMMDD.pmtiles $0"
    exit 1
fi

echo ""
echo "Done! Saved to: $DEST"
echo "File size: $(du -h "$DEST" | cut -f1)"
echo ""
echo "Start the application:"
echo "  ./mvnw spring-boot:run"
echo "  open http://localhost:8080"
