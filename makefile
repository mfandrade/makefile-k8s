# v2.1.1
ifeq (,$(wildcard ./app.ini))
$(error "The file app.ini was not found.  Please create it in the project root folder.")
else
include app.ini
endif

ifeq ($(strip $(ENVIRONMENT)),)
$(error "The ENVIRONMENT variable is undefined.  Please, define its value in app.ini file.")
endif
APPLICATION ?= $(shell basename $(CURDIR))
NAMESPACE   ?= $(APPLICATION)
PACKAGE     := $(NAMESPACE)
ifeq (,$(wildcard ./.git))
$(error "This project is still not version controlled.  Please initialize a git repo and add a remote to it.")
endif

VERSION     := $(shell git describe --tags --dirty --match="v*" 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null)
ifndef VERSION
VERSION     := latest
endif

YAML_DIR       ?= ./yaml
YAML_BUILD_DIR := ./.build_yaml
YAML_FILES     := $(shell find $(YAML_DIR) -name '*.yaml' 2>/dev/null | sed 's:$(YAML_DIR)/::g')

DOCKER_CONTEXT := .
SRC_DIR        := $(DOCKER_CONTEXT)/src
ENV_FILE       := $(SRC_DIR)/env
DOCKERFILE     := $(SRC_DIR)/Dockerfile

ENV_FLAGS := -e APPLICATION=$(APPLICATION) -e ENVIRONMENT=$(ENVIRONMENT)
ifneq (,$(wildcard $(ENV_FILE)))
	ENV_FLAGS += --env-file=$(ENV_FILE)
endif

K8S_DEPLOY  ?= false
BUILD_IMAGE ?= true
IMAGE_HUB   ?= registry.trt8.jus.br
IMAGE_NAME  ?= $(shell git remote -v | sed -ne '1 s:^origin.*gitlab\.trt8\.jus\.br[:/]\(.*\)\.git.*$$:\1:p')
ifeq ($(strip $(IMAGE_NAME)),)
$(error "The IMAGE_NAME is undefined.  Please, define it on app.ini or clone a repo from gitlab.trt8.jus.br.")
endif

DOCKER_IMAGE := $(IMAGE_HUB)/$(IMAGE_NAME):$(VERSION)

ifndef BUILD_ARGS
DOCKER_BUILD_ARGS := -t $(DOCKER_IMAGE)
else
DOCKER_BUILD_ARGS := $(shell echo ' $(BUILD_ARGS)' | sed 's:\ : --build-arg :g') -t $(DOCKER_IMAGE)
endif


APPID := $(shell bash -c 'printf "%05d" $$RANDOM')-$(APPLICATION)

AVAILABLE_VARS := PACKAGE APPLICATION ENVIRONMENT DOCKER_IMAGE APPID
AVAILABLE_VARS += APP_BACKEND_PORT APP_ENDPOINT_URL APP_ENDPOINT_PATH

SHELL_EXPORT := $(foreach v,$(AVAILABLE_VARS),$(v)='$($(v))' )

# ---------------------------------------------------------------------------------------------------------------------
.PHONY: help image release docker-run image-start image-stop build-yaml deploy clean

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
	@echo '    build-yaml  - interpolates the variables of project in yaml files at their folder.'
	@echo '    deploy      - apply yaml files to deploy the system at the Kubernetes cluster.'
	@echo '    clean       - gets rid of generated and volatile files and resources.'
	@echo '    help        - this message.'

image:
ifeq ($(BUILD_IMAGE), true)
	@echo 'Building image $(DOCKER_IMAGE)'
	docker build -f $(DOCKERFILE) $(DOCKER_BUILD_ARGS) $(DOCKER_CONTEXT)
else
	@echo 'Using image $(DOCKER_IMAGE)'
endif

release: image
ifeq ($(BUILD_IMAGE), true)
	docker push $(DOCKER_IMAGE)
endif

docker-run: image
	docker run --rm --name $(APPLICATION)-container $(ENV_FLAGS) $(RUN_FLAGS) $(DOCKER_IMAGE)

image-start: image
	docker run -d -t --name $(APPLICATION)-container $(ENV_FLAGS) $(RUN_FLAGS) $(DOCKER_IMAGE)

image-stop: image
	docker stop -t 1 $(APPLICATION)-container


# Create the yaml build directory if it does not exist
$(YAML_BUILD_DIR):
	@mkdir -p $(YAML_BUILD_DIR)

build-yaml: $(YAML_BUILD_DIR)
	@echo 'YAML files support the following vars: $(AVAILABLE_VARS)'
	@for file in $(YAML_FILES); do \
		mkdir -p `dirname "$(YAML_BUILD_DIR)/$$file"` ; \
		$(SHELL_EXPORT) envsubst <$(YAML_DIR)/$$file >$(YAML_BUILD_DIR)/$$file ;\
	done

deploy: build-yaml
ifeq ($(K8S_DEPLOY), true)
	kubectx cluster-$(ENVIRONMENT)

ifneq (,$(wildcard $(ENV_FILE)))
	kubectl create configmap $(APPLICATION)-config -n $(PACKAGE) --from-env-file=$(ENV_FILE) -o yaml --dry-run \
	| kubectl apply -f -
endif
	kubectl apply -f $(YAML_BUILD_DIR)
else
	$(error '(K8S_DEPLOY=false) Configured to not deploy to Kubernetes.  Skipping.')
endif

clean:
	docker container rm -f $(APPLICATION)-container 2>/dev/null || true
	docker image rm -f $(DOCKER_IMAGE) 2>/dev/null || true
	docker system prune -f 2>/dev/null || true
	rm -rf $(YAML_BUILD_DIR)
