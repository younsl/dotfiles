BINARY    := statusbar
INSTALL   := ../statusbar-rs

.PHONY: build install clean test

build:
	cargo build --release

install: build
	cp target/release/$(BINARY) $(INSTALL)
	@ls -lh $(INSTALL)

clean:
	cargo clean

test:
	@HOME=$$(mktemp -d) target/release/$(BINARY) < testdata/statusline-input.json
