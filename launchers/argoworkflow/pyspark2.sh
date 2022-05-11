#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export KUBECONFIG=${MYDIR}/../../kubeconfigs/spark-sapp-work.spark

kubectl create -f ./pyspark2.yaml
