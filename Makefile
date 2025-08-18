# Makefile for TrySpace GSW (YAMCS)
.PHONY: all build clean container runtime start stop shell test

# Variables
export BUILD_IMAGE ?= tryspaceorg/tryspace-lab:0.0.0
export RUNTIME_GSW ?= tryspace-gsw

# Color output function
define print_message
	@printf "\033[$(1)m$(2)\033[0m\n"
endef

# Main targets
all: runtime ## Build and prepare GSW for runtime

build: ## Build GSW using Maven in container
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE) ./mvnw clean package -DskipTests

copy-comp-gsw-files: ## Copy component GSW files to mdb directory
	@mkdir -p src/main/yamcs/mdb/components
	@rm -rf src/main/yamcs/mdb/components/*
	@for comp_dir in ../comp/*/gsw; do \
		if [ -d "$$comp_dir" ]; then \
			comp_name=$$(basename $$(dirname "$$comp_dir")); \
			mkdir -p "src/main/yamcs/mdb/components/$$comp_name"; \
			cp -f "$$comp_dir"/* "src/main/yamcs/mdb/components/$$comp_name/" 2>/dev/null || true; \
		fi; \
	done

clean: stop ## Clean up GSW build artifacts and containers
	./mvnw clean 2>/dev/null || true
	docker rmi $(RUNTIME_GSW):latest 2>/dev/null || true
	docker volume rm gsw-data 2>/dev/null || true
	@rm -rf src/main/yamcs/mdb/components 2>/dev/null || true

logs: ## Show GSW container logs
	docker logs -f $(RUNTIME_GSW)

runtime: copy-comp-gsw-files
	docker build -t $(RUNTIME_GSW):latest -f Dockerfile --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) .

start: ## Start GSW container
	docker run --rm -it \
		--name $(RUNTIME_GSW) \
		--network host \
		-p 8090:8090 \
		-v gsw-data:/app/yamcs-data \
		$(RUNTIME_GSW):latest

shell: ## Get shell access to running GSW container
	docker exec -it $(RUNTIME_GSW) /bin/bash

test: ## Run tests
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE) ./mvnw test

stop: ## Stop and remove GSW container
	docker stop $(RUNTIME_GSW) 2>/dev/null || true
	docker rm $(RUNTIME_GSW) 2>/dev/null || true