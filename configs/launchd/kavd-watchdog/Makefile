.PHONY: build test lint install uninstall

build:
	cargo build --release

test:
	cargo test

lint:
	cargo fmt --check
	cargo clippy --all-targets -- -D warnings

install: build
	osascript -e 'do shell script "/bin/bash $(CURDIR)/install.sh" with administrator privileges'

uninstall:
	osascript -e 'do shell script "/bin/bash $(CURDIR)/install.sh --uninstall" with administrator privileges'
