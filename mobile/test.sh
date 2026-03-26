#!/bin/sh
# Tests for alpine-mobile image
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

echo "=== alpine-mobile tests ==="

# ── glibc compatibility ──
echo ""
echo "--- glibc compatibility ---"
check "gcompat installed"          test -f /lib/libgcompat.so.0
check "ld-linux-x86-64 exists"    test -f /lib/ld-linux-x86-64.so.2

# ── JDK ──
echo ""
echo "--- JDK ---"
check "java available"            java -version
check "javac available"           javac -version
check "JAVA_HOME set"            test -n "$JAVA_HOME"
check "JAVA_HOME exists"         test -d "$JAVA_HOME"

# ── Android SDK ──
echo ""
echo "--- Android SDK ---"
check "ANDROID_HOME set"         test -n "$ANDROID_HOME"
check "ANDROID_HOME exists"      test -d "$ANDROID_HOME"
check "sdkmanager available"     sdkmanager --version
check "adb available"            adb version
check "platform-tools installed" test -d "$ANDROID_HOME/platform-tools"
check "build-tools installed"    test -d "$ANDROID_HOME/build-tools"
check "ndk installed"            test -d "$ANDROID_HOME/ndk"
check "platforms installed"      ls "$ANDROID_HOME/platforms"/android-* > /dev/null 2>&1

# ── Gradle ──
echo ""
echo "--- Gradle ---"
check "gradle available"         gradle --version
check "GRADLE_HOME set"         test -n "$GRADLE_HOME"

# ── Node.js ──
echo ""
echo "--- Node.js ---"
check "node available"           node --version
check "npm available"            npm --version
check "yarn available"           yarn --version
check "pnpm available"           pnpm --version

# ── Flutter ──
echo ""
echo "--- Flutter ---"
check "flutter available"        flutter --version
check "dart available"           dart --version
check "FLUTTER_HOME set"        test -n "$FLUTTER_HOME"
check "FLUTTER_HOME exists"     test -d "$FLUTTER_HOME"

# ── Multi-user access (all tools accessible to any user) ──
echo ""
echo "--- Multi-user access ---"
check "Android SDK readable by dev"   su dev -c "test -r ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager"
check "Flutter SDK readable by dev"   su dev -c "test -r ${FLUTTER_HOME}/bin/flutter"
check "Gradle readable by dev"        su dev -c "test -r /opt/gradle/bin/gradle"
check "flutter runs as dev"           su dev -c "flutter --version"
check "dart runs as dev"              su dev -c "dart --version"

# ── Inherited from alpine-dev ──
echo ""
echo "--- Inherited tools ---"
check "gcc available"            gcc --version
check "cmake available"          cmake --version
check "make available"           make --version
check "python3 available"        python3 --version
check "git available"            git --version
check "dev user exists"          id dev

# ── Summary ──
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
