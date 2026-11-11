.PHONY: build test lint nix-build

build:
	cargo build --release

test:
	cargo test

lint:
	cargo fmt --check
	cargo clippy --all-targets -- -D warnings

nix-build:
	nix build ../../..#kavd-watchdog
