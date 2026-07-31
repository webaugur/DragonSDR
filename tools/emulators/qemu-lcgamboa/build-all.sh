#!/usr/bin/env bash
# DragonSDR QEMU builder — split layout with clean build cache
#
# Path 1: ESP targets (xtensa, riscv32) only
#         Uses lcgamboa/picsimlab-esp32 + its own build_libqemu-esp32.sh
#         (Velxio / picsimlab API compatibility)
#
# Path 2: All other architectures
#         Uses utmapp/qemu (utm-edition) with --enable-shared-lib
#         Produces both libqemu-<arch>.so and qemu-system-<arch>
#
# Build artifacts live in $HOME/.cache/dragon-sdr/qemu-lcgamboa/
# Final install goes to ~/Applications/QEMU/
set -euo pipefail

PREFIX="${QEMU_PREFIX:-$HOME/Applications/QEMU}"
# Build cache lives OUTSIDE the install prefix
BUILD_CACHE="${QEMU_BUILD_CACHE:-$HOME/.cache/dragon-sdr/qemu-lcgamboa}"

# Auto-install missing build dependencies by default.
# Set QEMU_AUTO_DEPS=0 to disable automatic apt installation.
QEMU_AUTO_DEPS="${QEMU_AUTO_DEPS:-1}"

mkdir -p "$PREFIX/lib" "$PREFIX/bin" "$PREFIX/share/qemu" "$BUILD_CACHE"

echo "DragonSDR QEMU builder (split, unified prefix)"
echo "  prefix:      $PREFIX"
echo "  build cache: $BUILD_CACHE"
echo "  auto-deps:   $QEMU_AUTO_DEPS"
echo

# --- Pre-flight dependency check (enabled by default) ---
check_and_install_deps() {
  local pkgs=(
    # Core build system
    build-essential ninja-build python3 python3-pip meson pkg-config git curl
    # QEMU core + glib/pixman/fdt
    libglib2.0-dev libpixman-1-dev libfdt-dev
    # Audio (all the --enable-alsa/pa/jack/oss/pipewire/coreaudio we kept)
    libpipewire-0.3-dev libasound2-dev libpulse-dev libjack-jackd2-dev libsndio-dev
    # UI / graphics
    libsdl2-dev libsdl2-image-dev libgtk-3-dev libvte-2.91-dev libepoxy-dev
    libvirglrenderer-dev libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev
    # Remote / protocol
    libspice-server-dev libspice-protocol-dev libvdeplug-dev
    # Networking / block / USB
    libslirp-dev libfuse3-dev libnfs-dev libcurl4-openssl-dev libssh-dev
    libusb-1.0-0-dev libusbredirhost-dev libusbredirparser-dev
    # Compression
    libbz2-dev liblzo2-dev libsnappy-dev libzstd-dev
    # Misc features we enable
    libcapstone-dev libbrlapi-dev libgcrypt20-dev libgnutls28-dev
    libdaxctl-dev libiscsi-dev libpmem-dev libudev-dev
    libnuma-dev librdmacm-dev libseccomp-dev libtpms-dev libvirt-dev
    # Xen (required for --enable-xen)
    libxen-dev
    # Multipath (required for --enable-mpath)
    libdevmapper-dev libmpathpersist-dev
    # Smartcard / CAC (required for --enable-smartcard)
    libcacard-dev
    # RDMA / Infiniband
    libibverbs-dev libibmad-dev libibumad-dev
    # VNC / JPEG / PNG
    libvncserver-dev libjpeg-dev libpng-dev
    # Guest agent + modules + attr
    libattr1-dev libcap-ng-dev
    # Extra probes configure still performs
    liburing-dev libaio-dev libbpf-dev libxdp-dev libblkio-dev
    libxkbcommon-dev
  )

  local missing=()
  for p in "${pkgs[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then
      missing+=("$p")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "All required build dependencies are present."
    return 0
  fi

  echo "Missing build dependencies: ${missing[*]}"
  if [[ "$QEMU_AUTO_DEPS" == "1" ]]; then
    echo "Auto-installing (QEMU_AUTO_DEPS=1) ..."
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
  else
    echo "Automatic installation disabled (QEMU_AUTO_DEPS=0)."
    echo "Please install the missing packages manually and re-run."
    exit 1
  fi
}

check_and_install_deps

# --- Path 1: ESP targets (Velxio only) ---
ESP_CACHE="$BUILD_CACHE/qemu-picsimlab-esp32"
if [[ ! -d "$ESP_CACHE/.git" ]]; then
  echo "Cloning lcgamboa/qemu @ picsimlab-esp32 ..."
  git clone --depth 1 --branch picsimlab-esp32 https://github.com/lcgamboa/qemu.git "$ESP_CACHE"
