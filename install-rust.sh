#!/bin/bash
export RUSTUP_HOME=/home/zb/.rustup
export CARGO_HOME=/home/zb/.cargo

cd /tmp
curl --proto '=https' --tlsv1.2 -sSf https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init -o rustup-init
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-toolchain stable

source "$HOME/.cargo/env"
rustc --version 