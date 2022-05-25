#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "${KUBECONFIG}" ]; then echo "KUBECONFIG must be defined with some admin rights";  exit 1; fi

# To adjust to your application context
#NAMESPACE=spark-sapp-work
#BUCKET=spark-sapp
#S3_ENDPOINT=https://n0.minio1:9000/
#HIVE_METASTORE_NAMESPACE=spark-sapp-sys

NAMESPACE=$1; shift
BUCKET=$1; shift
S3_ENDPOINT=$1; shift
HIVE_METASTORE_NAMESPACE=$1; shift


kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: sapp-default
  namespace: ${NAMESPACE}
data:
  # Override default
  IMAGE_PULL_POLICY: "Always"
  # Mandatory
  S3_ENDPOINT: "${S3_ENDPOINT}"
  NAMESPACE: "${NAMESPACE}"
  EXECUTOR_INSTANCES: "2"
  EXECUTOR_LIMIT_CORES: "1500m"
  EXECUTOR_REQUEST_CORES: "500m"
  EXECUTOR_MEMORY: "3G"
  SPARK_BUCKET: "${BUCKET}"
  # Optional features
  EVENT_LOG_DIR: "s3a://${BUCKET}/eventlogs"
  FILE_UPLOAD_PATH: "s3a://${BUCKET}/shared"
  HIVE_METASTORE_URI: "thrift://hive-metastore.${HIVE_METASTORE_NAMESPACE}.svc:9083"
  SQL_WAREHOUSE_DIR: "s3a://${BUCKET}/warehouse"
EOF