fi

if [[ -x "$ESP_CACHE/build_libqemu-esp32.sh" ]]; then
  echo "Building ESP targets via fork script ..."
  (cd "$ESP_CACHE" && ./build_libqemu-esp32.sh) || exit 1
  for lib in "$ESP_CACHE"/build/libqemu-xtensa.so "$ESP_CACHE"/build/libqemu-riscv32.so; do
    [[ -f "$lib" ]] && cp "$lib" "$PREFIX/lib/"
  done
  echo "  installed: libqemu-xtensa.so, libqemu-riscv32.so"
fi

# --- Path 2: All other architectures (UTM fork with --enable-shared-lib) ---
UTM_CACHE="$BUILD_CACHE/qemu-utm"
if [[ ! -d "$UTM_CACHE/.git" ]]; then
  echo "Cloning utmapp/qemu @ utm-edition ..."
  git clone --depth 1 --branch utm-edition https://github.com/utmapp/qemu.git "$UTM_CACHE"
fi

build_one() {
  local arch="$1"
  local libname="libqemu-$arch.so"
  local binname="qemu-system-$arch"

  if [[ -f "$PREFIX/lib/$libname" && -f "$PREFIX/bin/$binname" ]]; then
    echo "  [skip] $arch"
    return 0
  fi

  echo "Building $arch (UTM + shared-lib) ..."

  # UTM hard-codes its build directory to ./build — clean it between arches
  rm -rf "$UTM_CACHE/build"

  # Only enable the TCG interpreter on architectures that lack a native backend.
  # On x86_64, aarch64, arm, ppc*, mips*, riscv*, xtensa etc. the native backend
  # is strongly preferred (meson warns when the interpreter is forced).
  tcg_interpreter_flag=""
  case "$arch" in
    nios2|m68k|sh4)
      tcg_interpreter_flag="--enable-tcg-interpreter"
      ;;
  esac

  (cd "$UTM_CACHE" && ./configure \
    --target-list="$arch-softmmu" \
    --enable-shared-lib \
    --extra-cflags='-fPIC' \
    --enable-fdt=system \
    --enable-modules \
    --enable-tcg \
    --enable-system \
    --enable-user \
    --enable-linux-user \
    --enable-guest-agent \
    --enable-vnc \
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
    --enable-bzip2 \
    --enable-lzo \
    --enable-snappy \
    --enable-zstd \
    --enable-capstone \
    --enable-debug-info \
    --enable-debug-tcg \
    $tcg_interpreter_flag \
    --enable-pipewire \
    --enable-alsa \
    --enable-pa \
    --enable-jack \
    --enable-oss \
    --enable-kvm \
    --enable-xen \
    --enable-vhost-kernel \
    --enable-vhost-user \
    --enable-vhost-vdpa \
    --enable-vhost-net \
    --enable-attr \
    --enable-brlapi \
    --enable-crypto-afalg \
    --enable-gettext \
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
    --disable-werror \
    --disable-docs) || return 1

  ninja -C "$UTM_CACHE/build" -j"$(nproc)" || return 1

  [[ -f "$UTM_CACHE/build/$libname" ]] && cp "$UTM_CACHE/build/$libname" "$PREFIX/lib/"
  [[ -f "$UTM_CACHE/build/$binname" ]] && cp "$UTM_CACHE/build/$binname" "$PREFIX/bin/"
}

echo
echo "=== Other architectures (UTM + shared-lib) ==="
while read -r arch; do
  [[ -z "$arch" || "$arch" =~ ^# ]] && continue
  case "$arch" in
    xtensa|riscv32) continue ;;
    *) build_one "$arch" || true ;;
  esac
done < "$(dirname "$0")/targets.txt"

# ROM blobs (best effort)
ROM_DIR="$PREFIX/share/qemu"
mkdir -p "$ROM_DIR"
for rom in esp32-v3-rom.bin esp32-v3-rom-app.bin esp32c3-rom.bin; do
  [[ -f "$ROM_DIR/$rom" ]] || curl -fsSL -o "$ROM_DIR/$rom" \
    "https://raw.githubusercontent.com/espressif/esp-idf/release/v4.4/components/esp_rom/${rom}" 2>/dev/null || true
done

ln -sfn "$PREFIX" "$PREFIX/current"

echo
echo "QEMU build complete."
echo "  prefix: $PREFIX"
echo "  libs:   $PREFIX/lib/"
echo "  bins:   $PREFIX/bin/"
echo "  ROMs:   $PREFIX/share/qemu/"
echo "  current -> $PREFIX"