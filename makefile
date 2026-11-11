.DEFAULT_GOAL := setup
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TARGET ?= $(HOME)
WINDOWS_HOME ?= auto
BREWFILE ?= $(ROOT)/homebrew/Brewfile

.PHONY: all setup deps link check capture-windows delete add

all: setup

setup: deps
	$(MAKE) --file="$(ROOT)/makefile" link

deps:
	@formulas="$$(brew bundle list --formula --file="$(BREWFILE)")" || exit $$?; \
	for formula in $$formulas; do \
		case "$$formula" in \
			*/*/*) brew trust --formula "$$formula" || exit $$? ;; \
		esac; \
	done
	brew bundle install --no-upgrade --file="$(BREWFILE)"
	bun install --frozen-lockfile --cwd "$(ROOT)/omp/.omp/agent/extensions/delta-diffs"

link check capture-windows delete:
	python3 "$(ROOT)/scripts/setup.py" $@ --target "$(TARGET)" --windows-home "$(WINDOWS_HOME)"

add:
	"$(ROOT)/bin/add" $(ARGS)
