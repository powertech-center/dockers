#!/bin/sh
# alpine-rust.sh — Rust toolchain installation
# Used by: alpine-rust, alpine-cross-rust

set -e

# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable

# Reload PATH so cargo/rustup are available
export PATH="/root/.cargo/bin:${PATH}"

rustup component add rustfmt clippy

cargo install cargo-audit --locked
