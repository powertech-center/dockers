# PowerTech Alpine Mobile
# Universal mobile development environment (Android, Flutter, React Native, KMP)
#
# Image: ghcr.io/powertech-center/alpine-mobile
#
# Key design decisions:
# - Android SDK tools are glibc-linked binaries; Alpine uses musl
# - gcompat + glibc dynamic linker provide the compatibility layer
# - JDK (latest LTS) from Alpine repos is musl-native (no shim needed)
# - Node.js from Alpine repos is musl-native
# - Flutter SDK requires glibc compat (Dart runtime is glibc-linked)
#
# iOS note: Full iOS development requires macOS (Xcode).
# For limited iOS cross-compilation from Linux, see: https://github.com/nicklama/xtool

FROM ghcr.io/powertech-center/alpine-dev:latest

# ── glibc compatibility layer ──────────────────────────────────────────────────
# Android SDK and Flutter/Dart binaries are linked against glibc.
# gcompat provides a musl-to-glibc translation shim, but the binaries also need
# the glibc dynamic linker (ld-linux-x86-64.so.2) to be present on disk.
RUN apk add --no-cache gcompat libstdc++ && \
    # Some Android SDK tools (e.g. aapt2) dlopen glibc's ld-linux directly.
    # The gcompat package provides /lib/ld-linux-x86-64.so.2 on recent Alpine,
    # but if missing we create a symlink to the gcompat loader.
    [ -f /lib/ld-linux-x86-64.so.2 ] || \
    ln -s /lib/ld-musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 2>/dev/null || true

# ── JDK (latest compatible LTS, musl-native, auto-detected) ──────────────────
# Max JDK version is determined from Gradle's compatibility page.
# From available Alpine packages, we pick the highest LTS that Gradle supports.
# Java LTS versions: 8, 11, 17, 21, 25, 29, 33, ...
RUN apk update && \
    MAX_JDK=$(wget -qO- "https://docs.gradle.org/current/userguide/compatibility.html" | \
        grep -oE 'between [0-9]+ and [0-9]+' | grep -oE '[0-9]+$') && \
    JDK_PKG=$(apk search openjdk | grep -E '^openjdk[0-9]+-jdk-' | \
        sed 's/-[0-9].*//' | while read pkg; do \
            ver=$(echo "$pkg" | grep -oP '\d+'); \
            if [ "$ver" -le "$MAX_JDK" ]; then \
                for lts in 8 11 17 21 25 29 33; do \
                    [ "$ver" = "$lts" ] && echo "$ver $pkg" && break; \
                done; \
            fi; \
        done | sort -n | tail -1 | awk '{print $2}') && \
    apk add --no-cache ${JDK_PKG} && \
    rm -rf /var/cache/apk/* && \
    JAVA_MAJOR=$(echo ${JDK_PKG} | grep -oP '\d+') && \
    ln -s /usr/lib/jvm/java-${JAVA_MAJOR}-openjdk /usr/lib/jvm/java-openjdk

ENV JAVA_HOME=/usr/lib/jvm/java-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ── Android SDK ────────────────────────────────────────────────────────────────
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Download cmdline-tools, install SDK components, and set ownership in one layer
# to avoid duplicating ~3 GB in a separate chown layer
RUN CMDLINE_URL=$(wget -qO- "https://developer.android.com/studio" | \
        grep -oP 'https://dl\.google\.com/android/repository/commandlinetools-linux-\d+_latest\.zip' | head -1) && \
    wget -q "${CMDLINE_URL}" -O /tmp/cmdline-tools.zip && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-tmp && \
    mv /tmp/cmdline-tools-tmp/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools-tmp && \
    # Accept licenses and install SDK components
    yes | sdkmanager --licenses > /dev/null 2>&1 && \
    PLATFORM_VERSION=$(sdkmanager --list 2>/dev/null | grep "platforms;android-" | \
        grep -v "\-ext" | tail -1 | awk '{print $1}') && \
    BUILD_TOOLS_VERSION=$(sdkmanager --list 2>/dev/null | grep "build-tools;" | \
        tail -1 | awk '{print $1}') && \
    NDK_VERSION=$(sdkmanager --list 2>/dev/null | grep "ndk;" | \
        tail -1 | awk '{print $1}') && \
    sdkmanager --install \
        "cmdline-tools;latest" \
        "${PLATFORM_VERSION}" \
        "${BUILD_TOOLS_VERSION}" \
        "platform-tools" \
        "${NDK_VERSION}" && \
    # Make SDK accessible to all users (root-owned, world-readable)
    chmod -R a+rX ${ANDROID_HOME}

# ── Gradle (latest stable, auto-detected) ─────────────────────────────────────
RUN GRADLE_VERSION=$(wget -qO- "https://services.gradle.org/versions/current" | jq -r '.version') && \
    wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -O /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && \
    mv /opt/gradle-${GRADLE_VERSION} /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip

ENV GRADLE_HOME=/opt/gradle

# ── Node.js LTS & package managers (musl-native) ──────────────────────────────
# For React Native, Expo, and general JS/TS mobile tooling
RUN apk add --no-cache nodejs npm && \
    npm install -g yarn pnpm

# ── Flutter SDK (latest stable, auto-detected) ────────────────────────────────
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# Install Flutter, precache artifacts, and make accessible to all users
RUN FLUTTER_VERSION=$(wget -qO- "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json" | \
        jq -r '.releases[] | select(.channel == "stable") | .version' | head -1) && \
    wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -O /tmp/flutter.tar.xz && \
    tar xf /tmp/flutter.tar.xz -C /opt && \
    rm /tmp/flutter.tar.xz && \
    git config --global --add safe.directory /opt/flutter && \
    flutter config --no-analytics && \
    dart --disable-analytics && \
    flutter precache --android && \
    chmod -R a+rX ${FLUTTER_HOME}

# Git safe directory for Flutter (needed when running as different user)
RUN git config --global --add safe.directory ${FLUTTER_HOME}

CMD ["/bin/sh"]
