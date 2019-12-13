include app.ini

PACKAGE     ?= $(shell basename $(CURDIR))
APPLICATION ?= $(PACKAGE)
VERSION     := $(shell git describe --tags --dirty --match="v*" 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null)
ifndef VERSION
VERSION     := latest
endif

K8S_DIR       ?= ./yaml
K8S_BUILD_DIR ?= ./.build_yaml
K8S_FILES     := $(shell find $(K8S_DIR) -name '*.yaml' | sed 's:$(K8S_DIR)/::g')

SRC_DIR     ?= ./app-src
ENV_FILE    := $(SRC_DIR)/env

IMAGE_HUB   ?= registry.trt8.jus.br
BUILD_IMAGE ?= true

ifndef IMAGE_REPO
	$(error IMAGE_REPO is undefined)
endif
ifndef IMAGE_NAME
	$(error IMAGE_NAME is undefined)
endif

DOCKER_IMAGE := $(IMAGE_HUB)/$(IMAGE_REPO)/$(IMAGE_NAME):$(VERSION)

ifdef BUILD_ARGS
DOCKER_BUILD_CMD := docker build --build-arg $(BUILD_ARGS) -t $(DOCKER_IMAGE) $(SRC_DIR)
else
DOCKER_BUILD_CMD := docker build -t $(DOCKER_IMAGE) $(SRC_DIR)
endif

ifdef RUN_FLAGS
DOCKER_RUN_CMD := docker run --rm --name $(PACKAGE)-$(APPLICATION) $(RUN_FLAGS) $(DOCKER_IMAGE)
else
DOCKER_RUN_CMD := docker run --rm --name $(PACKAGE)-$(APPLICATION) $(DOCKER_IMAGE)
endif

APPID := $(shell bash -c 'printf "%05d" $$RANDOM')-$(APPLICATION)

MAKE_ENV := PACKAGE ENVIRONMENT VERSION DOCKER_IMAGE APPID APPLICATION
MAKE_ENV += APP_BACKEND_PORT APP_ENDPOINT_URL APP_ENDPOINT_PATH

SHELL_EXPORT := $(foreach v,$(MAKE_ENV),$(v)='$($(v))' )
#SHELL_EXPORT += $(foreach v,$(filter APPENV_%,$(.VARIABLES)),$(info $(subst APPENV_,,$(v))='$($(v))') )

#.DEFAULT_GOAL := all

.PHONY: help compile image release docker-run image-start image-stop build-k8s deploy clean

help:
	@echo ''
	@echo 'Usage:'
	@echo '    make [TARGET TARGET ...]'
	@echo ''
	@echo 'TARGET can be:'
	@echo '    all         - all you need to know do get your app deployed.'
	@echo '    image       - generates the Docker image using a proper build command.'
	@echo '    release     - build and pushes the Docker image to specified registry.'
	@echo '    docker-run  - simply runs the specified generated Docker image.'
	@echo '    image-start - starts the specified image in background, useful for testing images'
	@echo '                  containing daemons of servers or something alike.'
	@echo '    image-stop  - stops the specified image previously started.'
	@echo '    build-k8s   - interpolates the variables of project in yaml files at k8s folder.'
	@echo '    deploy      - apply yaml files to deploy the system at the Kubernetes cluster.'
	@echo '    clean       - gets rid of generated and volatile files and resources.'
	@echo '    help        - this message.'

image:
ifeq ($(BUILD_IMAGE), true)
	@echo 'Building image $(DOCKER_IMAGE)'
	$(DOCKER_BUILD_CMD)
else
	@echo 'Using image $(DOCKER_IMAGE)'
endif


release: image
ifeq ($(BUILD_IMAGE), true)
	docker push "$(DOCKER_IMAGE)"
endif


docker-run: image
ifdef RUN_FLAGS
	docker run --rm --name $(PACKAGE)-$(APPLICATION) $(RUN_FLAGS) $(DOCKER_IMAGE)
else
	docker run --rm --name $(PACKAGE)-$(APPLICATION) $(DOCKER_IMAGE)
endif


image-start: image
ifdef RUN_FLAGS
	docker run -d --name $(PACKAGE)-$(APPLICATION) $(RUN_FLAGS) $(DOCKER_IMAGE)
else
	docker run -d --name $(PACKAGE)-$(APPLICATION) $(DOCKER_IMAGE)
endif



image-stop: image
	docker stop -t 1 $(PACKAGE)-$(APPLICATION)
	docker rm -f $(PACKAGE)-$(APPLICATION)


# Build the Kubernetes build directory if it does not exist
# The @ symbol prevents make from echoing command results.
$(K8S_BUILD_DIR):
	@mkdir -p $(K8S_BUILD_DIR)

build-k8s: $(K8S_BUILD_DIR)
	# yaml files support the following vars: $(MAKE_ENV)
	@for file in $(K8S_FILES); do \
		mkdir -p `dirname "$(K8S_BUILD_DIR)/$$file"` ; \
		$(SHELL_EXPORT) envsubst <$(K8S_DIR)/$$file >$(K8S_BUILD_DIR)/$$file ;\
	done
ifeq (,$(wildcard $(ENV_FILE)))
	@echo "Found $(ENV_FILE) file. ConfigMap $(APPLICATION)-config will be created"
	kubectl create configmap $(APPLICATION)-config -n $(PACKAGE) --from-env-file=$(ENV_FILE)
endif

deploy: build-k8s
	kubectl apply -f $(K8S_BUILD_DIR)

clean:
	@docker rmi -f $(DOCKER_IMAGE) 2>/dev/null
	@rm -rf $(K8S_BUILD_DIR)
	@rm -rf $(SRC_DIR)/bin
