#!/bin/sh
# Tests for tools image — distro-independent
set -e

PASS=0
FAIL=0

check() {
    desc="$1"; shift
    if "$@" > /dev/null 2>&1; then
        echo "  PASS  $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== tools tests ==="

# -- Shell --
echo ""
echo "--- Shell ---"
check "bash available"              bash --version

# -- Version control --
echo ""
echo "--- Version control ---"
check "git available"               git --version

# -- Network tools --
echo ""
echo "--- Network tools ---"
check "wget available"              wget --version
check "curl available"              curl --version
check "ssh client available"        ssh -V

# -- Certificates --
echo ""
echo "--- Certificates ---"
check "ca-certificates present"     test -d /etc/ssl/certs

# -- Archive tools --
echo ""
echo "--- Archive tools ---"
check "tar available"               tar --version
check "xz available"                xz --version
check "zstd available"              zstd --version
check "zip available"               zip --version
check "unzip available"             unzip -v
check "7z available"                7z --help

# -- Text processing --
echo ""
echo "--- Text processing ---"
check "jq available"                jq --version
check "grep available"              grep --version
check "sed available"               sed --version
check "diff available"              diff --version

# -- File utilities --
echo ""
echo "--- File utilities ---"
check "find available"              find --version
check "tree available"              tree --version

# -- System tools --
echo ""
echo "--- System tools ---"
check "htop available"              htop --version
check "nano available"              nano --version

# -- Summary --
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
