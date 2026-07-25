#!/usr/bin/env bash
# DragonSDR QEMU-lcgamboa builder — full shared-library mode
#
# Requirement: produce libqemu-<arch>.so for every architecture in targets.txt.
# - xtensa + riscv32 MUST come from the fork's own build_libqemu-esp32.sh
#   (Velxio / picsimlab API compatibility).
# - All other architectures are built using the generalized rsp-file post-processing
#   hack so they also become shared libraries.
set -euo pipefail

QEMU_DIR="${QEMU_LCGAMBOA_DIR:-$HOME/Applications/QEMU-lcgamboa}"
PINNED_REF_FILE="$(dirname "$0")/pinned-commit"
TARGETS_FILE="$(dirname "$0")/targets.txt"

REF="$(cat "$PINNED_REF_FILE" | head -1 | tr -d ' \t\r\n')"
CACHE="$QEMU_DIR/.cache/qemu-$REF"

echo "DragonSDR QEMU-lcgamboa builder (full shared-library mode)"
echo "  ref           : $REF"
echo "  install prefix: $QEMU_DIR/$REF"
echo

mkdir -p "$QEMU_DIR" "$CACHE"

if [[ ! -d "$CACHE/.git" ]]; then
  echo "Cloning lcgamboa/qemu @ $REF ..."
  if git ls-remote --heads https://github.com/lcgamboa/qemu.git "$REF" | grep -q .; then
    git clone --depth 1 --branch "$REF" https://github.com/lcgamboa/qemu.git "$CACHE"
  else
    git clone --depth 1 https://github.com/lcgamboa/qemu.git "$CACHE"
    git -C "$CACHE" fetch --depth 1 origin "$REF" || true
    git -C "$CACHE" checkout "$REF" || true
  fi
fi

cd "$CACHE"

# Best-effort dependencies
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -qq || true
  sudo apt-get install -y --no-install-recommends \
    git ninja-build pkg-config libglib2.0-dev libpixman-1-dev \
    python3 python3-venv python3-pip flex bison libslirp-dev \
    libgcrypt20-dev meson || true
fi

build_one_shared() {
  local arch="$1"
  local builddir="$CACHE/build-$arch"
  local libname="libqemu-$arch.so"

  if [[ -f "$QEMU_DIR/$REF/lib/$libname" ]]; then
    echo "  [skip] $libname already present"
    return 0
  fi

  echo "Building $arch-softmmu as shared library ..."
  rm -rf "$builddir"
  mkdir -p "$builddir"

  if ! (cd "$builddir" && ../configure \
        --target-list="$arch-softmmu" \
        --enable-shared-lib \
        --enable-fdt=system \
        --enable-modules \
        --enable-tcg \
        --enable-system \
        --enable-user \
        --enable-linux-user \
        --enable-bsd-user \
        --enable-guest-agent \
        --enable-vnc \
        --enable-vnc-jpeg \
        --enable-vnc-png \
        --enable-vnc-sasl \
        --enable-vnc-ws \
        --enable-curses \
        --enable-sdl \
        --enable-gtk \
        --enable-opengl \
        --enable-virglrenderer \
        --enable-spice \
        --enable-spice-protocol \
        --enable-usb-redir \
        --enable-smartcard \
        --enable-slirp \
        --enable-fuse \
        --enable-libnfs \
        --enable-curl \
        --enable-libssh \
        --enable-libxml2 \
        --enable-bzip2 \
        --enable-lzo \
        --enable-snappy \
        --enable-zstd \
        --enable-capstone \
        --enable-debug-info \
        --enable-debug-tcg \
        --enable-tcg-interpreter \
        --enable-pipewire \
        --enable-alsa \
        --enable-pa \
        --enable-jack \
        --enable-oss \
        --enable-coreaudio \
        --enable-hvf \
        --enable-kvm \
        --enable-xen \
        --enable-xen-pci-passthrough \
        --enable-vhost-kernel \
        --enable-vhost-user \
        --enable-vhost-vdpa \
        --enable-vhost-net \
        --enable-attr \
        --enable-brlapi \
        --enable-crypto-afalg \
        --enable-gettext \
        --enable-guest-agent-msi \
        --enable-iconv \
        --enable-libdaxctl \
        --enable-libiscsi \
        --enable-libpmem \
        --enable-libudev \
        --enable-malloc-trim \
        --enable-mpath \
        --enable-numa \
        --enable-rdma \
        --enable-replication \
        --enable-seccomp \
        --enable-tpm \
        --enable-vde \
        --enable-virtfs \
        --enable-virtiofsd \
        --enable-zlib-test \
        --extra-cflags="-fPIC -fvisibility=hidden" \
        --extra-ldflags="-shared" \
        --disable-werror \
        --disable-docs 2>&1); then
    echo "  [warn] configure failed for $arch — skipping"
    return 1
  fi

  if ! ninja -C "$builddir" -j"$(nproc)" 2>&1; then
    echo "  [warn] ninja build failed for $arch — skipping"
    return 1
  fi

  # Locate the rsp file (Meson puts it under the build dir)
  local rsp
  rsp=$(find "$builddir" -name '*.rsp' 2>/dev/null | head -1)
  if [[ -z "$rsp" || ! -f "$rsp" ]]; then
    echo "  [warn] could not find rsp file for $arch — skipping shared-lib step"
    return 1
  fi

  local main_obj="qemu-system-$arch.p/system_main.c.o"
  # Extract the final link command from the rsp
  local cmd
  cmd=$(tail -n 1 "$rsp" | sed 's/.*-o /-o /')

  # Strip the original main object and rewrite the output to a shared library
  sed -i "s|$main_obj||g" "$rsp"
  sed -i "s|-o qemu-system-$arch|-shared -o $libname|g" "$rsp"

  if eval "$cmd -ggdb @$rsp" 2>&1; then
    mkdir -p "$QEMU_DIR/$REF/lib"
    if [[ -f "$builddir/$libname" ]]; then
      cp "$builddir/$libname" "$QEMU_DIR/$REF/lib/"
      echo "    -> $QEMU_DIR/$REF/lib/$libname"
    else
      echo "  [warn] $libname was not produced in $builddir"
      return 1
    fi
  else
    echo "  [warn] re-link failed for $arch"
    return 1
  fi
}

