include app.ini

APPLICATION ?= $(shell basename $(CURDIR))
PACKAGE ?= $(APPLICATION)
VERSION     := $(shell git describe --tags --dirty --match="v*" 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null)
ifndef VERSION
VERSION     := latest
endif

YAML_DIR       ?= ./yaml
YAML_BUILD_DIR ?= ./.build_yaml
YAML_FILES     := $(shell find $(YAML_DIR) -name '*.yaml' | sed 's:$(YAML_DIR)/::g')

SRC_DIR     ?= ./app-src
ENV_FILE    := $(SRC_DIR)/env

BUILD_IMAGE ?= true
IMAGE_HUB   ?= registry.trt8.jus.br
IMAGE_NAME  ?= $(shell git remote -v | sed -ne '1 s:^origin.*gitlab\.trt8\.jus\.br[:/]\(.*\)\.git.*$$:\1:p')
ifndef IMAGE_NAME
$(error "IMAGE_NAME is undefined. Please define it on app.ini or clone a repo from gitlab.trt8.jus.br")
endif

DOCKER_IMAGE := $(IMAGE_HUB)/$(IMAGE_NAME):$(VERSION)

ifndef BUILD_ARGS
DOCKER_BUILD_ARGS := -t $(DOCKER_IMAGE)
else
DOCKER_BUILD_ARGS := --build-arg $(BUILD_ARGS) -t $(DOCKER_IMAGE)
endif


APPID := $(shell bash -c 'printf "%05d" $$RANDOM')-$(APPLICATION)

AVAILABLE_VARS := PACKAGE ENVIRONMENT DOCKER_IMAGE APPID APPLICATION
AVAILABLE_VARS += APP_BACKEND_PORT APP_ENDPOINT_URL APP_ENDPOINT_PATH

SHELL_EXPORT := $(foreach v,$(AVAILABLE_VARS),$(v)='$($(v))' )

# ---------------------------------------------------------------------------------------------------------------------
.PHONY: help compile image release docker-run image-start image-stop build-yaml deploy clean

help:
	@echo ''
	@echo 'Usage:'
	@echo '    make [TARGET TARGET ...]'
	@echo ''
	@echo 'TARGET can be:'
	@echo '    image       - generates the Docker image using a proper build command.'
	@echo '    release     - build and pushes the Docker image to specified registry.'
	@echo '    docker-run  - runs the generated Docker image (with RUN_FLAGS, if specified).'
	@echo '    image-start - starts the specified image in background (with RUN_FLAGS, if specified).'
	@echo '    image-stop  - stops the specified image previously started.'
	@echo '    build-yaml   - interpolates the variables of project in yaml files at their folder.'
	@echo '    deploy      - apply yaml files to deploy the system at the Kubernetes cluster.'
	@echo '    clean       - gets rid of generated and volatile files and resources.'
	@echo '    help        - this message.'

image:
ifeq ($(BUILD_IMAGE), true)
	@echo 'Building image $(DOCKER_IMAGE)'
	docker build $(DOCKER_BUILD_ARGS) $(SRC_DIR)
else
	@echo 'Using image $(DOCKER_IMAGE)'
endif

release: image
ifeq ($(BUILD_IMAGE), true)
	docker push "$(DOCKER_IMAGE)"
endif

docker-run: image
	@test -f $(ENV_FILE) \
	&& docker run --rm --name $(APPLICATION)-container $(RUN_FLAGS) --env-file=$(ENV_FILE) $(DOCKER_IMAGE) \
	|| docker run --rm --name $(APPLICATION)-container $(RUN_FLAGS) $(DOCKER_IMAGE)

image-start: image
	@test -f $(ENV_FILE) \
	&& docker run -d --name $(APPLICATION)-container $(RUN_FLAGS) --env-file=$(ENV_FILE) $(DOCKER_IMAGE) \
	|| docker run -d --name $(APPLICATION)-container $(RUN_FLAGS) $(DOCKER_IMAGE)

image-stop: image
	docker stop -t 1 $(APPLICATION)


# Build the Kubernetes build directory if it does not exist
# The @ symbol prevents make from echoing command results.
$(YAML_BUILD_DIR):
	@mkdir -p $(YAML_BUILD_DIR)

build-yaml: $(YAML_BUILD_DIR)
	@echo "YAML files support the following vars: $(AVAILABLE_VARS)"
	@for file in $(YAML_FILES); do \
		mkdir -p `dirname "$(YAML_BUILD_DIR)/$$file"` ; \
		$(SHELL_EXPORT) envsubst <$(YAML_DIR)/$$file >$(YAML_BUILD_DIR)/$$file ;\
	done 
	@test -f $(ENV_FILE) \
	&& @echo "Found $(ENV_FILE) file. ConfigMap $(APPLICATION)-config will be created" \
	&& kubectl create configmap $(APPLICATION)-config -n $(PACKAGE) --from-env-file=$(ENV_FILE)
endif

deploy: build-yaml
	kubectl apply -f $(YAML_BUILD_DIR)

clean:
	@docker rmi -f $(DOCKER_IMAGE) 2>/dev/null
	@rm -rf $(YAML_BUILD_DIR)
