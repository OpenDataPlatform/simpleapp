#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export KUBECONFIG=${MYDIR}/../../kubeconfigs/spark-sapp-work.spark

kubectl delete --ignore-not-found=true -f ./pyspark3.yaml
kubectl apply -f ./pyspark3.yaml