# 1. ESP targets — must come from the fork's own script for Velxio compatibility
echo "=== ESP targets (Velxio / picsimlab compatibility) ==="
if [[ -x ./build_libqemu-esp32.sh ]]; then
  if ! ./build_libqemu-esp32.sh; then
    echo "  [error] build_libqemu-esp32.sh failed — Velxio will be broken"
    exit 1
  fi

  mkdir -p "$QEMU_DIR/$REF/lib"
  for lib in build/libqemu-xtensa.so build/libqemu-riscv32.so; do
    if [[ -f "$lib" ]]; then
      cp "$lib" "$QEMU_DIR/$REF/lib/"
      echo "  installed (from fork script): $QEMU_DIR/$REF/lib/$(basename "$lib")"
    else
      echo "  [warn] $(basename "$lib") not produced by fork script"
    fi
  done
else
  echo "  [error] build_libqemu-esp32.sh not found"
  exit 1
fi

# 2. All other architectures — equal priority, also as shared libraries
echo
echo "=== Other architectures (equal priority, shared libraries) ==="
while read -r arch; do
  [[ -z "$arch" || "$arch" =~ ^# ]] && continue
  case "$arch" in
    xtensa|riscv32) continue ;;
    *) build_one_shared "$arch" || true ;;
  esac
done < "$TARGETS_FILE"

# ESP32 ROM blobs (best effort)
ROM_DIR="$QEMU_DIR/$REF/share/qemu"
mkdir -p "$ROM_DIR"
for rom in esp32-v3-rom.bin esp32-v3-rom-app.bin esp32c3-rom.bin; do
  if [[ ! -f "$ROM_DIR/$rom" ]]; then
    echo "Fetching $rom ..."
    curl -fsSL -o "$ROM_DIR/$rom" \
      "https://raw.githubusercontent.com/espressif/esp-idf/release/v4.4/components/esp_rom/${rom}" \
      2>/dev/null || echo "  [warn] could not fetch $rom"
  fi
done

ln -sfn "$QEMU_DIR/$REF" "$QEMU_DIR/current"

echo
echo "QEMU-lcgamboa build complete."
echo "  libs:   $QEMU_DIR/current/lib/"
echo "  ROMs:   $QEMU_DIR/current/share/qemu/"
echo "  current -> $REF"