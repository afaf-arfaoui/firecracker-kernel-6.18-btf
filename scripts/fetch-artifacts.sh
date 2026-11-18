#!/usr/bin/env bash
#
# fetch-artifacts.sh
#
# ABOUT THIS SCRIPT DOES
# It downloads the three files the lab needs:
#   1. the Firecracker program
#   2. the Firecracker CI kernel (the Linux kernel the microVMs boot)
#   3. the Ubuntu root filesystem (the operating system inside each microVM)
#
# It asks you before every download. If you say no, nothing is downloaded.
# If a file already exists, the script skips it.
#
# HOW TO RUN IT
#   bash fetch-artifacts.sh             asks before each download
#   bash fetch-artifacts.sh --dry-run   only shows what it would download
#
# THE FILES GO HERE
#   ~/Desktop/microVMs/firecracker       the Firecracker program
#   ~/Desktop/microVMs/kernel_rootfs     the kernel and the Ubuntu image

# Stop the script at the first error.
set -euo pipefail

# The lab folders.
LAB="$HOME/Desktop/microVMs"
FC_DIR="$LAB/firecracker"
KR_DIR="$LAB/kernel_rootfs"

# The processor type, for example x86_64. The downloads depend on it.
ARCH="$(uname -m)"

# Where the Firecracker releases are published on GitHub.
RELEASES="https://github.com/firecracker-microvm/firecracker/releases"

# Where the Firecracker CI files are stored.
BUCKET="https://s3.amazonaws.com/spec.ccfc.min"

# Dry run means: show what would happen, download nothing.
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

# This function asks a yes or no question.
# It returns success (yes) only when you type y or Y.
# In dry run mode it prints the question and returns "no", so nothing is downloaded.
ask() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN  would ask: $1"
    return 1
  fi
  local answer
  read -r -p "$1 [y/N] " answer
  [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

# Make sure both folders exist. mkdir -p does nothing if they already exist.
mkdir -p "$FC_DIR" "$KR_DIR"

# ---------------------------------------------------------------
# STEP 1: the Firecracker program
# ---------------------------------------------------------------

# Ask GitHub for the newest release. It answers with the address of the
# release page, and the last part of that address is the version, for example v1.17.0.
TAG=$(basename "$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$RELEASES/latest")")

# The program ends up in a folder named after the version.
FC_BINARY="$FC_DIR/release-$TAG-$ARCH/firecracker-$TAG-$ARCH"

if [ -x "$FC_BINARY" ]; then
  echo "SKIP  Firecracker $TAG is already installed"
elif ask "Download Firecracker $TAG into $FC_DIR?"; then
  # Download the archive and unpack it into the Firecracker folder.
  curl -fsSL "$RELEASES/download/$TAG/firecracker-$TAG-$ARCH.tgz" | tar -xz -C "$FC_DIR"
  if [ -x "$FC_BINARY" ]; then
    echo "DONE  Firecracker $TAG"
  else
    echo "FAIL  the archive did not contain $FC_BINARY"
    exit 1
  fi
else
  echo "SKIP  Firecracker was not downloaded"
fi

# ---------------------------------------------------------------
# STEP 2: find the newest Firecracker CI build
# ---------------------------------------------------------------

# The CI builds are stored in folders named by date and commit,
# for example firecracker-ci/20260301-abc123/. We list the folders,
# sort them, and keep the last one, which is the newest.
BUILD=$(curl -fsSL "$BUCKET?list-type=2&prefix=firecracker-ci/&delimiter=/" \
  | grep -oP "(?<=<Prefix>)firecracker-ci/[0-9]{8}-[^/]+/(?=</Prefix>)" \
  | sort | tail -1 || true)

if [ -z "$BUILD" ]; then
  echo "FAIL  no Firecracker CI build folder was found"
  exit 1
fi

# ---------------------------------------------------------------
# STEP 3: the CI kernel
# ---------------------------------------------------------------

# Look inside the newest build folder for kernel files named vmlinux-<version>.
# Sort them by version and keep the newest one.
KERNEL_KEY=$(curl -fsSL "$BUCKET?list-type=2&prefix=${BUILD}${ARCH}/vmlinux-" \
  | grep -oP "(?<=<Key>)(${BUILD}${ARCH}/vmlinux-[0-9]+\.[0-9]+\.[0-9]{1,3})(?=</Key>)" \
  | sort -V | tail -1 || true)

if [ -z "$KERNEL_KEY" ]; then
  echo "FAIL  no CI kernel was found in $BUILD"
  exit 1
fi

# The file name on your laptop is the last part of the key, for example vmlinux-6.18.56.
KERNEL_FILE="$KR_DIR/$(basename "$KERNEL_KEY")"

if [ -s "$KERNEL_FILE" ]; then
  echo "SKIP  kernel $(basename "$KERNEL_FILE") is already there"
elif ask "Download the kernel $(basename "$KERNEL_KEY") into $KR_DIR?"; then
  curl -fsSL -o "$KERNEL_FILE" "$BUCKET/$KERNEL_KEY"
  # A file of zero size means the download failed, so we stop here.
  if [ ! -s "$KERNEL_FILE" ]; then
    echo "FAIL  the kernel download is empty"
    exit 1
  fi
  echo "DONE  kernel $(basename "$KERNEL_FILE")"
else
  echo "SKIP  kernel was not downloaded"
fi

# ---------------------------------------------------------------
# STEP 4: the Ubuntu root filesystem
# ---------------------------------------------------------------

# Look in the same build folder for the Ubuntu image, for example ubuntu-24.04.squashfs.
ROOTFS_KEY=$(curl -fsSL "$BUCKET?list-type=2&prefix=${BUILD}${ARCH}/ubuntu-" \
  | grep -oP "(?<=<Key>)(${BUILD}${ARCH}/ubuntu-[0-9]+\.[0-9]+\.squashfs)(?=</Key>)" \
  | sort -V | tail -1 || true)

if [ -z "$ROOTFS_KEY" ]; then
  echo "FAIL  no Ubuntu image was found in $BUILD"
  exit 1
fi

# Take the version out of the name, for example 24.04, and build our file name from it.
UBUNTU_VERSION=$(basename "$ROOTFS_KEY" .squashfs | grep -oE '[0-9]+\.[0-9]+')
ROOTFS_FILE="$KR_DIR/ubuntu-$UBUNTU_VERSION.squashfs.upstream"

if [ -s "$ROOTFS_FILE" ]; then
  echo "SKIP  Ubuntu image $(basename "$ROOTFS_FILE") is already there"
elif ask "Download the Ubuntu image $(basename "$ROOTFS_FILE") into $KR_DIR?"; then
  curl -fsSL -o "$ROOTFS_FILE" "$BUCKET/$ROOTFS_KEY"
  if [ ! -s "$ROOTFS_FILE" ]; then
    echo "FAIL  the Ubuntu download is empty"
    exit 1
  fi
  echo "DONE  Ubuntu image $(basename "$ROOTFS_FILE")"
else
  echo "SKIP  Ubuntu image was not downloaded"
fi

# SUMMARY
echo
echo "Finished. The lab files are in $LAB"
