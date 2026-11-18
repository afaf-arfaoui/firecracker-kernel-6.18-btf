#!/usr/bin/env bash
#
# check-prereqs.sh
#
# ABOUT THIS SCRIPT
# It checks that this laptop is ready for the lab.
# It only reads information. It never installs, downloads, or changes anything.
#
# WHAT THE RESULTS MEAN
#   PASS  this item is ready
#   FAIL  this item is missing. The line under it tells how to fix it.
#   NOTE  this is information only.
#
# The script ends with exit code 0 when everything passes.
# It ends with exit code 1 when at least one check fails.

# This counter goes up by one for every failed check.
problems=0

# pass prints a PASS line for one check.
pass() {
  echo "PASS  $1"
}

# fail prints a FAIL line and the fix, then adds one to the problem counter.
fail() {
  echo "FAIL  $1"
  echo "      fix: $2"
  problems=$((problems + 1))
}

# note prints information (it does NOT mean there is an issue).
note() {
  echo "NOTE  $1"
}

# CHECK 1: the processor type.
# The lab was built and tested on an Intel or AMD processor of the x86_64 type.
# The command uname -m prints the processor type, for example x86_64.
architecture=$(uname -m)
if [ "$architecture" = "x86_64" ]; then
  pass "processor type is x86_64"
else
  fail "processor type is $architecture" "this lab was tested only on x86_64"
fi

# CHECK 2: the KVM device file.
# KVM is the part of Linux that lets a program run a virtual machine.
# Firecracker uses it to run the microVMs. KVM appears as the file /dev/kvm.
# We need to be able to read and write that file.
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  pass "/dev/kvm can be read and written"
else
  fail "/dev/kvm cannot be used by your user" "run: sudo usermod -aG kvm \$USER   then log out and log in again"
fi

# CHECK 3: the programs the lab needs.
# We look for each program one by one. The command "command -v" prints the
# location of a program, and it fails when the program is not installed.
# The list stores the names of the programs that are missing.
missing=""
for tool in ip iptables curl ssh scp zcat mount sysctl tar truncate unsquashfs mkfs.ext4 awk sort; do
  if ! command -v "$tool" > /dev/null 2>&1; then
    missing="$missing $tool"
  fi
done
if [ -z "$missing" ]; then
  pass "all the programs the lab needs are installed"
else
  fail "these programs are missing:$missing" "run: sudo apt install -y iproute2 iptables curl openssh-client gzip tar squashfs-tools e2fsprogs"
fi

# CHECK 4: free disk space.
# The kernel build and the disk images need several gigabytes.
# The command df shows the free space of the disk that holds your home folder.
# -P keeps the output in one fixed layout and -BG shows the sizes in gigabytes.
# awk takes the fourth column of the second line, which is the free space.
# tr removes the letter G, so we are left with a plain number.
free_gb=$(df -P -BG "$HOME" | awk 'NR==2 {print $4}' | tr -d 'G')
if [ -n "$free_gb" ] && [ "$free_gb" -ge 15 ]; then
  pass "free disk space is ${free_gb} GB"
else
  fail "free disk space is ${free_gb:-unknown} GB" "free at least 15 GB before building the kernel"
fi

# CHECK 5: the connection to the Internet.
# The default route tells which network interface to use for
# traffic that leaves your own network.
uplink=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
if [ -n "$uplink" ]; then
  pass "Internet traffic leaves through the interface $uplink"
else
  fail "no default route was found" "connect the laptop to a network, then run this check again"
fi

# CHECK 6: Firecracker. This is information only.
# We look for the binary in the lab folder.
fc_binary=$(ls "$HOME"/Desktop/microVMs/firecracker/release-*/firecracker-*-"$architecture" 2>/dev/null | tail -1)
if [ -n "$fc_binary" ]; then
  pass "Firecracker is installed: $fc_binary"
else
  note "Firecracker is not installed yet. fetch-artifacts.sh will ask before it downloads it."
fi

# SUMMARY
echo
if [ "$problems" -eq 0 ]; then
  echo "All checks passed. The laptop is ready."
  exit 0
else
  echo "$problems check(s) failed. Fix the FAIL lines above, then run this script again."
  exit 1
fi
