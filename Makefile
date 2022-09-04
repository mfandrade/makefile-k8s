# AUTHOR: Marcelo F Andrade <mfandrade@gmail.com>
# LICENSE: The Beer-ware License
# (C) 2022 https://about.me/mfandrade

REGISTRY    ?=

BRANCH      := $(shell git branch --show-current)
ENVIRONMENT := $(BRANCH)
APPLICATION := $(shell basename $(CURDIR))
NAMESPACE   ?= default

IMAGE_NAME  ?= $(shell git remote -v | sed -ne '1 s:^origin.*github\.com[:/]\(.*\)\.git.*$$:\1:p')

VERSION := $(shell cat VERSION 2>/dev/null || git rev-parse --short HEAD)
VERSION := $(addsuffix $(shell test -n "`git status --short`" && echo '-WIP'), $(VERSION))
DOCKER_IMAGE := $(REGISTRY)$(IMAGE_NAME):$(VERSION)



######################################################################
.DEFAULT_GOAL:= help
.PHONY: yaml

app.ini: ##- Sets required parameters if they're not present.
	$(eval APPLICATION_URL  ?= myapp.example.com)
	$(eval APPLICATION_HOME ?= /)
	$(eval BACKEND_PORT     ?= 8080)
	$(shell touch app.ini && echo 'APPLICATION_URL  = $(APPLICATION_URL)' > app.ini)
	$(shell echo 'APPLICATION_HOME = $(APPLICATION_HOME)' >> app.ini)
	$(shell echo 'BACKEND_PORT     = $(BACKEND_PORT)' >> app.ini)
	$(shell echo >> app.ini)
	$(shell echo 'RUN_FLAGS        = -p 8080:8080' >> app.ini)
	$(shell echo '#ENV_FILE        = env.$$(BRANCH)' >> app.ini)
	$(error The app.ini file was created.  Please run this Makefile again..)
include app.ini



# DOCKER RELATED ####################################################
ifndef BUILD_ARGS
DOCKER_BUILD_ARGS := -t $(DOCKER_IMAGE)
else
DOCKER_BUILD_ARGS := $(shell echo ' $(BUILD_ARGS)' | sed 's:\ : --build-arg :g') -t $(DOCKER_IMAGE)
endif
DOCKERFILE  ?= Dockerfile

image: $(DOCKERFILE) ##- Builds image with BUILD_ARGS if specified.
	docker build -f $(DOCKERFILE) $(DOCKER_BUILD_ARGS) .
	@docker image prune -f >/dev/null

release: image ##- Publishes image to registry (needs previous authentication).
	$(eval LATEST := $(REGISTRY)$(IMAGE_NAME):latest)
	@$$(test -z "$$(git status --short)") && \
		docker tag $(DOCKER_IMAGE) $(LATEST) && \
		docker push $(DOCKER_IMAGE) && \
		docker push $(LATEST) || \
		echo 'This git repo is in dirty state.  Aborting release...'

ENV_FILE  ?= env
ENV_FLAGS := -e APPLICATION=$(APPLICATION) -e ENVIRONMENT=$(ENVIRONMENT)
ifneq (,$(wildcard $(ENV_FILE)))
        ENV_FLAGS += --env-file=$(ENV_FILE)
endif

run: image ##- Runs this image as a container with RUN_FLAGS if specified.
	docker container run --detach --rm --name $(APPLICATION)-container $(ENV_FLAGS) $(RUN_FLAGS) $(DOCKER_IMAGE)

shell: run ##- Gets to the container shell, if available.
	docker container exec --interactive --tty $(APPLICATION)-container /bin/sh
	@docker container rm --force $(APPLICATION)-container

clean: ##- Removes generated image and containers.
	@docker container rm -f $(APPLICATION)-container 2>/dev/null || true
	@docker image rm -f `docker image ls | grep $(IMAGE_NAME) | awk '{print $3}'` 2>/dev/null || true
	@rm -rf $(YAML_BUILD_DIR)


### YAML RELATED ####################################################
AVAILABLE_VARS := APPLICATION NAMESPACE ENVIRONMENT DOCKER_IMAGE
AVAILABLE_VARS += BACKEND_PORT APPLICATION_URL APPLICATION_HOME

SHELL_EXPORT := $(foreach v,$(AVAILABLE_VARS),$(v)='$(firstword $($(v)))' )

YAML_DIR       := yaml
YAML_BUILD_DIR := .build_yaml
YAML_FILES     := $(shell find $(YAML_DIR) -name '*.yaml' 2>/dev/null | sed 's:$(YAML_DIR)/::g')

$(YAML_BUILD_DIR): # creates yaml build dir
	@mkdir -p $(YAML_BUILD_DIR)

yaml: $(YAML_BUILD_DIR) app.ini ##- Interpolates vars in yaml files.
	@echo 'YAML available vars: $(AVAILABLE_VARS)'
	@for file in $(YAML_FILES); do \
		mkdir -p `dirname "$(YAML_BUILD_DIR)/$$file"` ; \
		$(SHELL_EXPORT) envsubst <$(YAML_DIR)/$$file >$(YAML_BUILD_DIR)/$$file ;\
	done


### KUBERNETES RELATED ###############################################
deploy: release yaml ##- Creates a deploy of the released image to context called ENVIRONMENT.
	kubectl config use-context $(ENVIRONMENT)
	kubectl create deploy $(APPLICATION) --replicas=2 --image=$(IMAGE_NAME) --namespace $(NAMESPACE)

undeploy: ##- Deletes the deploy.
	kubectl config use-context $(ENVIRONMENT)
	kubectl delete deploy $(APPLICATION) --namespace $(NAMESPACE)

######################################################################
help: ##- This message.
	@echo 'USAGE: make <TARGET> [VARNAME=value]'
	@echo
	@echo 'TARGET can be:'
	@sed -e '/#\{2\}-/!d; s/\\$$//; s/:[^#\t]*/\t- /; s/#\{2\}- *//' $(MAKEFILE_LIST)

