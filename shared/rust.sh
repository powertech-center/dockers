#!/bin/sh
# rust.sh — Rust toolchain installation
# Used by: rust, cross-rust
#
# Installs Rust to global paths (/opt/rust/rustup, /opt/rust/cargo)
# so the toolchain is available to all users, not just root.

set -e

export RUSTUP_HOME=/opt/rust/rustup
export CARGO_HOME=/opt/rust/cargo

# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable

# Reload PATH so cargo/rustup are available
export PATH="${CARGO_HOME}/bin:${PATH}"

rustup component add rustfmt clippy

cargo install cargo-audit --locked

# Make accessible to all users
chmod -R a+rX ${RUSTUP_HOME} ${CARGO_HOME}
chmod a+x ${CARGO_HOME}/bin/*
