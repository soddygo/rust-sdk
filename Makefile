# Makefile — publish rmcp-soddygo crates to crates.io.
#
# rmcp-soddygo depends on rmcp-soddygo-macros, so the macros crate MUST be
# published first and its crates.io index propagated before the main crate.
# (crates.io rejects a crate that depends on a version not yet published.)
#
# Usage:
#   make publish           full release: macros -> wait -> main crate
#   make publish-macros    publish only rmcp-soddygo-macros
#   make publish-rmcp      publish only rmcp-soddygo (retry if it failed here)
#   make publish-check     dry-run, no upload
#
# Tunables (override on the command line):
#   CARGO_HTTP_TIMEOUT   cargo HTTP timeout in seconds    (default 120)
#   PROPAGATION_WAIT     seconds to wait after publishing  (default 10)
#                        macros, for index propagation
#
# Fail-fast: if macros fails to publish, the main crate is NOT published.
# If macros is already published and `make publish` stops there, run
# `make publish-rmcp` to publish only the main crate.

CARGO_HTTP_TIMEOUT ?= 120
PROPAGATION_WAIT   ?= 10
MACROS_CRATE        := rmcp-soddygo-macros
MAIN_CRATE          := rmcp-soddygo

.PHONY: help publish publish-macros publish-rmcp publish-check

help:
	@echo "rmcp-soddygo publish targets:"
	@echo "  make publish         full release (macros -> wait -> main)"
	@echo "  make publish-macros  publish only rmcp-soddygo-macros"
	@echo "  make publish-rmcp    publish only rmcp-soddygo"
	@echo "  make publish-check   dry-run, no upload"

publish: publish-macros publish-rmcp
	@echo "==> Done. $(MACROS_CRATE) and $(MAIN_CRATE) published to crates.io."

publish-macros:
	@echo "==> 1/2 Publishing $(MACROS_CRATE) ..."
	CARGO_HTTP_TIMEOUT=$(CARGO_HTTP_TIMEOUT) cargo publish -p $(MACROS_CRATE)
	@echo "==> Waiting $(PROPAGATION_WAIT)s for crates.io index propagation ..."
	@sleep $(PROPAGATION_WAIT)

publish-rmcp:
	@echo "==> 2/2 Publishing $(MAIN_CRATE) ..."
	CARGO_HTTP_TIMEOUT=$(CARGO_HTTP_TIMEOUT) cargo publish -p $(MAIN_CRATE)

publish-check:
	@echo "==> Dry-run $(MACROS_CRATE) ..."
	CARGO_HTTP_TIMEOUT=$(CARGO_HTTP_TIMEOUT) cargo publish -p $(MACROS_CRATE) --dry-run
	@echo "==> Dry-run $(MAIN_CRATE) (fails until $(MACROS_CRATE) is live) ..."
	CARGO_HTTP_TIMEOUT=$(CARGO_HTTP_TIMEOUT) cargo publish -p $(MAIN_CRATE) --dry-run
