# Makefile for TrySpace GSW (YAMCS)
.PHONY: all build clean container runtime start stop shell test help

# Variables
IMAGE_NAME := tryspace-gsw
CONTAINER_NAME := tryspace-gsw
BUILD_IMAGE_NAME ?= tryspace-lab

# Color output function
define print_message
	@printf "\033[$(1)m$(2)\033[0m\n"
endef

.DEFAULT_GOAL := help

# Main targets
all: runtime ## Build and prepare GSW for runtime

runtime: container ## Build production container image
	$(call print_message,32,[GSW] Runtime container ready: $(IMAGE_NAME))

container: ## Build the GSW Docker container
	$(call print_message,36,[GSW] Building container: $(IMAGE_NAME))
	docker build -t $(IMAGE_NAME):latest -f Dockerfile --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) .
	$(call print_message,32,[GSW] Container built successfully)

build: ## Build GSW using Maven in container
	$(call print_message,36,[GSW] Building GSW application with Maven...)
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE_NAME) ./mvnw clean package -DskipTests
	$(call print_message,32,[GSW] Build completed successfully)

test: ## Run tests
	$(call print_message,36,[GSW] Running tests...)
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE_NAME) ./mvnw test

start: ## Start GSW container
	$(call print_message,36,[GSW] Starting $(CONTAINER_NAME)...)
	docker run -d \
		--name $(CONTAINER_NAME) \
		--network tryspace-net \
		-p 8090:8090 \
		-p 10015:10015/udp \
		-p 10025:10025/udp \
		-v gsw-data:/app/yamcs-data \
		--restart unless-stopped \
		$(IMAGE_NAME):latest

stop: ## Stop and remove GSW container
	$(call print_message,33,[GSW] Stopping $(CONTAINER_NAME)...)
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true

shell: ## Get shell access to running GSW container
	$(call print_message,36,[GSW] Opening shell in $(CONTAINER_NAME)...)
	docker exec -it $(CONTAINER_NAME) /bin/bash

logs: ## Show GSW container logs
	docker logs -f $(CONTAINER_NAME)

clean: stop ## Clean up GSW build artifacts and containers
	$(call print_message,33,[GSW] Cleaning up...)
	./mvnw clean 2>/dev/null || true
	docker rmi $(IMAGE_NAME):latest 2>/dev/null || true
	docker volume rm gsw-data 2>/dev/null || true
	$(call print_message,32,[GSW] Cleanup completed)

# Development targets using the docker subdirectory setup
dev-up: ## Start development environment using docker-compose
	$(call print_message,36,[GSW] Starting development environment...)
	cd docker && $(MAKE) yamcs-up

dev-down: ## Stop development environment
	$(call print_message,33,[GSW] Stopping development environment...)
	cd docker && $(MAKE) yamcs-down

dev-simulator: ## Run the YAMCS simulator for development
	$(call print_message,36,[GSW] Starting YAMCS simulator...)
	cd docker && $(MAKE) yamcs-simulator

dev-clean: ## Clean development environment
	cd docker && $(MAKE) clean

help: ## Display this help message
	@echo "TrySpace GSW (YAMCS) Makefile"
	@echo "=============================="
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m%-20s\033[0m %s\n", "Target", "Description"} /^[a-zA-Z_-]+:.*?##/ {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Production targets: runtime, start, stop, logs"
	@echo "Development targets: dev-up, dev-down, dev-simulator"