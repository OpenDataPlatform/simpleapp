#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "${KUBECONFIG}" ]; then echo "KUBECONFIG must be defined with some admin rights";  exit 1; fi

NAMESPACE=$1; shift
SERVICE_ACCOUNT=$1; shift
TARGET_KUBECONFIG=$1; shift

if [ -z "${TARGET_KUBECONFIG}" ]; then echo "Usage: $0 <namespace> <serviceAccount> <targetKubeconfigFile>";  exit 1; fi

set -e

SERVER=$(yq eval -o=json $KUBECONFIG | jq '.clusters[0].cluster.server')
SERVER="${SERVER%\"}"
SERVER="${SERVER#\"}"

CLUSTER=$(yq eval -o=json $KUBECONFIG | jq '.clusters[0].name')
CLUSTER="${CLUSTER%\"}"
CLUSTER="${CLUSTER#\"}"

SECRET_NAME=$(kubectl -n ${NAMESPACE} get serviceaccounts  ${SERVICE_ACCOUNT} -o jsonpath='{.secrets[0].name}')
CA=$(kubectl -n ${NAMESPACE} get secret/$SECRET_NAME -o jsonpath='{.data.ca\.crt}')
TOKEN=$(kubectl -n ${NAMESPACE} get secret/$SECRET_NAME -o jsonpath='{.data.token}' | base64 --decode)

cat >${TARGET_KUBECONFIG} <<EOF
  apiVersion: v1
  kind: Config
  clusters:
  - name: default-cluster
    cluster:
      certificate-authority-data: ${CA}
      server: ${SERVER}
  contexts:
  - name: default-context
    context:
      cluster: default-cluster
      namespace: ${NAMESPACE}
      user: spark-user
  current-context: default-context
  users:
  - name: spark-user
    user:
      token: ${TOKEN}
EOF

echo "To switch to spark config:"
echo "export KUBECONFIG=$TARGET_KUBECONFIG"


