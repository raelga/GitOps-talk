
#REGISTRY ?= eu.gcr.io/${GCP_PROJECT}
TAG ?= $(shell git rev-parse --verify --short HEAD)

DOCKERFILES = $(shell find * -type f -name Dockerfile)
IMAGES = $(subst /,\:,$(subst /Dockerfile,,$(DOCKERFILES)))

.PHONY: help

# Help

help:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null \
		| awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' \
		| egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | sort

$(addprefix docker-build-,$(IMAGES)): docker-build-%:
	test -d $*/context \
	&&	docker build -t $(REGISTRY)/$*:$(TAG) -f $*/Dockerfile $*/context \
	||	docker build -t $(REGISTRY)/$*:$(TAG) $*

$(addprefix docker-push-,$(IMAGES)): docker-push-%:
	docker push $(REGISTRY)/$*:$(TAG)

$(addprefix docker-tag-latest-,$(IMAGES)): docker-tag-latest-%:
	docker tag $(REGISTRY)/$*:$(TAG) $(REGISTRY)/$*:latest

$(addprefix docker-push-latest-,$(IMAGES)): docker-push-latest-%: docker-tag-latest-%
	docker push $(REGISTRY)/$*:latest

$(addprefix docker-run-,$(IMAGES)): docker-run-%:
	docker run -ti --rm $(REGISTRY)/$*:$(TAG) /bin/bash
