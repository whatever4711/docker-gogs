ARCHITECTURES = amd64 i386 arm32v6 arm64v8
QEMU_STATIC = https://github.com/multiarch/qemu-user-static/releases/download/v2.11.0
IMAGE = golang:alpine
IMAGE2 = alpine
MULTIARCH = multiarch/qemu-user-static:register
TMP_DIR = tmp
TMP_DOCKERFILE = Dockerfile.generated
VERSION = $(shell cat gogs/templates/.VERSION)
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

all: $(ARCHITECTURES)

$(ARCHITECTURES):
	@mkdir -p $(TMP_DIR)
	@curl -L -o $(TMP_DIR)/qemu-$@-static.tar.gz $(QEMU_STATIC)/qemu-$(strip $(call qemuarch,$@))-static.tar.gz
	@tar xzf $(TMP_DIR)/qemu-$@-static.tar.gz -C $(TMP_DIR)
	@sed    -e "s|<IMAGE>|$@/$(IMAGE)|g" \
	        -e "s|<IMAGE2>|$@/$(IMAGE2)|g" \
		-e "s|<ARCH>|$@|g" \
		-e "s|<QEMU>|COPY $(TMP_DIR)/qemu-$(strip $(call qemuarch,$@))-static /usr/bin/qemu-$(strip $(call qemuarch,$@))-static|g" \
		-e "s|<GOARCH>|$(strip $(call goarch,$@))|g" \
		-e "s|<GOSUARCH>|$(strip $(call gosuarch,$@))|g" \
		Dockerfile.generic > $(TMP_DOCKERFILE)
	@sed -i -e "s|amd64/$(IMAGE)|$(IMAGE)|g" \
	        -e "s|amd64/$(IMAGE2)|$(IMAGE2)|g" $(TMP_DOCKERFILE)
	@docker run --rm --privileged $(MULTIARCH) --reset
	@docker build --build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
			--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
			--build-arg VCS_URL=$(shell git config --get remote.origin.url) \
			--build-arg VERSION=$(VERSION) \
			-f $(TMP_DOCKERFILE) -t $(REPO):linux-$@-$(TAG) .
	@rm -rf $(TMP_DIR) $(TMP_DOCKERFILE)

push:
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	@$(foreach arch,$(ARCHITECTURES), docker push $(REPO):linux-$(arch)-$(TAG);)
	@docker logout

manifest:
	@wget -O docker https://6582-88013053-gh.circle-artifacts.com/1/work/build/docker-linux-amd64
	@chmod +x docker
	@./docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	@./docker manifest create $(REPO):$(TAG) $(foreach arch,$(ARCHITECTURES), $(REPO):linux-$(arch)-$(TAG)) --amend
	@$(foreach arch,$(ARCHITECTURES), ./docker manifest annotate $(REPO):$(TAG) $(REPO):linux-$(arch)-$(TAG) --os linux $(strip $(call convert_variants,$(arch)));)
	@./docker manifest push $(REPO):$(TAG)
	@./docker logout
	@rm -f docker

clean:
	@rm -rf $(TMP_DIR) $(TMP_DOCKERFILE)

# Needed convertions for different architecture naming schemes
# Convert qemu archs to naming scheme of https://github.com/multiarch/qemu-user-static/releases
define qemuarch
	$(shell echo $(1) | sed -e "s|arm32.*|arm|g" -e "s|arm64.*|aarch64|g" -e "s|amd64|x86_64|g")
endef
# Convert GOARCH to naming scheme of https://gist.github.com/asukakenji/f15ba7e588ac42795f421b48b8aede63
define goarch
	$(shell echo $(1) | sed -e "s|arm32.*|arm|g" -e "s|arm64.*|arm64|g" -e "s|i386|386|g" )
endef
# Convert gosu archs to naming scheme of https://github.com/tianon/gosu/releases
define gosuarch
	$(shell echo $(1) | sed -e "s|arm32.*|armhf|g" -e "s|arm64.*|arm64|g" )
endef
# Convert Docker manifest entries according to https://docs.docker.com/registry/spec/manifest-v2-2/#manifest-list-field-descriptions
define convert_variants
	$(shell echo $(1) | sed -e "s|amd64|--arch amd64|g" -e "s|i386|--arch 386|g" -e "s|arm32v5|--arch arm --variant v5|g" -e "s|arm32v6|--arch arm --variant v6|g" -e "s|arm32v7|--arch arm --variant v7|g" -e "s|arm64v8|--arch arm64 --variant v8|g" -e "s|ppc64le|--arch ppc64le|g" -e "s|s390x|--arch s390x|g")
endef
