.PHONY: help
help:  ## display help text
	@grep -E '^[-a-zA-Z_/\%]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'

######################
# detect podman installed
# simple test: if podman is installed, use podman to build images

_IMAGECMD=podman
ifeq (, $(shell /usr/bin/which podman))
	_IMAGECMD=docker
endif

######################
# docker operations

IMAGES=fb-kpimon-xapp fb-ah-xapp ah-eson-test-server

define IMAGE_HELP

Build xApp images.

Usage: make image/<app_name>
       Apps: ${IMAGES}

       or: image/all to make all images

endef
export IMAGE_HELP

SM_TMP ?= ${TMPDIR}/onos-ric-python-apps-sync-sm

.PHONY: get-bindings
get-bindings: ## clone onos-e2-sm repo and prepare python bindings for use
	if [ ! -d "onos_e2_sm" ]; then \
		rm -rf ${SM_TMP}; \
		git clone --depth 1 git@github.com:onosproject/onos-e2-sm.git ${SM_TMP}; \
		cp -v -r ${SM_TMP}/python onos_e2_sm; \
	fi

.PHONY: image
image: ## Build xApp docker image
	@echo "$$IMAGE_HELP"

image/%: get-bindings
	if [ "all" = "$*" ]; then exit 0; fi; \
	$(_IMAGECMD) build --tag $*:latest -f $*/Dockerfile .;

_IMAGES=$(patsubst %,image/%,$(IMAGES))
image/all: $(_IMAGES)
images: $(_IMAGES)

build-tools: # @HELP install the ONOS build tools if needed
	@if [ ! -d "../build-tools" ]; then cd .. && git clone https://github.com/onosproject/build-tools.git; fi

publish: # @HELP publish version on github and dockerhub
	if ! grep dev VERSION.fb-ah-xapp; then ./../build-tools/publish-version fb-ah-xapp/${VERSION} onosproject/fb-ah-xapp; fi
	if ! grep dev VERSION.ah-eson-test-server; then ./../build-tools/publish-version ah-eson-test-server/${VERSION} onosproject/ah-eson-test-server; fi
	if ! grep dev VERSION.fb-kpimon-xapp; then ./../build-tools/publish-version fb-kpimon-xapp/${VERSION} onosproject/fb-kpimon-xapp; fi

jenkins-publish: build-tools # @HELP Jenkins calls this to publish artifacts
	./build/bin/push-images
	VERSIONFILE=VERSION.fb-ah-xapp ../build-tools/release-merge-commit
	VERSIONFILE=VERSION.ah-eson-test-server ../build-tools/release-merge-commit
	VERSIONFILE=VERSION.fb-kpimon-xapp ../build-tools/release-merge-commit

jenkins-test:  # @HELP run the unit tests and source code validation producing a junit style report for Jenkins
jenkins-test: build-tools

test: build-tools
