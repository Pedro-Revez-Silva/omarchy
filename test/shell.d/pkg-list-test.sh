#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

pkg_list="$ROOT/bin/omarchy-pkg-list"

x86_base=$(OMARCHY_PATH="$ROOT" "$pkg_list" base --arch x86_64)
grep -qx 'nvim' <<<"$x86_base" || fail "x86 package list retains nvim"
grep -qx 'obs-studio' <<<"$x86_base" || fail "x86 package list retains OBS Studio"
pass "x86 package list retains its native packages"

arm_base=$(OMARCHY_PATH="$ROOT" "$pkg_list" --arch aarch64 base)
grep -qx 'neovim' <<<"$arm_base" || fail "ARM package list substitutes Neovim"
if grep -Eq '^(dotnet-runtime|nvim|obs-studio|obsidian|pinta|qemu-user-static-binfmt)$' <<<"$arm_base"; then
  fail "ARM package list retains an unavailable package"
fi
pass "ARM base package list substitutes or omits unavailable packages"

arm_other=$(OMARCHY_PATH="$ROOT" "$pkg_list" other --arch arm64)
grep -qx 'linux-aarch64' <<<"$arm_other" || fail "ARM package list selects linux-aarch64"
grep -qx 'linux-aarch64-headers' <<<"$arm_other" || fail "ARM package list selects linux-aarch64 headers"
grep -qx 'vulkan-asahi' <<<"$arm_other" || fail "ARM package list retains Asahi graphics"
grep -qx 'vulkan-radeon' <<<"$arm_other" || fail "ARM package list retains generic ARM graphics"
if grep -Eq '^(linux|linux-headers|broadcom-wl|linux-t2|vulkan-intel|nvidia-dkms)$' <<<"$arm_other"; then
  fail "ARM package list retains an x86 or PC-specific package"
fi
pass "ARM secondary package list selects its kernel and portable drivers"

if OMARCHY_PATH="$ROOT" "$pkg_list" --arch riscv64 base >/dev/null 2>&1; then
  fail "package list accepts an unsupported architecture"
fi
pass "package list fails closed for unsupported architectures"
