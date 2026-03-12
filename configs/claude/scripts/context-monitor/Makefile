BINARY    := context-monitor
INSTALL   := ../context-monitor-rs

.PHONY: build install clean test

build:
	cargo build --release

install: build
	cp target/release/$(BINARY) $(INSTALL)
	@ls -lh $(INSTALL)

clean:
	cargo clean

test:
	@echo '{"model":{"display_name":"Claude Opus 4.6"},"workspace":{"current_dir":"/tmp/project","project_dir":"/tmp/project"},"cost":{"total_cost_usd":0.042,"total_duration_ms":180000,"total_lines_added":50,"total_lines_removed":10},"context_window":{"used_percentage":32.5}}' | target/release/$(BINARY)
