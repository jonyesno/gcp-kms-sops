.PHONY: help fmt validate lint security check install-tools clean init init-providers plan apply bootstrap

TF ?= tofu

help:
	@echo "terraform/tofu makefile targets:"
	@echo ""
	@echo "using: $(TF)"
	@echo ""
	@echo "  make bootstrap      - run bootstrap.sh to set up gcp project"
	@echo "  make init           - initialize $(TF) with backend"
	@echo "  make init-providers - initialize providers only (no backend/credentials needed)"
	@echo "  make fmt            - format terraform files"
	@echo "  make validate       - validate terraform configuration"
	@echo "  make lint           - run tflint"
	@echo "  make security       - run trivy"
	@echo "  make check          - run all checks (fmt, validate, lint, security)"
	@echo "  make plan           - run $(TF) plan"
	@echo "  make apply          - run $(TF) apply"
	@echo "  make install-tools  - install tflint and trivy"
	@echo "  make clean          - clean terraform files"
	@echo ""
	@echo "override with: make TF=terraform <target>"

fmt:
	@echo "==> formatting terraform files..."
	$(TF) fmt -recursive

validate: fmt
	@echo "==> validating terraform configuration..."
	$(TF) validate

lint:
	@echo "==> running tflint..."

# notably can't do this on FreeBSD arm64
	@if [ ! -d .terraform/providers ]; then \
		echo "note: providers not initialized. some provider-specific checks will be skipped."; \
		echo "      run 'make init-providers' if your platform supports the google provider."; \
	fi
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init || true; \
		tflint; \
	else \
		echo "tflint not found"; \
		exit 1; \
	fi

security:
	@echo "==> running security checks..."
# GODEBUG fixes a Go issue on FreeBSD arm64
	@if command -v trivy >/dev/null 2>&1; then \
		GODEBUG=netdns=cgo trivy config . --severity HIGH,CRITICAL --tf-vars terraform.tfvars; \
	else \
		echo "trivy not found"; \
		exit 1; \
	fi

check: fmt lint security
	@echo ""
	@echo "==> all checks passed!"
	@echo ""
	@echo "note: skipping validate (requires backend access). run 'make validate' separately if needed."

bootstrap:
	@echo "==> running bootstrap script..."
	./bootstrap.sh

init:
	@echo "==> initializing $(TF)..."
# GODEBUG fixes a Go issue on FreeBSD arm64
	GODEBUG=netdns=cgo $(TF) init

init-providers:
	@echo "==> initializing $(TF) providers (no backend)..."
# GODEBUG fixes a Go issue on FreeBSD arm64
	GODEBUG=netdns=cgo $(TF) init -backend=false

plan: validate
	@echo "==> running $(TF) plan..."
	$(TF) plan

apply: validate
	@echo "==> running $(TF) apply..."
	$(TF) apply

clean:
	@echo "==> cleaning terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup
	@echo "==> cleaned!"
