include hack/make-project-vars.mk
include hack/make-tools.mk
include hack/make-bundle-vars.mk


# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:

all: build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this help.
	@./hack/make-help.sh $(MAKEFILE_LIST)

##@ Development

manifests: controller-gen update-mgr-env ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
	$(CONTROLLER_GEN) $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases

generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

lint: ## Run golangci-lint against code.
	docker run --rm -v $(PROJECT_DIR):/app:Z -w /app $(GO_LINT_IMG) golangci-lint run -E gosec --timeout=6m .

godeps-update: ## Run go mod tidy and go mod vendor.
	go mod tidy && go mod vendor

test-setup: generate fmt vet godeps-update ## Run setup targets for tests

go-test: ## Run go test against code.
	./hack/go-test.sh

test: test-setup go-test ## Run go unit tests.

ODF_OPERATOR_INSTALL ?= true
ODF_OPERATOR_UNINSTALL ?= true
e2e-test: ginkgo ## Run end to end functional tests.
	@echo "build and run e2e tests"
	./hack/e2e-test.sh

define MANAGER_ENV_VARS
NOOBAA_SUBSCRIPTION_NAME=$(NOOBAA_SUBSCRIPTION_NAME)
NOOBAA_SUBSCRIPTION_PACKAGE=$(NOOBAA_SUBSCRIPTION_PACKAGE)
NOOBAA_SUBSCRIPTION_CHANNEL=$(NOOBAA_SUBSCRIPTION_CHANNEL)
NOOBAA_SUBSCRIPTION_STARTINGCSV=$(NOOBAA_SUBSCRIPTION_STARTINGCSV)
NOOBAA_SUBSCRIPTION_CATALOGSOURCE=$(NOOBAA_SUBSCRIPTION_CATALOGSOURCE)
NOOBAA_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE=$(NOOBAA_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE)
CSIADDONS_SUBSCRIPTION_NAME=$(CSIADDONS_SUBSCRIPTION_NAME)
CSIADDONS_SUBSCRIPTION_PACKAGE=$(CSIADDONS_SUBSCRIPTION_PACKAGE)
CSIADDONS_SUBSCRIPTION_CHANNEL=$(CSIADDONS_SUBSCRIPTION_CHANNEL)
CSIADDONS_SUBSCRIPTION_STARTINGCSV=$(CSIADDONS_SUBSCRIPTION_STARTINGCSV)
CSIADDONS_SUBSCRIPTION_CATALOGSOURCE=$(CSIADDONS_SUBSCRIPTION_CATALOGSOURCE)
CSIADDONS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE=$(CSIADDONS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE)
OCS_SUBSCRIPTION_NAME=$(OCS_SUBSCRIPTION_NAME)
OCS_SUBSCRIPTION_PACKAGE=$(OCS_SUBSCRIPTION_PACKAGE)
OCS_SUBSCRIPTION_CHANNEL=$(OCS_SUBSCRIPTION_CHANNEL)
OCS_SUBSCRIPTION_STARTINGCSV=$(OCS_SUBSCRIPTION_STARTINGCSV)
OCS_SUBSCRIPTION_CATALOGSOURCE=$(OCS_SUBSCRIPTION_CATALOGSOURCE)
OCS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE=$(OCS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE)
IBM_SUBSCRIPTION_NAME=$(IBM_SUBSCRIPTION_NAME)
IBM_SUBSCRIPTION_PACKAGE=$(IBM_SUBSCRIPTION_PACKAGE)
IBM_SUBSCRIPTION_CHANNEL=$(IBM_SUBSCRIPTION_CHANNEL)
IBM_SUBSCRIPTION_STARTINGCSV=$(IBM_SUBSCRIPTION_STARTINGCSV)
IBM_SUBSCRIPTION_CATALOGSOURCE=$(IBM_SUBSCRIPTION_CATALOGSOURCE)
IBM_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE=$(IBM_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE)
endef
export MANAGER_ENV_VARS

update-mgr-env: ## Feed env variables to the manager configmap
	@echo "$$MANAGER_ENV_VARS" > config/manager/manager.env

##@ Build

build: generate fmt vet go-build ## Build manager binary.

go-build: ## Run go build against code.
	@GOBIN=${GOBIN} ./hack/go-build.sh

run: manifests generate fmt vet ## Run a controller from your host.
	go run ./main.go

docker-build: godeps-update test-setup ## Build docker image with the manager.
	docker build -t ${IMG} .

docker-push: ## Push docker image with the manager.
	docker push ${IMG}

##@ Deployment

install: manifests kustomize ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

uninstall: manifests kustomize ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl delete -f -

install-odf: operator-sdk ## install odf using the hack/install-odf.sh script
	hack/install-odf.sh $(OPERATOR_SDK) $(BUNDLE_IMG) $(CATALOG_DEPS_IMG) $(STARTING_CSVS)

deploy: manifests kustomize ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	cd config/default && $(KUSTOMIZE) edit set image rbac-proxy=$(RBAC_PROXY_IMG)
	cd config/console && $(KUSTOMIZE) edit set image odf-console=$(ODF_CONSOLE_IMG)
	$(KUSTOMIZE) build config/default | kubectl apply -f -

