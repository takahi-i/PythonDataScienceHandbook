.PHONY: clean clean-model clean-pyc docs help init init-data init-docker create-container start-container jupyter test lint profile clean clean-data clean-docker clean-container clean-image
.DEFAULT_GOAL := help

###########################################################################################################
## SCRIPTS
###########################################################################################################

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
        match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
        if match:
                target, help = match.groups()
                print("%-20s %s" % (target, help))
endef

define START_DOCKER_CONTAINER
if [ `$(DOCKER) inspect -f {{.State.Running}} $(CONTAINER_NAME)` = "false" ] ; then
        $(DOCKER) start $(CONTAINER_NAME)
fi
endef

###########################################################################################################
## VARIABLES
###########################################################################################################


export DOCKER=docker
export PRINT_HELP_PYSCRIPT
export START_DOCKER_CONTAINER
export PYTHONPATH=$PYTHONPATH:$(PWD)
export PROJECT_NAME=pythondatasciencehandbook
export IMAGE_NAME=$(PROJECT_NAME)-image
export CONTAINER_NAME=$(PROJECT_NAME)-container
export DATA=Please Input data source in S3
export JUPYTER_HOST_PORT=7777
export JUPYTER_CONTAINER_PORT=8888
export PYTHON=python3
export DOCKERFILE=docker/Dockerfile

###########################################################################################################
## ADD TARGETS FOR YOUR TASK
###########################################################################################################


###########################################################################################################
## GENERAL TARGETS
###########################################################################################################

help:
	@$(PYTHON) -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

init: init-docker init-data ## initialize repository for traning

init-data: ## download data
	-aws s3 sync $(DATA) ./data/

init-docker: ## initialize docker image
	$(DOCKER) build -t $(IMAGE_NAME) -f $(DOCKERFILE) .


create-container: ## create docker container
	$(DOCKER) run -it -v $(PWD):/work -p $(JUPYTER_HOST_PORT):$(JUPYTER_CONTAINER_PORT) --name $(CONTAINER_NAME) $(IMAGE_NAME)

start-container: ## start docker container
	@echo "$$START_DOCKER_CONTAINER" | $(SHELL)
	@echo "Launched $(CONTAINER_NAME)..."
	$(DOCKER) attach $(CONTAINER_NAME)

jupyter: ## start Jupyter Notebook server
	jupyter-notebook --ip=0.0.0.0 --port=${JUPYTER_CONTAINER_PORT}

test: ## run test cases in tests directory
	$(PYTHON) -m unittest discover

lint: ## check style with flake8
	flake8 pythondatasciencehandbook

profile: ## show profile of the project
	@echo "CONTAINER_NAME: $(CONTAINER_NAME)"
	@echo "IMAGE_NAME: $(IMAGE_NAME)"
	@echo "JUPYTER_PORT: `$(DOCKER) port $(CONTAINER_NAME)`"
	@echo "DATA: $(DATA)"

clean: clean-model clean-pyc clean-docker ## remove all artifacts

clean-model: ## remove model artifacts
	rm -fr model/*

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

distclean: clean clean-data ## remove all the reproducible resources including Docker images

clean-data: ## remove files under data
	rm -fr data/*

clean-docker: clean-container clean-image ## remove Docker image and container

clean-container: ## remove Docker container
	-$(DOCKER) rm $(CONTAINER_NAME)

clean-image: ## remove Docker image
	-$(DOCKER) image rm $(IMAGE_NAME)
