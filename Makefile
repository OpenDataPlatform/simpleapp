
MC_ALIAS := minio1
BUCKET := spark-sapp
NAMESPACE := spark-sapp-work
SERVICE_ACCOUNT := spark
S3_ACCESS_KEY := spark-sapp
S3_SECRET_KEY := pd2t3yiizB0hTRjQOiIMihNNwMGeBM9P1vd1We2cUK1_MrAkRzY4qg==

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

doc: ## Generate doc index
	doctoc docs/howto.md --github --title '## Index'
	doctoc docs/spark-odp-image.md --github --title '## Index'

prepare: toolsexec kubeconfig upload-data upload-code s3secret ## handle all prerequisites

##@ Prerequisites

toolsexec: ## To execute after git clone
	chmod +x ./tools/*.sh
	chmod +x ./launchers/*/*.sh

kubeconfig: ## Generate kubeconfig for spark service account
	./tools/generate-kubeconfig.sh $(NAMESPACE) $(SERVICE_ACCOUNT) ./kubeconfigs/$(NAMESPACE).$(SERVICE_ACCOUNT)

upload-data: ## upload sample dataset
	./tools/upload-data.sh $(MC_ALIAS)/$(BUCKET)/data

upload-code: ## upload java and python code
	./tools/upload-java-simpleapp.sh $(MC_ALIAS)/$(BUCKET)/jars
	./tools/upload-py-simpleapp.sh $(MC_ALIAS)/$(BUCKET)/py

s3secret: ## Generate secret for S3 access
	./tools/s3secret.sh $(NAMESPACE) $(S3_ACCESS_KEY) $(S3_SECRET_KEY)