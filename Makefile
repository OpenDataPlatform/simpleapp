
MC_ALIAS := minio1
BUCKET := spark-sapp
NAMESPACE := spark-sapp-work
SERVICE_ACCOUNT := spark
S3_ACCESS_KEY := spark-sapp
S3_SECRET_KEY := pd2t3yiizB0hTRjQOiIMihNNwMGeBM9P1vd1We2cUK1_MrAkRzY4qg==
S3_ENDPOINT := https://n0.minio1:9000/
HIVE_METASTORE_NAMESPACE := spark-sapp-sys
ODP_TAG := 3.2.1
SAPP_TAG := 0.1.0

# ------------------- Docker Build configuration

DOCKER_REPO := ghcr.io/opendataplatform
BUILDX_CACHE=/tmp/docker_cache
# You can switch between simple (faster) docker build or multiplatform one.
# For multiplatform build on a fresh system, do 'make docker-set-multiplatform-builder'
DOCKER_BUILD := docker buildx build --builder multiplatform --cache-to type=local,dest=$(BUILDX_CACHE),mode=max --cache-from type=local,src=$(BUILDX_CACHE) --platform linux/amd64,linux/arm64
#DOCKER_BUILD := docker build
# Comment this to just build locally
DOCKER_PUSH := --push


.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

doc: ## Generate doc index
	doctoc docs/howto.md --github --title '## Index'

prepare: toolsexec kubeconfig upload-data upload-code s3secret ## handle all prerequisites

##@ Prerequisites

.PHONY: toolsexec
toolsexec: ## To execute after git clone
	chmod +x ./tools/*.sh
	chmod +x ./launchers/*/*.sh

.PHONY: kubeconfig
kubeconfig: ## Generate kubeconfig for spark service account
	./tools/generate-kubeconfig.sh $(NAMESPACE) $(SERVICE_ACCOUNT) ./kubeconfigs/$(NAMESPACE).$(SERVICE_ACCOUNT)

.PHONY: upload-data
upload-data: ## upload sample dataset
	./tools/upload-data.sh $(MC_ALIAS)/$(BUCKET)/data

.PHONY: upload-code
upload-code: ## upload java and python code
	./tools/upload-java-simpleapp.sh $(MC_ALIAS)/$(BUCKET)/jars
	./tools/upload-py-simpleapp.sh $(MC_ALIAS)/$(BUCKET)/py

.PHONY: s3secret
s3secret: ## Generate secret for S3 access
	./tools/s3secret.sh $(NAMESPACE) $(S3_ACCESS_KEY) $(S3_SECRET_KEY)

.PHONY: sapp-default
sapp-default: ## Generate configmap with application default
	./tools/sapp-default.sh "$(NAMESPACE)" "$(BUCKET)" "$(S3_ENDPOINT)" "$(HIVE_METASTORE_NAMESPACE)"

.PHONY: docker-sapp
docker-sapp: ## Generate image embedding simpleapp code
	$(DOCKER_BUILD) ${DOCKER_PUSH} --build-arg img_base=${DOCKER_REPO}/spark-odp:${ODP_TAG} --build-arg sapp_version=${SAPP_TAG} -t $(DOCKER_REPO)/sapp:${SAPP_TAG} -f Dockerfile .
