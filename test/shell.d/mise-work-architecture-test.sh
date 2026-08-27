#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

mise_work="$ROOT/install/user/mise-work.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/bin" "$fixture/node/bin"
cat >"$fixture/bin/mise" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$MISE_CALLS"
EOF
chmod +x "$fixture/bin/mise"
printf '#!/bin/sh\n' >"$fixture/node/bin/node"
chmod +x "$fixture/node/bin/node"

for pair in "x86_64 x64" "aarch64 arm64" "arm64 arm64"; do
  read -r machine dist_arch <<<"$pair"
  case_dir="$fixture/$machine"
  mkdir -p "$case_dir/packages" "$case_dir/home"
  tar -czf "$case_dir/packages/node-v24.7.0-linux-${dist_arch}.tar.gz" -C "$fixture/node" .

  cat >"$fixture/bin/uname" <<EOF
#!/bin/bash
printf '%s\n' '$machine'
EOF
  chmod +x "$fixture/bin/uname"

  MISE_CALLS="$case_dir/mise-calls" \
    HOME="$case_dir/home" \
    PATH="$fixture/bin:$PATH" \
    OMARCHY_SETUP_CONTEXT=iso-chroot \
    OMARCHY_NODE_PACKAGE_DIR="$case_dir/packages" \
    bash "$mise_work"

  [[ -x "$case_dir/home/.local/share/mise/installs/node/24.7.0/bin/node" ]] ||
    fail "mise work installs the $dist_arch Node archive on $machine"
  grep -Fx 'use -g node@24.7.0' "$case_dir/mise-calls" >/dev/null ||
    fail "mise work activates the bundled Node version on $machine"
done

pass "offline mise setup selects x64 and arm64 Node archives by machine architecture"
