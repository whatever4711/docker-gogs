ARCHITECTURES = amd64 i386 arm32v6 arm64v8
VERSION = $(shell cat gogs/templates/.VERSION)
QEMU_VERSION = v4.2.0-6
BINFMT = a7996909642ee92942dcd6cff44b9b95f08dad64
#DOCKER_USER = test
#DOCKER_PASS = test
ifeq ($(REPO),)
  REPO = gogs
endif
ifeq ($(CIRCLE_TAG),)
	TAG = latest
else
	TAG = $(CIRCLE_TAG)
endif

init:
	@docker run --rm --privileged docker/binfmt:$(BINFMT)
	@docker buildx create --name gogs_builder
	@docker buildx use gogs_builder
	@docker buildx inspect --bootstrap

clean:
	@docker buildx rm gogs_builder

all:
	@docker buildx build \
			--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
			--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
			--build-arg VCS_URL=$(shell git config --get remote.origin.url) \
			--build-arg VERSION=$(VERSION) \
			--platform linux/amd64,linux/arm64,linux/arm/v7,linux/i386 \
			-t $(REPO):$(TAG) .

push:
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	@$(foreach arch,$(ARCHITECTURES), docker push $(REPO):linux-$(arch)-$(TAG);)
	@docker logout
