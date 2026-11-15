#!/usr/bin/env bash
# Package Linux 6.18 ACK AnyKernel3 flashable zip and module tarball for Redmi Note 12 4G (tapas/topaz)
set -euo pipefail
PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
. "$PROJECT_ROOT/scripts/project-env.sh"

DIST="$PROJECT_ROOT/dist/tapas-release"
mkdir -p "$DIST"

IMAGE="$K618/out-gki/arch/arm64/boot/Image"
[ -f "$IMAGE" ] || { echo "Missing kernel Image at $IMAGE" >&2; exit 1; }

echo "=== Packaging AnyKernel3 for Redmi Note 12 4G (tapas/topaz) ==="
w=$(mktemp -d)
trap 'rm -rf "$w"' EXIT

# Copy AnyKernel3 base
if [ -d "$AK3_SOURCE" ]; then
    cp -r "$AK3_SOURCE" "$w/ak3"
else
    git clone -q https://github.com/osm0sis/AnyKernel3 "$w/ak3"
fi
rm -rf "$w/ak3/.git" "$w/ak3/.github" "$w/ak3/README.md"

# Install tapas specific anykernel.sh
cp "$PROJECT_ROOT/tools/ak3/anykernel-tapas.sh" "$w/ak3/anykernel.sh"

# Install kernel Image
cp "$IMAGE" "$w/ak3/Image"

# Setup module directories for vendor_dlkm and vendor
MOD_DIR="$w/ak3/modules/vendor_dlkm/lib/modules"
mkdir -p "$MOD_DIR"

STRIP="$K618/ws/prebuilts/clang/host/linux-x86/clang-r584948c/bin/llvm-strip"
[ -x "$STRIP" ] || STRIP=$(command -v llvm-strip || command -v aarch64-linux-gnu-strip || echo "true")

# Collect all compiled techpack modules
if [ -d "$K618/tpmods" ]; then
    echo "Adding techpack modules from $K618/tpmods..."
    find "$K618/tpmods" -name "*.ko" -exec cp {} "$MOD_DIR/" \;
fi

# Collect all compiled SoC modules
if [ -d "$K618/soc" ]; then
    echo "Adding SoC modules from $K618/soc..."
    find "$K618/soc" -name "*.ko" -exec cp {} "$MOD_DIR/" \;
fi

# Strip debug symbols from all modules (reduces uncompressed size from 420MB+ down to ~39MB)
echo "Stripping debug symbols from modules..."
for mod in "$MOD_DIR"/*.ko; do
    "$STRIP" --strip-debug "$mod" 2>/dev/null || true
done

# Generate modules.load
(cd "$MOD_DIR" && ls *.ko > modules.load)

TOTAL_MODS=$(ls -1 "$MOD_DIR"/*.ko | wc -l)
echo "Total modules packaged: $TOTAL_MODS"

# Build AnyKernel3 zip
ZIP_OUT="$DIST/AnyKernel3-tapas-k618.zip"
rm -f "$ZIP_OUT"
(cd "$w/ak3" && zip -qr9 "$ZIP_OUT" . -x '.git*')
echo "Created: $ZIP_OUT ($(du -h "$ZIP_OUT" | cut -f1))"

# Build standalone modules tarball
TAR_OUT="$DIST/tapas-k618-modules.tar.gz"
rm -f "$TAR_OUT"
(cd "$MOD_DIR" && tar -czf "$TAR_OUT" *.ko modules.load)
echo "Created: $TAR_OUT ($(du -h "$TAR_OUT" | cut -f1))"

# Write SHA256SUMS
(cd "$DIST" && sha256sum AnyKernel3-tapas-k618.zip tapas-k618-modules.tar.gz > SHA256SUMS)
cat "$DIST/SHA256SUMS"

echo "=== Packaging Complete! ==="
