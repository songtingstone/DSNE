SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

PWD := $(shell pwd)
TEST_FILTER ?= ""


first: help

.PHONY: clean
clean:  ## Clean build files
	@rm -rf build dist site htmlcov .pytest_cache .eggs
	@rm -f .coverage coverage.xml dsne/_generated_version.py
	@find . -type f -name '*.py[co]' -delete
	@find . -type d -name __pycache__ -exec rm -rf {} +
	@find . -type d -name .ipynb_checkpoints -exec rm -rf {} +


.PHONY: cleanall
cleanall: clean   ## Clean everything
	@rm -rf *.egg-info
	@rm *.so dsne/st_dsne.cpp


.PHONY: help
help:  ## Show this help menu
	@grep -E '^[0-9a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##"; OFS="\t\t"}; {printf "\033[36m%-30s\033[0m %s\n", $$1, ($$2==""?"":$$2)}'


# ------------------------------------------------------------------------------
# Package build, test and docs

.PHONY: env  ## Create dev environment
env:
	conda env create


.PHONY: develop
develop:  ## Install package for development
	python -m pip install --no-build-isolation -e .


.PHONY: build
build: package  ## Build everything


.PHONY: package
package:  ## Build Python package (sdist)
	python setup.py sdist

.PHONY: cleanpackage
cleanpackage: clean ## Build Python package (sdist)
	python setup.py -v install

.PHONY: debug
debug: cleanpackage ## Build Python package (sdist)
	python ./examples/unexact_simulation.py
.PHONY: stest
stest:  ## Run tests
	python ./examples/unexact_simulation.py > ./examples/data/output.txt

.PHONY: check
check:  ## Check linting
	@flake8 dsne
	@isort --check-only --diff --recursive --project dsne --section-default THIRDPARTY .
	@black --check .


.PHONY: fmt
fmt:  ## Format source
	@isort --recursive --project dsne --section-default THIRDPARTY .
	@black .


.PHONY: upload-pypi
upload-pypi:  ## Upload package to PyPI
	twine upload dist/*.tar.gz


.PHONY: upload-test
upload-test:  ## Upload package to test PyPI
	twine upload --repository test dist/*.tar.gz


.PHONY: test
test:  ## Run tests
	pytest -k $(TEST_FILTER)


.PHONY: report
report:  ## Generate coverage reports
	@coverage xml
	@coverage html

# ------------------------------------------------------------------------------
# Project specific

.PHONY: docker-img
docker-img:  ## Docker image for testing
	docker build -t dsne .


.PHONY: docker-run
docker-run:  ## Run docker container
	docker run -it -v $(PWD):/workdir dsne
