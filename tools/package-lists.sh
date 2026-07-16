# DragonSDR apt package lists — single source of truth for suite install.
# Sourced by tools/install-suite.sh
#
# shellcheck shell=bash

# Desktop SDR, hardware libs, GNU Radio OOTs, and common analysis tools.
APT_SDR=(
  gnuradio gnuradio-dev gnuradio-doc
  gr-osmosdr gr-limesdr gr-fosphor gr-air-modes gr-hpsdr gr-dab gr-satellites
  libsoapysdr-dev python3-soapysdr soapysdr-module-osmosdr soapysdr-module-mirisdr uhd-soapysdr
  rtl-sdr librtlsdr-dev hackrf hackrf-firmware libhackrf-dev hackrf-doc
  airspy libairspy-dev bladerf libbladerf-dev limesuite limesuite-udev uhd-host libuhd-dev
  gqrx-sdr quisk inspectrum hacktv dfu-util openocd
  gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi ccache lz4 bzip2
)

# Desktop ham / digital modes (optional but installed by default suite).
APT_HAM=(
  libhamlib-dev libhamlib-utils python3-hamlib
  fldigi wsjtx wsjtx-data chirp direwolf gpredict grig xastir xastir-data
)

# Extra build/runtime libs commonly needed for OOT modules and host tools.
APT_SDR_BUILD=(
  build-essential cmake pkg-config git curl wget unzip
  python3-pip python3-venv python3-dev
  python3-numpy python3-scipy python3-matplotlib python3-yaml python3-requests python3-pyqt5 python3-psutil
  libssl-dev clang llvm-dev libclang-dev
  libusb-1.0-0-dev libfftw3-dev libvolk-dev portaudio19-dev libsndfile1-dev
  libboost-dev libboost-program-options-dev
)

# Combined list used by install-suite / verify.
APT_SUITE=("${APT_SDR_BUILD[@]}" "${APT_SDR[@]}" "${APT_HAM[@]}")
