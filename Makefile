SHELL := /bin/bash
ENVS := dev staging prod

.PHONY: help bootstrap hub spokes spoke-% projects fmt validate clean

help: ## Show this help
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Apply bootstrap layer (state backend)
	cd 00-bootstrap && terraform init && terraform apply

hub: ## Apply hub layer (shared services)
	cd 01-hub && terraform init && terraform apply

spoke-%: ## Apply a spoke environment (e.g., make spoke-dev)
	cd 02-spokes && terraform init -reconfigure -backend-config="key=spokes/$*/terraform.tfstate" && terraform apply -var-file=envs/$*.tfvars

spokes: $(addprefix spoke-,$(ENVS)) ## Apply all spoke environments

projects: ## Apply project factory (provisions all team projects from YAML requests)
	cd 03-projects && terraform init && terraform apply

fmt: ## Format all Terraform files
	terraform fmt -recursive

validate: ## Validate all layers
	@for dir in 00-bootstrap 01-hub 02-spokes 03-projects; do \
		echo "==> Validating $$dir"; \
		cd $$dir && terraform init -backend=false && terraform validate && cd ..; \
	done

clean: ## Remove .terraform directories
	find . -type d -name ".terraform" -exec rm -rf {} +
