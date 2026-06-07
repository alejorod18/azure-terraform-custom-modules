.PHONY: validate fmt lint docs clean help

MODULES := $(wildcard module-*)

## help: Show this help message
help:
	@echo ""
	@echo "Azure Terraform Custom Modules"
	@echo "=============================="
	@echo ""
	@echo "Available targets:"
	@echo ""
	@grep -E '^## ' Makefile | sed 's/## /  /'
	@echo ""

## validate: Run terraform validate on all modules
validate:
	@echo "🔍 Validating all modules..."
	@for dir in $(MODULES); do \
		echo "  → $$dir"; \
		cd $$dir && terraform init -backend=false -input=false > /dev/null 2>&1 && \
		terraform validate && cd .. || (echo "  ✗ FAILED: $$dir" && cd .. && exit 1); \
	done
	@echo "✅ All modules validated successfully!"

## fmt: Format all Terraform files
fmt:
	@echo "📐 Formatting all Terraform files..."
	@terraform fmt -recursive .
	@echo "✅ Done!"

## fmt-check: Check formatting without modifying files
fmt-check:
	@echo "📐 Checking Terraform formatting..."
	@terraform fmt -recursive -check . || (echo "✗ Formatting issues found. Run 'make fmt' to fix." && exit 1)
	@echo "✅ All files properly formatted!"

## lint: Run fmt-check + validate
lint: fmt-check validate

## clean: Remove .terraform directories and lock files
clean:
	@echo "🧹 Cleaning generated files..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -name "*.tfstate" -delete 2>/dev/null || true
	@find . -name "*.tfstate.*" -delete 2>/dev/null || true
	@echo "✅ Clean complete!"

## tree: Show the module structure
tree:
	@for dir in $(MODULES); do \
		echo ""; \
		echo "📦 $$dir/"; \
		find $$dir -type f -not -path '*/\.*' | sort | sed 's|^|  |'; \
	done
