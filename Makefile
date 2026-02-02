SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:

ROOT := $(CURDIR)
PY := python3
VENV := $(ROOT)/.venv
VENV_BIN := $(VENV)/bin

VENV_PY := $(if $(wildcard $(VENV_BIN)/python),$(VENV_BIN)/python,$(PY))
RUFF := $(if $(wildcard $(VENV_BIN)/ruff),$(VENV_BIN)/ruff,ruff)
MYPY := $(if $(wildcard $(VENV_BIN)/mypy),$(VENV_BIN)/mypy,mypy)
PYTEST := $(if $(wildcard $(VENV_BIN)/pytest),$(VENV_BIN)/pytest,pytest)
PIP_AUDIT := $(if $(wildcard $(VENV_BIN)/pip-audit),$(VENV_BIN)/pip-audit,pip-audit)

.DEFAULT_GOAL := help

.PHONY: help bootstrap format lint typecheck test verify audit shellcheck clean demo

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: ## Create venv and install tools/ in editable mode (dev extras)
	$(PY) -m venv $(VENV)
	$(VENV_BIN)/python -m pip install -U pip
	$(VENV_BIN)/python -m pip install -e tools[dev]
	@echo "Done. Activate with: . $(VENV)/bin/activate"

format: ## Format Python (tools/) with Ruff
	cd tools
	$(RUFF) format .

lint: ## Lint Python (tools/) with Ruff
	cd tools
	$(RUFF) check .

typecheck: ## Typecheck Python (tools/) with MyPy
	cd tools
	$(MYPY) .

test: ## Run tests (tools/) with PyTest
	cd tools
	$(PYTEST) -q

verify: ## Run format check + lint + typecheck + tests (tools/)
	cd tools
	$(RUFF) format --check .
	$(RUFF) check .
	$(MYPY) .
	$(PYTEST) -q

demo: ## Replay sample alerts through the enrichment pipeline (no VMs needed)
	cd tools
	$(VENV_PY) demo_enrich.py

audit: ## Run pip-audit to check for known dependency vulnerabilities
	$(PIP_AUDIT)

shellcheck: ## Run shellcheck on all shell scripts (matches CI)
	shellcheck scripts/*.sh

clean: ## Remove local venv and common Python caches
	rm -rf $(VENV) \
		__pycache__ \
		.pytest_cache \
		.mypy_cache \
		.ruff_cache \
		tools/__pycache__ \
		tools/tests/__pycache__ \
		tools/.pytest_cache \
		tools/.mypy_cache \
		tools/.ruff_cache
