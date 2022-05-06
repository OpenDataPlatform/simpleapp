#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export KUBECONFIG=${MYDIR}/../../kubeconfigs/spark-sapp-work.spark

kubectl delete --ignore-not-found=true -f ./java2.yaml
kubectl apply -f ./java2.yaml
