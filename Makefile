# Makefile for TrySpace GSW (YAMCS)
.PHONY: all build clean container runtime start stop shell test

# Variables
IMAGE_NAME := tryspace-gsw
CONTAINER_NAME := tryspace-gsw
BUILD_IMAGE_NAME ?= tryspace-lab

# Color output function
define print_message
	@printf "\033[$(1)m$(2)\033[0m\n"
endef

# Main targets
all: runtime ## Build and prepare GSW for runtime

build: ## Build GSW using Maven in container
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE_NAME) ./mvnw clean package -DskipTests

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
	docker rmi $(IMAGE_NAME):latest 2>/dev/null || true
	docker volume rm gsw-data 2>/dev/null || true
	@rm -rf src/main/yamcs/mdb/components 2>/dev/null || true

logs: ## Show GSW container logs
	docker logs -f $(CONTAINER_NAME)

runtime: copy-comp-gsw-files
	docker build -t $(IMAGE_NAME):latest -f Dockerfile --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) .

start: ## Start GSW container
	docker run --rm -it \
		--name $(CONTAINER_NAME) \
		--network host \
		-p 8090:8090 \
		-p 10015:10015/udp \
		-p 10025:10025/udp \
		-v gsw-data:/app/yamcs-data \
		$(IMAGE_NAME):latest

shell: ## Get shell access to running GSW container
	docker exec -it $(CONTAINER_NAME) /bin/bash

test: ## Run tests
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE_NAME) ./mvnw test

stop: ## Stop and remove GSW container
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true