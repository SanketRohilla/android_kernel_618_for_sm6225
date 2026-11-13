#!/usr/bin/env bash
# Public entry point: enforce memory, swap and CPU limits for preparation/build.
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
action=${1:-}
case "$action" in bootstrap|prepare|build|verify|gate1|gate2|gate3|gate4|vendor-modules|tapas-media|test-installer|test-runtime) ;; *) echo 'Usage: bash scripts/run-limited.sh bootstrap|prepare|build|verify|gate1|gate2|gate3|gate4|vendor-modules|tapas-media|test-installer|test-runtime'; exit 2;; esac
shift
. "$here/project-env.sh"
if [ "$(id -u)" -eq 0 ]; then
  exec systemd-run --scope --quiet \
    -p MemoryMax=12G -p MemoryHigh=10G -p MemorySwapMax=1G -p CPUQuota=400% \
    env BUILD_ROOT="$BUILD_ROOT" TAG="${TAG:-release}" JOBS="${JOBS:-4}" K618_INPUT_SPEC="${K618_INPUT_SPEC:-}" \
    bash "$here/cgroup-check.sh" bash "$here/$action.sh" "$@"
elif sudo -n true 2>/dev/null; then
  exec sudo systemd-run --scope --quiet \
    --uid="$(id -u)" --gid="$(id -g)" \
    -p MemoryMax=12G -p MemoryHigh=10G -p MemorySwapMax=1G -p CPUQuota=400% \
    env BUILD_ROOT="$BUILD_ROOT" TAG="${TAG:-release}" JOBS="${JOBS:-4}" K618_INPUT_SPEC="${K618_INPUT_SPEC:-}" \
    bash "$here/cgroup-check.sh" bash "$here/$action.sh" "$@"
else
  exec systemd-run --user --scope --quiet \
    -p MemoryMax=12G -p MemoryHigh=10G -p MemorySwapMax=1G -p CPUQuota=400% \
    env BUILD_ROOT="$BUILD_ROOT" TAG="${TAG:-release}" JOBS="${JOBS:-4}" K618_INPUT_SPEC="${K618_INPUT_SPEC:-}" \
    bash "$here/cgroup-check.sh" bash "$here/$action.sh" "$@"
fi