undeploy: ## Undeploy controller from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/default | kubectl delete -f -

deploy-with-olm: kustomize ## Deploy controller to the K8s cluster via OLM
	cd config/install && $(KUSTOMIZE) edit set image catalog-img=${CATALOG_IMG}
	cd config/install/odf-resources && $(KUSTOMIZE) edit set namespace $(OPERATOR_NAMESPACE)
	$(KUSTOMIZE) build config/install | kubectl create -f -

undeploy-with-olm: ## Undeploy controller from the K8s cluster
	$(KUSTOMIZE) build config/install | kubectl delete -f -

.PHONY: bundle
bundle: manifests kustomize operator-sdk ## Generate bundle manifests and metadata, then validate generated files.
	$(OPERATOR_SDK) generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	cd config/default && $(KUSTOMIZE) edit set image rbac-proxy=$(RBAC_PROXY_IMG)
	cd config/console && $(KUSTOMIZE) edit set image odf-console=$(ODF_CONSOLE_IMG)
ifneq ($(FUSION), true)
	cd config/manifests/bases && $(KUSTOMIZE) edit add annotation --force 'olm.skipRange':"$(SKIP_RANGE)" && \
	        $(KUSTOMIZE) edit add annotation --force 'operators.operatorframework.io/operator-type':"$(OPERATOR_TYPE)" \
			'olm.properties':'[{"type": "olm.maxOpenShiftVersion", "value": "$(MAX_OCP_VERSION)"}]' && \
		$(KUSTOMIZE) edit add patch --name odf-operator.v0.0.0 --kind ClusterServiceVersion\
		--patch '[{"op": "replace", "path": "/spec/replaces", "value": "$(REPLACES)"}]'
	cd config/manifests && $(KUSTOMIZE) edit remove resource fusion
	cd config/manifests && $(KUSTOMIZE) edit add resource bases
else
	cd config/manifests/fusion && $(KUSTOMIZE) edit add annotation --force 'olm.skipRange':"$(SKIP_RANGE)" && \
	        $(KUSTOMIZE) edit add annotation --force 'operators.operatorframework.io/operator-type':"$(OPERATOR_TYPE)" \
			'olm.properties':'[{"type": "olm.maxOpenShiftVersion", "value": "$(MAX_OCP_VERSION)"}]' && \
		$(KUSTOMIZE) edit add patch --name odf-operator.v0.0.0 --kind ClusterServiceVersion\
		--patch '[{"op": "replace", "path": "/spec/replaces", "value": "$(REPLACES)"}]'
	cd config/manifests && $(KUSTOMIZE) edit remove resource bases
	cd config/manifests && $(KUSTOMIZE) edit add resource fusion
endif
	$(KUSTOMIZE) build config/manifests | $(OPERATOR_SDK) generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	$(OPERATOR_SDK) bundle validate ./bundle

.PHONY: bundle-build
bundle-build: bundle ## Build the bundle image.
	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

.PHONY: bundle-push
bundle-push: ## Push the bundle image.
	$(MAKE) docker-push IMG=$(BUNDLE_IMG)

# Build a catalog image by adding bundle images to an empty catalog using the operator package manager tool, 'opm'.
# This recipe invokes 'opm' in 'semver' bundle add mode. For more information on add modes, see:
# https://github.com/operator-framework/community-operators/blob/7f1438c/docs/packaging-operator.md#updating-your-existing-operator
.PHONY: catalog
catalog: opm ## Generate catalog manifests and then validate generated files.
	$(OPM) render --output=yaml $(BUNDLE_IMG) $(OPM_RENDER_OPTS) > catalog/odf.yaml
	$(OPM) render --output=yaml $(OCS_BUNDLE_IMG) $(OPM_RENDER_OPTS) > catalog/ocs.yaml
	$(OPM) render --output=yaml $(IBM_BUNDLE_IMG) $(OPM_RENDER_OPTS) > catalog/ibm.yaml
	$(OPM) render --output=yaml $(NOOBAA_BUNDLE_IMG) $(OPM_RENDER_OPTS) > catalog/noobaa.yaml
	$(OPM) render --output=yaml $(CSIADDONS_BUNDLE_IMG) $(OPM_RENDER_OPTS) > catalog/csiaddons.yaml
	$(OPM) validate catalog

.PHONY: catalog-build
catalog-build: catalog ## Build a catalog image.
	docker build -f catalog.Dockerfile -t $(CATALOG_IMG) .

.PHONY: catalog-push
catalog-push: ## Push a catalog image.
	$(MAKE) docker-push IMG=$(CATALOG_IMG)

.PHONY: catalog-deps-build
catalog-deps-build: catalog ## Build a catalog-deps image.
	docker build -f catalog.deps.Dockerfile -t $(CATALOG_DEPS_IMG) .

.PHONY: catalog-deps-push
catalog-deps-push: ## Push a catalog-deps image.
	$(MAKE) docker-push IMG=$(CATALOG_DEPS_IMG)
